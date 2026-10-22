extends SceneTree

## Actual GPU renders for visual review only: no probes, scores or assertions.
const ROOMS := ["1x1CellRoom", "2x2CellRoom", "3x3CellRoom"]
const CORRIDORS := ["1x2Corridor", "2x1Corridor", "1x3Corridor", "3x1Corridor"]

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	for scene_name in ROOMS + CORRIDORS:
		await _capture_room(scene_name)
	await _capture_gallery(ROOMS, 3, "cell-rooms-comparison")
	await _capture_gallery(CORRIDORS, 2, "corridors-comparison")
	quit()

func _capture_room(scene_name: String) -> void:
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/" + scene_name + ".tscn").instantiate()
	var dungeon: Node2D = scene.get_node("Dungeon")
	var frame: Rect2 = dungeon.get_content_rect()
	viewport.size = Vector2i(frame.size.ceil() * 2)
	viewport.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var prefix := "res://artifacts/" + scene_name
	viewport.get_texture().get_image().save_png(prefix + "-2x.png")
	viewport.size = Vector2i(frame.size.ceil())
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(prefix + ".png")
	var cap: Rect2 = dungeon.get_cap_rect()
	var camera: Camera2D = scene.get_node("Camera2D")
	viewport.size = Vector2i(320, ceili((cap.size.y + 90) * 4))
	await process_frame
	camera.zoom = Vector2.ONE * 4
	for side in ["west", "east"]:
		camera.position = Vector2(cap.position.x + 13 if side == "west" else cap.end.x - 13, cap.get_center().y + 30)
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(prefix + "-" + side + "-4x.png")
	viewport.size = Vector2i(ceili((cap.size.x + 30) * 4), 280)
	await process_frame
	camera.zoom = Vector2.ONE * 4
	for wall in ["north", "south"]:
		camera.position = Vector2(cap.get_center().x, cap.position.y + 31 if wall == "north" else cap.end.y + 28)
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(prefix + "-" + wall + "-4x.png")
	print("Visual capture: ", scene_name)
	viewport.queue_free()
	await process_frame

func _capture_gallery(names: Array, columns: int, filename: String) -> void:
	var scenes: Array[Node2D] = []
	var panel := Vector2.ZERO
	for scene_name in names:
		var scene: Node2D = load("res://scenes/" + scene_name + ".tscn").instantiate()
		scene.get_node("Camera2D").enabled = false
		var frame: Rect2 = scene.get_node("Dungeon").get_content_rect()
		panel = panel.max(frame.size)
		scenes.append(scene)
	panel = panel.ceil() + Vector2(16, 40)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(panel * Vector2(columns, ceili(float(names.size()) / columns)))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for index in range(names.size()):
		var origin := Vector2(index % columns, index / columns) * panel
		var scene := scenes[index]
		var frame: Rect2 = scene.get_node("Dungeon").get_content_rect()
		scene.position = origin + Vector2((panel.x - frame.size.x) * 0.5, 30)
		viewport.add_child(scene)
		var label := Label.new()
		label.text = names[index]
		label.position = origin + Vector2(16, 8)
		label.add_theme_font_size_override("font_size", 18)
		viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://artifacts/" + filename + ".png")
	viewport.queue_free()
	await process_frame
