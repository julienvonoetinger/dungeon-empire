extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if "--icon-only" in OS.get_cmdline_user_args():
		await _icon()
		quit()
		return
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.category = 1
	game.cam_zoom = 2.6
	game.mobile_ui._center(Vector2i(10, 4))
	var cell := Vector2i(10, 4)
	game.sim.grid[cell.y][cell.x] = GameTypes.Tile.SPIKE
	game.sim.trap_charges[cell] = 3
	game.mobile_ui._refresh()
	for state in ["armed", "active", "broken"]:
		game.hero["trap_sprung_at"] = cell if state == "active" else Vector2i(-1, -1)
		game.sim.trap_charges[cell] = 0 if state == "broken" else 3
		for yaw in [45, 135, 225, 315]:
			game.cam_yaw = yaw
			game.mobile_ui._center(cell)
			for i in 24:
				await process_frame
			var picture := root.get_texture().get_image()
			assert(picture.save_png("res://artifacts/spines-%s-%d.png" % [state, yaw]) == OK)
	game.cam_yaw = 45
	game.mobile_ui._center(cell)
	root.size = Vector2i(960, 540)
	for i in 12:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/spines-small.png") == OK)
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
	game.raid._trigger_trap(cell, GameTypes.Tile.SPIKE)
	assert(game.sim.trap_charges[cell] == 0)
	assert(game.hero.trap_sprung_at == cell)
	game.mobile_ui._center(cell)
	for i in 24:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/spines-hero-last-charge.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: Vulkan spines captures, three states at four camera angles")
	quit()


func _icon() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	preload("res://scripts/world/mobile_spines.gd").add_to(world, false, true)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.1
	camera.position = Vector3(1.7, 1.7, 1.7)
	camera.look_at(Vector3(0.5, 0.25, 0.5))
	for i in 12:
		await process_frame
	var picture := viewport.get_texture().get_image()
	assert(picture.get_used_rect().get_area() > 1000)
	assert(picture.save_png("res://assets/mobile/spikes-icon-v2.png") == OK)
	viewport.queue_free()
	await process_frame
