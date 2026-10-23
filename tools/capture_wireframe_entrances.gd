extends SceneTree

## Actual Godot rendering of each entrance and its neighbouring corridor cell.
func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(1000, 1000)
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/WireframeClosedCorridors.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera2D = scene.get_node("Camera2D")
	var dungeon: Node2D = scene.get_node("Dungeon")
	var centres := {
		"north": Vector2(1.47, -1.42),
		"east": Vector2(4.03, 1.36),
		"south": Vector2(1.47, 4.03),
		"west": Vector2(-1.10, 1.36),
	}
	for direction in centres:
		camera.position = centres[direction] * 256.0
		camera.zoom = Vector2.ONE * 1.85
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/wireframe-entrance-%s-detail.png" % direction)
		print("Rendered entrance detail ", direction)
	var entrance_count := 0
	for child in dungeon.get_children():
		if str(child.name).begins_with("Entrance_"):
			entrance_count += 1
	print("Complete entrance sprites: ", entrance_count)
	viewport.remove_child(scene)
	scene.free()
	quit()
