extends RefCounted
## A volunteer rehearses the approach to the Core with a private routing map.
const Types = preload("res://scripts/game/game_types.gd")
const Stairs = preload("res://scripts/game/stair_traversal.gd")
const Actor = preload("res://scripts/game/invocation_actor.gd")
const SPEED := 1.05
const INSPECT_TIME := 2.2
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
			# Leave room on the approach side for the volunteer's silhouette.
			path.add_point(center.lerp(target,.06 if outcome == Outcome.DOOR else .32))
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
	actor.modulate.a = smoothstep(0.,.13,distance)
	var running := time < travel_time or returning
	actor.present_messenger("run-"+heading, int(time*24.)%12 if running else 0)
	return at

func report() -> String:
	match outcome:
		Outcome.DOOR: return "Your door forced him to turn back, Master. A hero would have to break it down to get any farther."
		Outcome.TRAP: return "He stepped on the trapped tile. That’s where your spikes would have struck a real intruder."
		Outcome.CORE: return "He made it all the way to the Core, Master. Now you know which passage needs stronger defenses before the heroes arrive."
		_: return "Our scout could find no way through to the Core. He’s back in the village now."
