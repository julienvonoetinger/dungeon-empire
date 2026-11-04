extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(800,700)
	var preview = load("res://scenes/previews/EnergyMasterPreview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_paused(true)
	preview.orbit_button.button_pressed = true
	await process_frame
	preview.viewport.size = Vector2i(480,480)
	DirAccess.make_dir_recursive_absolute("res://artifacts/energy-master/frames")
	for i in 360:
		preview.set_time(float(i)/15.0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var result: int = preview.viewport.get_texture().get_image().save_png("res://artifacts/energy-master/frames/%03d.png" % i)
		if result != OK:
			push_error("Could not save animation frame")
			quit(1)
			return
	print("CAPTURED_360_NATIVE_FRAMES")
	quit()
