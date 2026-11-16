extends RefCounted
## A volunteer rehearses the approach to the Core with a private routing map.
const Types = preload("res://scripts/game/game_types.gd")
const Stairs = preload("res://scripts/game/stair_traversal.gd")
const Actor = preload("res://scripts/game/invocation_actor.gd")
const SPEED := 1.05
const INSPECT_TIME := 2.2
const VOLUNTEER_SCALE := .82
# The camera renders 256 px per three model units. One dungeon cell spans
# 128 horizontal pixels after a 45-degree turn onto a corridor axis.
const MODEL_TO_CELLS := VOLUNTEER_SCALE * 256. / (3. * 128. * sqrt(2.))
const PICK_FRAMES := [0,1,2,3,4,5,3,6,5,7,4,5,3,8,9,10]
enum Outcome { BLOCKED, DOOR, TRAP, CORE }

var path := Curve2D.new()
var outcome := Outcome.BLOCKED
var contact := Vector2i(-1,-1)
var travel_time := 0.

func _init(sim: DungeonSim, raid: RaidDirector) -> void:
	path.bake_interval = .04
	var entrance := sim._find_tile(Types.Tile.ENTRANCE)
	var center := Vector2(entrance) + Vector2(.5,.5)
	path.add_point(center - Vector2(sim._entrance_mouth(entrance)) * Stairs.TOP_TRAVEL)
	path.add_point(center)
	var scout := {"kind":"oculin", "pos":entrance, "known":{}, "visited":{}, "bias":{},
		"avoided_doors":{}, "trap_weight":0., "fear_weight":0.}
	var goals := {}
	for y in Types.ROWS:
		for x in Types.COLS:
			var cell := Vector2i(x,y)
			var tile: int = sim.grid[y][x]
			if tile == Types.Tile.ROCK: continue
			scout.known[cell] = tile
			if tile == Types.Tile.CORE: goals[cell] = true
			if sim._door_intact(cell): scout.avoided_doors[cell] = true
	# Try an open passage first. If every route has a door, approach that door.
	if raid._route_step(scout,goals) == entrance: scout.avoided_doors.clear()
	for step in scout.known.size():
		var next := raid._route_step(scout,goals)
		if next == scout.pos: break
		var target := Vector2(next) + Vector2(.5,.5)
		var tile: int = scout.known[next]
		if sim._door_intact(next) or tile == Types.Tile.CORE:
			outcome = Outcome.CORE if tile == Types.Tile.CORE else Outcome.DOOR
			if outcome == Outcome.DOOR:
				# In the working poses the tip is 1.14 units forward, .06 to
				# the actor's right, at the painted keyhole height (.32 cells).
				var forward := target-center
				var right := Vector2(forward.y,-forward.x)
				var panel_normal := Vector2.DOWN if sim.door_facing(next) == "north" else Vector2.RIGHT
				var keyhole := target + panel_normal*.035
				path.add_point(keyhole-(1.14*forward+.06*right)*MODEL_TO_CELLS)
			else:
				path.add_point(center.lerp(target,.32))
			contact = next
			break
		path.add_point(target)
		if sim._is_trap_tile(tile) and sim.trap_charges.get(next,Types.trap_max_charges(tile)) > 0:
			outcome = Outcome.TRAP
			contact = next
			break
		scout.pos = next
		center = target
	# Even a door right at the stair gives the player time to notice the arrival.
	travel_time = maxf(1.6,path.get_baked_length()/SPEED)

func duration() -> float:
	return 2. * travel_time + INSPECT_TIME

func present(actor: Actor, view: Node2D, time: float) -> Vector2:
	var returning := time > travel_time + INSPECT_TIME
	var moving_time := clampf(duration()-time if returning else time,0.,travel_time)
	var distance := path.get_baked_length() * moving_time / travel_time
	var at := path.sample_baked(distance)
	var previous := path.sample_baked(maxf(0.,distance-.015))
	var ahead := path.sample_baked(minf(path.get_baked_length(),distance+.015))
	var heading := Actor.direction_for(view.grid_to_local(previous-ahead if returning else ahead-previous))
	view.position_invoker(actor,at)
	if outcome == Outcome.DOOR:
		var remaining := path.get_baked_length()-distance
		view.reveal_practice_lockpick(contact,actor,1.-smoothstep(.0,.95,remaining))
	actor.modulate.a = smoothstep(0.,.13,distance)
	var contact_age := time - travel_time
	if outcome == Outcome.TRAP and contact_age >= 0. and not returning:
		# Eight non-looping poses, then stay grounded until the turn home.
		actor.present_messenger("hurt-"+heading, mini(7, int(contact_age * 10.)))
	elif outcome == Outcome.DOOR and contact_age >= 0. and not returning:
		var beat := mini(PICK_FRAMES.size()-1,int(contact_age/INSPECT_TIME*PICK_FRAMES.size()))
		actor.present_messenger("lockpick-"+heading,PICK_FRAMES[beat])
	else:
		var running := time < travel_time or returning
		actor.present_messenger("run-"+heading, int(time*24.)%12 if running else 0)
	return at

func report() -> String:
	match outcome:
		Outcome.DOOR: return "He turned back at your door, Master. He couldn’t find an open passage to the Core."
		Outcome.TRAP: return "The spikes rose under his feet, Master. In a real raid, they can wound the same hero only once, even on the way back."
		Outcome.CORE: return "He reached the Core, Master. In a real raid, an attacker could strike it from here. Let’s guard this passage."
		_: return "Our scout could find no way through to the Core. He’s back in the village now."
