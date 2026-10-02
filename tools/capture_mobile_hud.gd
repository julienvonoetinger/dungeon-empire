extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/hud-%s.png" % label) == OK)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	var ui = game.mobile_ui
	ui.paused = true
	ui._cancel()
	ui.tray_collapsed = true
	ui._layout()
	ui._refresh()
	game.cam_zoom = 1.55
	ui._center_core()
	await _capture("overview")
	ui._category(1)
	await _capture("traps")
	ui.menu_button.pressed.emit()
	assert(ui.cameras.visible)
	await _capture("menu")
	ui.menu_button.pressed.emit()
	ui.selected = Vector2i(4, 7)
	ui._update_preview()
	ui._refresh()
	await _capture("placement")
	ui._cancel()
	ui._toggle_tray()
	root.size = Vector2i(960, 540)
	await _capture("phone")
	ui._pause_menu()
	await _capture("pause")
	ui._continue()
	ui._start_raid()
	ui.paused = true
	ui._layout()
	ui._refresh()
	await _capture("raid")
	game.queue_free()
	await process_frame
	print("OK: HUD captures completed")
	quit()
