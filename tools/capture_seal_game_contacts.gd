extends SceneTree
## Isolated static scene review; no gameplay commands or player save access.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const GATES := [Vector2i(8,6),Vector2i(10,8),Vector2i(8,10),Vector2i(6,8)]
var OUT := "res://artifacts/door-frame-contacts/"
var records: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			OUT = argument.trim_prefix("--output=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(25.0).timeout.connect(func(): quit(2))
	_capture.call_deferred()

func _record(label: String, view: Node2D) -> void:
	var walls: Array[Dictionary] = []
	var nodes := {}
	for part in view.solid_groups:
		if nodes.has(part.node):
			failed = true
			push_error("Two physical supports share one gameplay group")
		nodes[part.node] = true
		if part.has("wall_segment"):
			failed = true
			push_error("Unexpected wall cut beneath frame in " + label)
	for gate: Vector2i in GATES:
		var across := Vector2i.RIGHT if gate.x==8 else Vector2i.DOWN
		var prefix := "wall-v-" if gate.x==8 else "wall-h-"
		for at: Vector2i in [gate,gate+across]:
			var supports: Array = view.solid_groups.filter(func(part): return str(part.id).begins_with(prefix) and Vector2i(part.at)==at)
			if supports.size() != 1:
				failed = true
				push_error("Expected an intact wall at %s in %s" % [at,label])
				continue
			walls.append({"id":supports[0].id,"at":[at.x,at.y],"index":supports[0].node.get_index()})
	if view._paint_cursor != view._paint_order.size():
		failed = true
		push_error("Incomplete gameplay contact groups in " + label)
	records.append({"label":label,"walls":walls,"groups":view.solid_groups.size(),"actor_index":view._actor.get_index() if is_instance_valid(view._actor) else -1})

func _capture() -> void:
	var game := Game.instantiate()
	game.save_path = OUT + "never-created.save"
	game.persistence_enabled = false
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.sim.new_map()
	for i in range(5,12):
		game.sim.grid[8][i] = Types.Tile.FLOOR
		game.sim.grid[i][8] = Types.Tile.FLOOR
	game.sim.grid[8][8] = Types.Tile.CORE
	for p in GATES: game.sim.grid[p.y][p.x] = Types.Tile.DOOR
	var view: Node2D = game.get_node("PlayArea/World/Dungeon")
	view.rebuild()
	_record("intact",view)
	game.raid.raid_active = true
	game.raid.hero = {"pos":Vector2i(8,9),"name":"Neris","kind":"thief","level":1,"hp":80,"max_hp":100}
	view.rebuild()
	_record("actor-behind",view)
	game.raid.hero.pos = Vector2i(8,11)
	view._update_markers()
	_record("actor-in-front",view)
	game.get_node("HUD").visible = false
	game.get_node("PlayArea").stretch = false
	var world: SubViewport = game.get_node("PlayArea/World")
	world.size = Vector2i(640,520)
	var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
	camera.zoom = Vector2.ONE*1.15
	for p in [Vector2i(8,10),Vector2i(10,8)]:
		camera.position = view.grid_to_local(Vector2(p)+Vector2(.5,.5))+Vector2(0,-110)
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if world.get_texture().get_image().save_png(OUT + "game-" + ("north" if p.x==8 else "west") + ".png") != OK: failed = true
	# Keep both sides of the actor/door depth transition as visual evidence.
	camera.position = view.grid_to_local(Vector2(8.5,10.5)) + Vector2(0,-110)
	camera.force_update_scroll()
	for side in [0, 1]:
		# Sample close to the door using the actual movement interpolation, so
		# actor and masonry overlap on screen instead of merely sharing a corridor.
		game.raid.hero.pos = Vector2i(8,10 + side)
		game.raid.hero.move_from = Vector2i(8,9 + side)
		game.raid.hero.step_started_at = 0.0
		game.raid.elapsed_seconds = Types.TURN_TIME * (.78 if side == 0 else .22)
		view._update_markers()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if world.get_texture().get_image().save_png(OUT + ("actor-behind.png" if side == 0 else "actor-in-front.png")) != OK: failed = true
		_record("overlap-behind" if side == 0 else "overlap-in-front",view)
	game.raid.hero.erase("move_from")
	game.raid.hero.erase("step_started_at")
	for p in GATES: game.sim.door_hp[p] = 0
	view.rebuild()
	_record("destroyed",view)
	for p in GATES: game.sim.door_hp[p] = Types.DOOR_MAX_HP
	view.rebuild()
	_record("restored",view)
	var file := FileAccess.open(OUT + "game-contact-inventory.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t"))
	if FileAccess.file_exists(game.save_path):
		failed = true
		push_error("Static review unexpectedly wrote its isolated save")
	game.queue_free()
	await process_frame
	print("Game contact review: ",records.size()," states; failed=",failed)
	quit(1 if failed else 0)
