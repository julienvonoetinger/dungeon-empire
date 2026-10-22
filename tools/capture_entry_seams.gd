extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1664,640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position = Vector2(592,370)
	camera.zoom = Vector2(2,2)
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://artifacts/entrance-seams-detail.png")
	print("Entrance at 2x: ",error_string(result))
	viewport.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
