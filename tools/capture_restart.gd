extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(960, 540)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.core_hp = 0
	game.game_over = true
	game.mobile_ui._show_defeat_recovery()
	for i in 4:
		await process_frame
	game.mobile_ui.modal_continue.pressed.emit()
	game.mobile_ui.paused = true
	for i in 12:
		await process_frame
	var suffix := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	assert(root.get_texture().get_image().save_png("res://artifacts/restart-%s.png" % suffix) == OK)
	print("RESTART core=", game._has_core(), " entrance=", game._has_entrance(), " viewport=", game._world_port.render_target_update_mode)
	if suffix == "after":
		assert(not game._has_core() and not game._has_entrance(), "Restart must return to free placement")
		assert(game.dungeon._mobile_core_preview.visible, "Restart must show the Core placement preview")
	game.queue_free()
	await process_frame
	quit()
