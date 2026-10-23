extends SceneTree

## Enlarged captures of the real door sprites and neighbouring corridor cells.
func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(1000, 1000)
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/WireframeDoorCross.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera2D = scene.get_node("Camera2D")
	var dungeon: Node2D = scene.get_node("Dungeon")
	for cell: Vector2i in dungeon.door_cells:
		var facing: String = dungeon.door_cells[cell]
		camera.position = (Vector2(cell) + Vector2(0.45, 0.25)) * 256.0
		camera.zoom = Vector2.ONE * 2.0
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/wireframe-door-%s-detail.png" % facing)
		print("Rendered door detail ", facing)
	viewport.remove_child(scene)
	scene.free()
	quit()
