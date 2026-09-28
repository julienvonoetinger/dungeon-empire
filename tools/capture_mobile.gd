extends SceneTree

var game

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	game.starter_enabled = false
	root.add_child(game)
	call_deferred("_capture")

func _capture() -> void:
	await process_frame
	root.size = Vector2i(1280, 720)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	load("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.mobile_ui.profile.xp = 80
	game.cam_zoom = 1.35
	game.mobile_ui._center_core()
	for i in 12:
		await process_frame
	await _save("mobile-management.png")
	game.mobile_ui.selected = Vector2i(8, 7)
	game.mobile_ui.tool = GameTypes.Tool.TRAP_SPIKE
	game.mobile_ui.category = 1
	game.mobile_ui._update_preview()
	game.mobile_ui._refresh()
	await _save("mobile-build.png")
	game.mobile_ui._cancel()
	game.mobile_ui.paused = false
	game.mobile_ui._start_raid()
	game.mobile_ui.paused = true
	game.hero.pos = Vector2i(3, 10)
	game.mobile_ui._center(game.hero.pos)
	await _save("mobile-raid.png")
	root.size = Vector2i(1560, 720)
	await _save("mobile-wide.png")
	root.size = Vector2i(960, 540)
	await _save("mobile-small.png")
	game.raid_stats = {"killed": 1, "escaped": 0, "carried_out": 0, "core_lost": 0, "traps_spent": 2}
	game._end_raid("Victory")
	await _save("mobile-result.png")
	game.queue_free()
	await process_frame
	quit()

func _save(filename: String) -> void:
	for i in 8:
		await process_frame
	RenderingServer.force_draw()
	await process_frame
	var image := root.get_texture().get_image()
	assert(image != null and not image.is_empty())
	assert(image.save_png("res://artifacts/" + filename) == OK)
	print("Saved ", filename, " ", image.get_size())
	print("Render counters: draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
