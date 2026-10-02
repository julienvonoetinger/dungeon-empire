extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.category = 1
	game.cam_zoom = 2.6
	game.mobile_ui._center(Vector2i(11, 4))
	var cell := Vector2i(11, 4)
	game.sim.grid[cell.y][cell.x] = GameTypes.Tile.SNARE
	game.sim.trap_charges[cell] = 3
	game.mobile_ui._refresh()
	for state in ["hidden", "active", "broken"]:
		game.hero["trap_sprung_at"] = cell if state == "active" else Vector2i(-1, -1)
		game.sim.trap_charges[cell] = 0 if state == "broken" else 3
		for yaw in [45, 135, 225, 315]:
			game.cam_yaw = yaw
			game.mobile_ui._center(cell)
			for i in 24:
				await process_frame
			var picture := root.get_texture().get_image()
			assert(picture.save_png("res://artifacts/grasp-%s-%d.png" % [state, yaw]) == OK)
	game.cam_yaw = 45
	game.mobile_ui._center(cell)
	root.size = Vector2i(960, 540)
	for i in 12:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/grasp-small.png") == OK)
	game.hero.clear()
	game.mobile_ui.paused = false
	game.mobile_ui._start_raid()
	assert(game.raid_active)
	game.mobile_ui.paused = true
	game.mobile_ui.following = false
	game.hero.pos = cell
	game.hero.portal_t = 0.0
	game.hero.door_portal_in = false
	game.sim.trap_charges[cell] = 1
	game.raid._trigger_trap(cell, GameTypes.Tile.SNARE)
	assert(game.sim.trap_charges[cell] == 0)
	assert(game.hero.trap_sprung_at == cell)
	game.mobile_ui._center(cell)
	for i in 24:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/grasp-hero-last-charge.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: Vulkan grasp captures, three states at four camera angles")
	quit()
