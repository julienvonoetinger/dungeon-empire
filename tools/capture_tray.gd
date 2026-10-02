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
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game._sync_world()
	game.mobile_ui._refresh()
	var ui = game.mobile_ui
	assert(ui.get("tray_toggle") != null, "Bottom tray must have a collapse handle")
	for width in [1280, 960]:
		root.size = Vector2i(width, width * 9 / 16)
		for collapsed in [false, true]:
			if ui.tray_collapsed != collapsed:
				ui.tray_toggle.pressed.emit()
			for i in 10:
				await process_frame
			assert(ui.tray_toggle.visible and ui.phase.is_visible_in_tree())
			assert(ui.build_options.visible != collapsed)
			assert(not ui.tray_toggle.get_global_rect().intersects(ui.bottom.get_global_rect()))
			assert(root.get_texture().get_image().save_png("res://artifacts/tray-%d-%s.png" % [width, "collapsed" if collapsed else "expanded"]) == OK)
	ui.tray_toggle.pressed.emit()
	ui.selected = Vector2i(4, 7)
	ui._update_preview()
	ui._refresh()
	for i in 6:
		await process_frame
	assert(ui.actions.visible and not ui.actions.get_global_rect().intersects(ui.tray_toggle.get_global_rect()))
	assert(root.get_texture().get_image().save_png("res://artifacts/tray-selected.png") == OK)
	var selection: Vector2i = ui.selected
	var handle: Vector2 = ui.tray_toggle.get_global_rect().get_center()
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = handle
		click.global_position = handle
		click.pressed = pressed
		root.push_input(click, true)
		await process_frame
	assert(ui.tray_collapsed and ui.selected == selection, "Actual handle input must collapse without changing map selection")
	var taps := {"count": 0}
	ui.router.tapped.connect(func(_point: Vector2): taps.count += 1)
	for point in [Vector2(ui.bottom.position.x + 40, ui.bottom.position.y - 90), ui.tray_toggle.get_global_rect().get_center()]:
		for pressed in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = point
			touch.pressed = pressed
			ui.route(touch)
	assert(taps.count == 1, "Freed tray space accepts a world tap; handle never leaks a tap to the dungeon")
	game.queue_free()
	await process_frame
	print("OK: expanded/collapsed tray at two mobile sizes, selection actions and handle do not overlap")
	quit()
