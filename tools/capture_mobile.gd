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
	root.size = Vector2i(1280, 720)
	game.cam_zoom = 2.0
	game.mobile_ui.following = false
	game.hero.kind = "paladin"
	game.hero.display = "Paladin"
	game.hero.name = "Paladin"
	game.hero.door_portal_in = false
	game.hero.portal_t = 0.0
	game.hero.pos = Vector2i(5, 6)
	game.hero.objective = "core"
	for y in game.ROWS:
		for x in game.COLS:
			game.hero.known[Vector2i(x, y)] = game.grid[y][x]
	game.raid._update_hero(0.5)
	game.mobile_ui._refresh()
	assert(game.hero.pos == Vector2i(5, 6))
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center_core()
		for i in 40:
			await process_frame
		await _save("mobile-core-attack-%d.png" % yaw)
	for hp in [100, 51, 50, 1, 0, 100]:
		game.sim.core_hp = hp
		await _save("mobile-core-hp-%d.png" % hp)
	game.raid_stats = {"killed": 1, "escaped": 0, "carried_out": 0, "core_lost": 0, "traps_spent": 2}
	game._end_raid("Victory")
	await _save("mobile-result.png")
	game.mobile_ui.modal.hide()
	game.mobile_ui.result_open = false
	load("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.cam_yaw = 45
	game.cam_zoom = 2.2
	game.mobile_ui._center(Vector2i(11, 4))
	game.sim.grid[4][11] = GameTypes.Tile.SNARE
	game.sim.grid[5][11] = GameTypes.Tile.VOID
	game.sim.trap_charges[Vector2i(11, 5)] = 3
	game.mobile_ui._refresh()
	await _save("mobile-traps-armed.png")
	for cell in [Vector2i(10, 4), Vector2i(11, 4), Vector2i(11, 5)]:
		game.sim.trap_charges[cell] = 0
	await _save("mobile-traps-spent.png")
	game.sim.gold = 150
	game.cam_zoom = 2.5
	game.mobile_selection = Vector2i(3, 3)
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(Vector2i(3, 3))
		await _save("mobile-chests-%d.png" % yaw)
	game.sim.gold = 0
	await _save("mobile-chests-depleted.png")
	game.sim.gold = 300
	await _save("mobile-chests-refilled.png")
	game.mobile_ui.paused = false
	game.mobile_ui._start_raid()
	assert(game.raid_active)
	game.mobile_ui.paused = true
	game.mobile_ui.following = false
	game.hero.kind = "thief"
	game.hero.name = "Voleur"
	game.hero.display = "Voleur"
	game.hero.pos = Vector2i(3, 3)
	game.hero.facing = Vector2i.LEFT
	game.hero.collecting_gold = true
	game.mobile_ui._refresh()
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(Vector2i(3, 3))
		await _save("mobile-chests-loot-%d.png" % yaw)
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
	var prefix := "forward-" if "--forward-capture" in OS.get_cmdline_user_args() else ""
	assert(image.save_png("res://artifacts/" + prefix + filename) == OK)
	print("Saved ", filename, " ", image.get_size())
	print("Render counters: draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
