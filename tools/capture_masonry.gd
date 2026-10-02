extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui.modal.hide()
	game.mobile_ui._cancel()
	game.cam_zoom = 2.0
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center_core()
		for shown in [true, false]:
			game.dungeon.set_mobile_walls_visible(shown)
			for i in 12:
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/masonry-%s-%d.png" % ["shown" if shown else "hidden", yaw]) == OK)
	root.size = Vector2i(960, 540)
	game.cam_yaw = 45
	game.mobile_ui._center_core()
	for i in 12:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/masonry-small.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: masonry captures in both modes, four angles and small viewport")
	quit()
