extends SceneTree
## Isolated presentation exercise. Never loads or writes the player save.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/trap-review/v7-integrated-paint/"
var failed := false
var records: Array = []
var positions := [Vector2i(6,7), Vector2i(8,7), Vector2i(10,7)]
var kinds := [Types.Tile.SPIKE, Types.Tile.SNARE, Types.Tile.VOID]

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(2))
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func state(view: Node, label: String, expected: String) -> void:
	var ids := {}
	for item in view._trap_visuals:
		var id: String = item.node.get_meta("prepared_id")
		ids[id] = true
		check(id == "trap-"+item.kind+"-"+expected+"-"+item.layer, label+": unexpected "+id)
	check(ids.size() == 5, label+": missing trap layers")
	check(view._paint_cursor == view._paint_order.size(), label+": incomplete ordering")
	records.append({"state":label,"ids":ids.keys()})

func snap(world: SubViewport, view: Node, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	view._update_markers()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	check(world.get_texture().get_image().save_png(OUT+name+".png") == OK, "Cannot save "+name)

func _run() -> void:
	var game := Game.instantiate()
	game.save_path = OUT+"never-created.save"
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.sim.new_map()
	for y in range(6,11):
		for x in range(5,12): game.sim.grid[y][x] = Types.Tile.FLOOR
	game.sim.grid[10][11] = Types.Tile.CORE
	for i in 3:
		game.sim.grid[positions[i].y][positions[i].x] = kinds[i]
		game.sim.trap_charges[positions[i]] = Types.trap_max_charges(kinds[i])
	var view: Node2D = game.get_node("PlayArea/World/Dungeon")
	view.set_process(false) # The harness advances presentation time explicitly.
	view.rebuild()
	state(view,"armed","ready")
	if failed:
		quit(1)
		return
	game.get_node("HUD").hide()
	game.get_node("PlayArea").stretch = false
	var world: SubViewport = game.get_node("PlayArea/World")
	world.size = Vector2i(960,540)
	var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
	camera.zoom = Vector2.ONE*.75
	camera.position = view.grid_to_local(Vector2(8.5,7.5))
	camera.force_update_scroll()
	await snap(world,view,"ready-mobile")
	game.raid.raid_active = true
	game.raid.elapsed_seconds = 10
	game.raid.raid_stats = {"traps_spent":0}
	# Exercise the real activation method and its new presentation event.
	for i in 3:
		game.raid.hero = {"pos":positions[i],"kind":"thief","name":"Review","display":"Review","level":1,"hp":100,"max_hp":100,"carried_gold":0,"morale":100.0,"profile":{"fear":1.0}}
		game.sim.trap_charges[positions[i]] = 1
		game.raid._trigger_trap(positions[i], kinds[i])
	view._update_markers()
	state(view,"last-charge-trigger","triggered")
	await snap(world,view,"triggered-mobile")
	view.rebuild()
	state(view,"trigger-survives-rebuild","triggered")
	check(view.is_processing(), "Rebuild disabled the active trap presentation clock")
	view.set_process(false)
	game.paused = true
	await process_frame
	view._advance_trap_effects(5)
	view._update_markers()
	state(view,"pause-holds-trigger","triggered")
	game.paused = false
	game.raid.hero = {} # Dedicated actor captures follow; keep state plates clear.
	for expected in ["triggered", "spent", "ready"]:
		if expected == "spent":
			game.raid.elapsed_seconds = 20
			view._advance_trap_effects(5)
		if expected == "ready":
			game.raid.raid_active = false
			game.raid.hero = {}
			game.sim.gold = 1000
			for p in positions: game.sim.repair_trap(p)
		view._update_markers()
		state(view,expected,expected)
		for i in 3:
			camera.zoom = Vector2.ONE*2
			camera.position = view.grid_to_local(Vector2(positions[i])+Vector2(.5,.5))
			camera.force_update_scroll()
			await snap(world,view,expected+"-"+["spike","snare","void"][i])
	var node_ids: Array = view._trap_visuals.map(func(item): return item.node.get_instance_id())
	for p in positions: game.sim.trap_charges[p] = 1
	view._update_markers()
	check(node_ids == view._trap_visuals.map(func(item): return item.node.get_instance_id()), "Partial charge rebuilt sprites")
	game.sim.trap_charges.clear()
	view.rebuild()
	state(view,"missing-charges-default","ready")
	# Inspect raised mechanism ordering against the provisional actor, both
	# behind the trap and over its centre. This is visual evidence, not a pixel oracle.
	game.raid.raid_active = true
	for i in 2:
		game.sim.trap_charges[positions[i]] = 1
		view._on_trap_activated(positions[i],kinds[i])
		for offset in [Vector2i(-1,0),Vector2i.ZERO]:
			game.raid.hero = {"pos":positions[i]+offset,"kind":"thief","name":"Review","level":1,"hp":100,"max_hp":100}
			view.rebuild()
			view.set_process(false)
			camera.zoom = Vector2.ONE*2
			camera.position = view.grid_to_local(Vector2(positions[i])+Vector2(.5,.5))
			camera.force_update_scroll()
			await snap(world,view,"actor-"+["spike","snare"][i]+("-behind" if offset != Vector2i.ZERO else "-centre"))
	game.raid.hero = {}
	game.raid.raid_active = false
	game.sim.gold = 1000
	for p in positions:
		game.sim.trap_charges[p] = 0
		view._on_trap_activated(p,game.sim.grid[p.y][p.x])
		check(game.sim.repair_trap(p), "Fixture repair failed")
	view._update_markers()
	state(view,"repair-cancels-active-trigger","ready")
	view.set_process(false)
	# Real lethal resolve path ends the raid and synchronously rebuilds the view.
	game.raid.raid_index = 2
	game.raid.raid_active = true
	game.raid.raid_stats = {"traps_spent":0,"killed":0}
	game.raid.hero = {"pos":positions[0],"kind":"ranger","name":"Review","display":"Review","level":1,"hp":1,"max_hp":100,"carried_gold":0,"morale":100.0}
	game.sim.trap_charges[positions[0]] = 1
	game.save_blocked = true # Exercise the real result callback without a save write.
	game.raid._resolve_cell(positions[0])
	check(game.result_open and not game.raid.raid_active, "Lethal hit did not finish the raid")
	check(view._trap_state(positions[0],kinds[0]) == "triggered", "Lethal last charge skipped triggered art")
	game.save_blocked = false
	view._advance_trap_effects(5)
	check(view._trap_state(positions[0],kinds[0]) == "triggered", "Result did not freeze trigger")
	game.continue_preparation()
	view._advance_trap_effects(5)
	check(view._trap_state(positions[0],kinds[0]) == "spent", "Lethal trigger did not finish after result")
	records.append({"state":"lethal-last-charge-result-and-resume","passed":true})
	# Do not only call the clock helper: verify the live node advances it.
	game.raid.raid_active = true
	game.sim.trap_charges[positions[0]] = 1
	view._on_trap_activated(positions[0],kinds[0])
	check(view.is_processing(), "Activation did not start the presentation clock")
	await create_timer(.9).timeout
	check(view._trap_state(positions[0],kinds[0]) == "ready", "Live trap clock failed to expire")
	view.set_process(false)
	records.append({"state":"live-frame-clock-expiry","passed":true})
	view._on_trap_activated(positions[0],kinds[0])
	for p in positions: game.sim.grid[p.y][p.x] = Types.Tile.FLOOR
	view.rebuild()
	check(view._trap_visuals.is_empty(), "Removed traps persist")
	check(view._trap_triggers.is_empty(), "Removed trap trigger persists")
	check(not FileAccess.file_exists(game.save_path), "Unexpected save write")
	var file := FileAccess.open(OUT+"native-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed":failed,"records":records},"\t"))
	print("Painted traps: ", records.size(), " checks, failed=",failed)
	quit(1 if failed else 0)
