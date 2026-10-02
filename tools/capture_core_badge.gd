extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	assert(ui.save_api.apply(ui.save_api.read_save("res://artifacts/chest-user-repro.save"), game.sim, game.raid, ui.profile))
	ui.paused = true
	ui._cancel()
	game.cam_zoom = 3.5
	game.core_hp = 65
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		ui._center(game._core_origin())
		game.dungeon.set_mobile_walls_visible(false)
		game._sync_world()
		for frame in 8:
			ui.modal.hide()
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/core-badge-%d.png" % yaw) == OK)
	quit()
