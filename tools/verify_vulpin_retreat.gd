extends SceneTree
## Real raid decisions observed through passive probes, no UI or player saves.
const Session = preload("res://scripts/game/game_session.gd")
const Probes = preload("res://scripts/testing/game_probes.gd")
const Types = preload("res://scripts/game/game_types.gd")
const OUT := "res://artifacts/vulpin-retreat/"
var checks := 0
var failures: Array[String] = []
var traces := {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: ",message)
func make_game() -> Node:
	var game = Session.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.restart(true)
	return game
func observe(game: Node, title: String, seconds: float) -> Array:
	var trace := []
	var previous := ""
	for tick in int(seconds*30):
		if not game.raid.raid_active: break
		game.advance_simulation(1.0/30)
		var probes := Probes.snapshot(game)
		var h: Dictionary = probes.hero
		var state := str([h.get("pos"),h.get("fleeing"),h.get("lockpicking"),h.get("avoided_doors"),h.get("exiting")])
		if state != previous:
			trace.append({"t":probes.raid.elapsed,"hero":h,"message":game.sim.message})
			previous = state
	traces[title] = trace
	print(title," active=",game.raid.raid_active," t=",game.raid.elapsed_seconds," state_changes=",trace.size()," hero=",str(game.raid.hero.get("pos"))," fleeing=",game.raid.hero.get("fleeing")," result=",game.raid.last_result.get("escaped"))
	return trace
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = make_game()
	seed(1); game.start_raid()
	game.raid.hero.lockpick_success_chance = 0.0
	var trace := observe(game,"failed-only-door",35)
	check(not game.raid.raid_active,"abandoned only door leads to exit, not endless revisits")
	check(game.raid.elapsed_seconds<8,"one failed attempt then a short direct retreat")
	check(game.raid.last_result.get("escaped",0)==1,"leaves through entrance alive")
	check(game.sim.door_hp[Vector2i(5,8)]==Types.DOOR_MAX_HP,"failed pick leaves door locked")
	check(trace.any(func(t):return not t.hero.get("avoided_doors",{}).is_empty()),"actual lockpick failure was exercised")
	game.free()
	# More experienced thieves keep their authorised retries, then retreat too.
	game = make_game(); seed(1); game.start_raid()
	game.raid.hero.level=3; game.raid.hero.lockpick_success_chance=0.0
	trace=observe(game,"two-failed-attempts",15)
	check(trace.any(func(t):return int(t.hero.get("lockpick_attempts",{}).get("5:8",0))==2),"level 3 uses both lockpick attempts")
	check(not game.raid.raid_active and game.raid.last_result.get("escaped",0)==1,"retreat after retry limit")
	game.free()
	# A successful pick is unaffected.
	game=make_game(); seed(21); game.start_raid(); game.raid.hero.lockpick_success_chance=1.0
	observe(game,"success",35)
	check(game.sim.door_opened.get(Vector2i(5,8),false),"successful pick still opens the door")
	check(game.raid.last_result.get("stolen",0)>0,"successful thief still collects treasure")
	game.free()
	# Explicit mental-map fixtures: blocked goals must not hide another route
	# or an accessible exploration frontier.
	game=make_game()
	for x in range(4,8): game.sim.grid[7][x]=Types.Tile.FLOOR if x<7 else Types.Tile.VAULT
	seed(1); game.start_raid()
	game.raid.hero.pos=Vector2i(4,8); game.raid.hero.avoided_doors={Vector2i(5,8):true}
	game.raid._remember_nearby(game.raid.hero)
	var next: Vector2i=game.raid._choose_next_step(game.raid.hero)
	check(next==Vector2i(4,7) and not game.raid.hero.fleeing,"explore reachable bypass instead of fleeing")
	game.raid.hero.known[Vector2i(7,7)]=Types.Tile.VAULT
	next=game.raid._choose_next_step(game.raid.hero)
	check(next==Vector2i(4,7) and not game.raid.hero.fleeing,"pursue known reachable vault via bypass")
	game.free()
	# Already on the entrance: lack of objectives must use normal departure,
	# rather than reporting an interrupted raid because no path step is needed.
	game=make_game(); seed(1); game.start_raid()
	game.raid.hero.avoided_doors={Vector2i(5,8):true}
	game.raid._remember_nearby(game.raid.hero)
	observe(game,"blocked-at-entrance",8)
	check(game.raid.last_result.get("escaped",0)==1,"entrance departure completes normally")
	game.free()
	FileAccess.open(OUT+"trace.json",FileAccess.WRITE).store_string(JSON.stringify(traces,"\t"))
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Vulpin retreat: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
