extends SceneTree

## Render the actual cell-sprite scenes for human review, without assertions.
func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var names := OS.get_cmdline_user_args()
	if names.is_empty():
		names = PackedStringArray(["WireframeClosedCorridors", "2x2CellRoom", "3x3RoomCornerCorridors"])
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(1280, 960)
	root.add_child(viewport)
	for scene_name in names:
		var scene: Node2D = load("res://scenes/%s.tscn" % scene_name.validate_filename()).instantiate()
		viewport.add_child(scene)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/wireframe-%s.png" % scene_name)
		viewport.size = Vector2i(2560, 1920)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/wireframe-%s-2x.png" % scene_name)
		viewport.remove_child(scene)
		scene.free()
		viewport.size = Vector2i(1280, 960)
		print("Rendered wireframe ", scene_name)
	quit()
