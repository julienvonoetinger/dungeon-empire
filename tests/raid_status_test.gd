extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.raid.raid_timer = 23.0
	ui._refresh()
	assert(ui.phase.text == "Prochain raid dans\n00:23", "Countdown clearly announces the next raid")
	game.raid._start_raid()
	ui._refresh()
	assert(ui.phase.text == "RAID 00:00", "Raid header shows elapsed time, not raid index")
	game.raid.elapsed_seconds = 42.0
	ui._refresh()
	assert(ui.phase.text == "RAID 00:42")
	ui.tick(1.0)
	assert(game.raid.elapsed_seconds == 42.0, "Pause freezes the clock")
	ui.paused = false
	ui.tick(0.25)
	assert(is_equal_approx(game.raid.elapsed_seconds, 42.25))
	ui.paused = true
	game.raid.elapsed_seconds = 125.0
	ui._refresh()
	assert(ui.phase.text == "RAID 02:05")
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		await process_frame
		ui._layout()
		await process_frame
		assert(ui.status_panel.position.y == 0.0, "Raid banner touches the top edge")
		assert(not ui.status_panel.get_global_rect().intersects(ui.core_panel.get_global_rect()))
		assert(not ui.status_panel.get_global_rect().intersects(ui.pause_button.get_global_rect()))
		assert(ui.phase.get_global_rect().end.x < ui.status_panel.get_global_rect().end.x)
	game.raid._end_raid("Test complete")
	game.raid._start_raid()
	ui._refresh()
	assert(ui.phase.text == "RAID 00:00", "Every raid resets the clock")
	game.queue_free()
	await process_frame
	print("OK: raid clock, pause, reset and header layout")
	quit()
