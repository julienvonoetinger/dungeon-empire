extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	assert(not ui.tray_toggle.visible, "Anchoring keeps its dedicated confirmation bar")
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	ui.paused = true
	ui._cancel()
	ui._refresh()
	assert(ui.tray_collapsed and ui.navigation.visible and not ui.tray_toggle.visible, "Fresh HUD shows categories only")
	ui._toggle_tray()
	assert(not ui.tray_collapsed)
	assert(ui.profile.level() == 1 and ui.profile.testing_unlock_defenses)
	for defense in [GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID, GameTypes.Tool.BUILD_MAGIC_DOOR]:
		assert(not ui.buttons[defense].button.disabled, "Playtest defense buttons are unlocked")
		assert(not "Niv." in ui.buttons[defense].label.text, "Unlocked defenses display their price")
	assert(ui.tray_toggle.custom_minimum_size == Vector2(56, 104), "Back occupies the same row as tools")
	ui.selected = Vector2i(4, 7)
	ui._update_preview()
	ui._refresh()
	var selected_category: int = ui.category
	ui._toggle_tray()
	assert(ui.tray_collapsed and not ui.build_options.visible and not ui.actions.visible)
	assert(ui.selected.x < 0 and ui.tool == GameTypes.Tool.NONE and ui.category == selected_category, "Back cancels placement")
	var path := "user://tray-test-%d.cfg" % Time.get_ticks_usec()
	assert(ui._save_tray_preference(path) == OK)
	ui._toggle_tray()
	assert(not ui.tray_collapsed and ui.build_options.visible and not ui.actions.visible)
	ui._load_tray_preference(path)
	assert(ui.tray_collapsed, "Preference reload restores collapsed state")
	assert(DirAccess.remove_absolute(path) == OK)
	game.raid_active = true
	ui._layout()
	ui._refresh()
	assert(not ui.tray_toggle.visible and not ui.build_options.visible)
	game.raid_active = false
	ui._layout()
	ui._refresh()
	assert(ui.tray_collapsed and ui.navigation.visible and not ui.build_options.visible)
	ui._toggle_tray()
	assert(ui.selected.x < 0 and not ui.actions.visible)
	game.queue_free()
	await process_frame
	print("OK: tray toggles, cancels selection, restores preference and survives raid transitions")
	quit()
