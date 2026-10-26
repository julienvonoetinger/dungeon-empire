extends SceneTree
## Static isolated state exercise: never reads or writes a player save.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/trap-review/v3-integrated/"
var failed := false
var records: Array[Dictionary] = []

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): quit(2))
	_run.call_deferred()

func _inventory(view: Node) -> Dictionary:
	var ids := {}
	for node in view.find_children("*", "Sprite2D", true, false):
		if node.has_meta("prepared_id"):
			var id: String = node.get_meta("prepared_id")
			ids[id] = int(ids.get(id,0)) + 1
	return ids

func _check(view: Node, state: String, ready: bool, present := true) -> void:
	var ids := _inventory(view)
	for kind in ["spike","snare","void"]:
		var id: String = "trap-"+kind+("-ready-floor" if ready else "-spent-floor")
		if int(ids.get(id,0)) != (1 if present else 0):
			failed = true
			push_error(state+": expected prepared "+id)
		var other: String = "trap-"+kind+("-spent-floor" if ready else "-ready-floor")
		if ids.has(other):
			failed = true
			push_error(state+": stale "+other)
	if view._paint_cursor != view._paint_order.size():
		failed = true
		push_error(state+": incomplete solid grouping")
	for item in view._trap_visuals:
		if item.layer == "mechanism" and item.node.visible != ready:
			failed = true
			push_error(state+": incorrect raised mechanism visibility")
		if item.layer == "floor":
			var anchor: Vector2 = view.grid_to_local(Vector2(item.cell))
			for node in view._world.get_children():
				if node is Sprite2D and node.has_meta("prepared_id"):
					var id: String = node.get_meta("prepared_id")
					if id.begins_with("floor"):
						var entry: Dictionary = view._definition.get("entries")[id]
						if node.position.is_equal_approx(anchor+Vector2(entry.offset[0],entry.offset[1])):
							failed = true
							push_error(state+": ordinary floor/damage covers the socket")
	records.append({"state":state,"ids":ids,"groups":view.solid_groups.size()})

func _snap(world: SubViewport, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	# Static session processing is disabled, so refresh screen-sized rings after
	# the capture camera changes. The offscreen window retains normal 1280x720 DPI.
	world.get_node("Dungeon")._update_markers()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if world.get_texture().get_image().save_png(OUT+name+".png") != OK: failed = true

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
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
	var positions := [Vector2i(6,7),Vector2i(8,7),Vector2i(10,7)]
	var kinds := [Types.Tile.SPIKE,Types.Tile.SNARE,Types.Tile.VOID]
	for i in 3:
		var p: Vector2i = positions[i]
		game.sim.grid[p.y][p.x] = kinds[i]
		game.sim.trap_charges[p] = Types.trap_max_charges(kinds[i])
	var view: Node2D = game.get_node("PlayArea/World/Dungeon")
	view.rebuild()
	_check(view,"ready",true)
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
	await _snap(world,"ready-mobile")
	# Missing dictionary values have always meant a fully charged trap in the sim.
	game.sim.trap_charges.clear()
	view.rebuild()
	_check(view,"default-charges",true)
	for i in 3: game.sim.trap_charges[positions[i]] = Types.trap_max_charges(kinds[i])
	for i in 3:
		camera.zoom = Vector2.ONE*2
		camera.position = view.grid_to_local(Vector2(positions[i])+Vector2(.5,.5))
		camera.force_update_scroll()
		await _snap(world,"ready-"+["spike","snare","void"][i])
	for p in positions: game.sim.trap_charges[p] = 0
	view._update_markers()
	_check(view,"spent-without-rebuild",false)
	camera.zoom = Vector2.ONE*.75
	camera.position = view.grid_to_local(Vector2(8.5,7.5))
	camera.force_update_scroll()
	await _snap(world,"spent-mobile")
	view.rebuild()
	_check(view,"initial-spent-rebuild",false)
	game.sim.gold = 1000
	for p in positions: game.sim.repair_trap(p)
	view._update_markers()
	_check(view,"repaired-without-rebuild",true)
	var floor_nodes: Array = view._trap_visuals.map(func(item): return item.node.get_instance_id())
	for p in positions: game.sim.trap_charges[p] = 1
	view._update_markers()
	_check(view,"one-charge-left",true)
	if floor_nodes != view._trap_visuals.map(func(item): return item.node.get_instance_id()):
		failed = true
		push_error("Partial charge change recreated prepared nodes")
	game.raid.raid_active = true
	game.raid.hero = {"pos":positions[0],"name":"Neris","kind":"thief","level":1,"hp":80,"max_hp":100}
	view.rebuild()
	_check(view,"hero-on-trap",true)
	await _snap(world,"hero-mobile")
	for p in positions: game.sim.grid[p.y][p.x] = Types.Tile.FLOOR
	view.rebuild()
	_check(view,"removed",true,false)
	var file := FileAccess.open(OUT+"native-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed":failed,"records":records},"\t"))
	if FileAccess.file_exists(game.save_path):
		failed = true
		push_error("Unexpected isolated save write")
	print("Inset traps: ",records.size()," states, failed=",failed)
	quit(1 if failed else 0)
