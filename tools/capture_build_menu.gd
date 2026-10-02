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
	ui.category = 0
	ui.tray_collapsed = false
	ui._layout()
	ui._refresh()
	game.cam_zoom = 3.5
	ui._center(game._core_origin())
	game._sync_world()
	for frame in 10:
		ui.modal.hide()
		await process_frame
	for id in [GameTypes.Tool.DIG, GameTypes.Tool.STORE, GameTypes.Tool.BUILD_DOOR, GameTypes.Tool.BUILD_ENTRANCE]:
		var button: Button = ui.buttons[id].button
		var box: VBoxContainer = button.get_child(0)
		var icon: TextureRect = box.get_child(0)
		var caption: Label = box.get_child(1)
		assert(absf(icon.get_global_rect().get_center().x - button.get_global_rect().get_center().x) < 1.0)
		var content_center := (icon.global_position.y + caption.get_global_rect().end.y) * 0.5
		assert(absf(content_center - button.get_global_rect().get_center().y) < 1.0)
	assert(root.get_texture().get_image().save_png("res://artifacts/build-menu-centered.png") == OK)
	print("OK: all four building options centered horizontally and vertically")
	quit()
