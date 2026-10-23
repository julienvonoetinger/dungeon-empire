extends SceneTree

## Human-review views of the entry and the original two-cell-wide connections.
func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(1200, 1000)
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera2D = scene.get_node("Camera2D")
	var dungeon: Node2D = scene.get_node("Dungeon")
	var centres := {
		"entry": Vector2(3.5, 2.85),
		"crossing": Vector2(13, 5.85),
		"west-join": Vector2(8, 5.85),
		"southwest-join": Vector2(4, 8),
		"lower-join": Vector2(16, 13.85),
	}
	for detail in centres:
		camera.position = centres[detail] * 256.0
		camera.zoom = Vector2.ONE * 1.15
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/wireframe-six-rooms-%s.png" % detail)
		print("Rendered six-room detail ", detail)
	var entrance_count := 0
	for child in dungeon.get_children():
		if str(child.name).begins_with("Entrance_"):
			entrance_count += 1
	print("Logical cells: ", dungeon.get_connection_plan().cells.size(), "; entrance sprites: ", entrance_count)
	viewport.remove_child(scene)
	scene.free()
	quit()
