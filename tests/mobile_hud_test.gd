extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

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
	ui._layout()
	ui._refresh()
	await process_frame
	assert(ui.top.size.x < 450, "Resources must not span the screen")
	assert(not ui.cameras.visible, "Secondary controls are tucked away")
	assert(ui.category_buttons[1].global_position.x > ui.category_buttons[0].global_position.x)
	ui._category(1)
	assert(not ui.tray_collapsed and ui.buttons[GameTypes.Tool.TRAP_VOID].button.visible)
	assert(not ui.navigation.visible, "Tools replace categories instead of stacking")
	assert(is_equal_approx(ui.bottom.position.y, ui.navigation.position.y), "Both menus occupy the same row")
	ui.tray_toggle.pressed.emit()
	assert(ui.navigation.visible and not ui.bottom.visible, "Back restores categories")
	ui._category(1)
	ui._category(1)
	assert(ui.tray_collapsed and not ui.bottom.visible)
	ui._category(1)
	ui.menu_button.pressed.emit()
	assert(ui.cameras.visible)
	await process_frame
	var camera_controls = ui.cameras.get_children()
	for index in range(1, camera_controls.size()):
		var gap: float = camera_controls[index].position.y - (camera_controls[index - 1].position.y + camera_controls[index - 1].size.y)
		assert(gap >= 8.0, "Camera controls need a visible gap")
	assert(ui.cameras.get_global_rect().end.y < ui.raid_button.position.y, "Camera menu fits above Raid")
	ui.menu_button.pressed.emit()
	assert(not ui.cameras.visible)
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		await process_frame
		ui._layout()
		await process_frame
		assert(ui.bottom.get_global_rect().end.x <= ui.size.x)
		assert(ui.bottom.get_global_rect().end.y <= ui.size.y)
		assert(not ui.top.get_global_rect().intersects(ui.phase.get_parent().get_global_rect()))
		assert(is_equal_approx(ui.top.size.y, ui.core_panel.size.y), "Gold and core panels share a height")
		assert(is_equal_approx(ui.top.size.y, ui.status_panel.size.y), "Gold and phase panels share a height")
		ui.cameras.show()
		await process_frame
		assert(ui.cameras.get_global_rect().end.y < ui.raid_button.position.y, "Restart menu fits above Raid at every viewport")
	game.queue_free()
	await process_frame
	print("OK: compact HUD and responsive category navigation")
	quit()
