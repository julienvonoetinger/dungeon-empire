extends SceneTree
## Isolated static scene review; no gameplay commands or player save access.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/door-redesign/seal-v1/painted-v3/"
var records: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func(): quit(2))
	_capture.call_deferred()

func _record(label: String, view: Node2D, expected_segments: int) -> void:
	var segments: Array[Dictionary] = []
	var nodes := {}
	for part in view.solid_groups:
		if nodes.has(part.node):
			failed = true
			push_error("Two physical supports share one gameplay group")
		nodes[part.node] = true
		if part.has("wall_segment"):
			segments.append({"id": part.id, "at": [part.at.x,part.at.y], "span": [part.wall_segment.span.x,part.wall_segment.span.y], "index": part.node.get_index(), "min": [part.min.x,part.min.y,part.min.z], "max": [part.max.x,part.max.y,part.max.z]})
	if segments.size() != expected_segments or view._paint_cursor != view._paint_order.size():
		failed = true
		push_error("Incomplete gameplay contact groups in " + label)
	records.append({"label":label,"segments":segments,"groups":view.solid_groups.size(),"actor_index":view._actor.get_index() if is_instance_valid(view._actor) else -1})

func _capture() -> void:
	var game := Game.instantiate()
	game.save_path = OUT + "never-created.save"
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.sim.new_map()
	for i in range(5,12):
		game.sim.grid[8][i] = Types.Tile.FLOOR
		game.sim.grid[i][8] = Types.Tile.FLOOR
	game.sim.grid[8][8] = Types.Tile.CORE
	var gates := [Vector2i(8,6),Vector2i(10,8),Vector2i(8,10),Vector2i(6,8)]
	for p in gates: game.sim.grid[p.y][p.x] = Types.Tile.DOOR
	var view: Node2D = game.get_node("PlayArea/World/Dungeon")
	view.rebuild()
	_record("intact",view,16)
	game.raid.raid_active = true
	game.raid.hero = {"pos":Vector2i(8,9),"name":"Neris","kind":"thief","level":1,"hp":80,"max_hp":100}
	view.rebuild()
	_record("actor-behind",view,16)
	game.raid.hero.pos = Vector2i(8,11)
	view._update_markers()
	_record("actor-in-front",view,16)
	game.get_node("HUD").visible = false
	game.get_node("PlayArea").stretch = false
	var world: SubViewport = game.get_node("PlayArea/World")
	world.size = Vector2i(640,520)
	var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
	camera.zoom = Vector2.ONE*2
	for p in [Vector2i(8,10),Vector2i(10,8)]:
		camera.position = view.grid_to_local(Vector2(p)+Vector2(.5,.5))+Vector2(0,-40)
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if world.get_texture().get_image().save_png(OUT + "game-" + ("north" if p.x==8 else "west") + ".png") != OK: failed = true
	for p in gates: game.sim.door_hp[p] = 0
	view.rebuild()
	_record("destroyed",view,0)
	for p in gates: game.sim.door_hp[p] = Types.DOOR_MAX_HP
	view.rebuild()
	_record("restored",view,16)
	var file := FileAccess.open(OUT + "game-contact-inventory.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"\t"))
	if FileAccess.file_exists(game.save_path):
		failed = true
		push_error("Static review unexpectedly wrote its isolated save")
	game.queue_free()
	await process_frame
	print("Game contact review: ",records.size()," states; failed=",failed)
	quit(1 if failed else 0)
