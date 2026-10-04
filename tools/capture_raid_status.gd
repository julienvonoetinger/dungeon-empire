extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://artifacts/raid-status-%s.png" % label)
	var ui = root.get_node("Main").mobile_ui
	var scale: Vector2 = Vector2(image.get_size()) / ui.size
	var rect: Rect2 = ui.status_panel.get_global_rect().grow(6)
	image.get_region(Rect2i(rect.position * scale, rect.size * scale)).save_png("res://artifacts/raid-banner-%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	ui._center_core()
	ui._cancel()
	game.raid._start_raid()
	game.raid.elapsed_seconds = 42.0
	ui._layout()
	ui._refresh()
	await _capture("raid")
	root.size = Vector2i(960, 540)
	await process_frame
	ui._layout()
	ui._refresh()
	await _capture("compact")
	game.raid.raid_active = false
	game.raid.hero = {}
	game.raid.raid_timer = 25.0
	ui._layout()
	ui._refresh()
	await _capture("preparation")
	game.queue_free()
	await process_frame
	quit()
