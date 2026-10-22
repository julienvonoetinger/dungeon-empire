extends SceneTree

## With a real renderer; optional arguments: width height name scene_path.
func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var arguments := OS.get_cmdline_user_args()
	var dimensions := Vector2i(1692, 1152)
	var filename := "dungeon-2d.png"
	var scene_path := "res://scenes/SixRoomPreview.tscn"
	if arguments.size() >= 2:
		dimensions = Vector2i(arguments[0].to_int(), arguments[1].to_int())
	if arguments.size() >= 3:
		filename = arguments[2].get_file()
	if arguments.size() >= 4:
		scene_path = arguments[3]
	if dimensions.x <= 0 or dimensions.y <= 0:
		push_error("Capture dimensions must be positive")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Cannot load capture scene: " + scene_path)
		quit(1)
		return
	var scene := packed.instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var output := "res://artifacts/" + filename
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var result := viewport.get_texture().get_image().save_png(output)
	if result != OK:
		push_error("Could not save capture: %s" % error_string(result))
	else:
		print("Saved: " + ProjectSettings.globalize_path(output))
	viewport.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
