extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.category = 1
	game.cam_zoom = 2.6
	game.mobile_ui._center(Vector2i(11, 4))
	var cell := Vector2i(11, 4)
	game.sim.grid[cell.y][cell.x] = GameTypes.Tile.VOID
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
			assert(picture.save_png("res://artifacts/void-%s-%d.png" % [state, yaw]) == OK)
	game.cam_yaw = 45
	game.mobile_ui._center(cell)
	root.size = Vector2i(960, 540)
	for i in 12:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/void-small.png") == OK)
	# Probe actual lighting on the sealed stone, not just its material flags.
	game.sim.trap_charges[cell] = 1
	game.hero.erase("trap_sprung_at")
	game._sync_world()
	for i in 8:
		await process_frame
	var point := Vector3(cell.x + 0.5, 0.181, cell.y + 0.5)
	var pixel: Vector2i = Vector2i(game.dungeon.camera.unproject_position(point))
	var before: Color = game._world_port.get_texture().get_image().get_pixelv(pixel)
	var torch := OmniLight3D.new()
	torch.light_color = Color(1.0, 0.55, 0.18)
	torch.light_energy = 2.0
	torch.omni_range = 3.0
	torch.position = point + Vector3(0, 1.0, 0)
	game.dungeon.add_child(torch)
	for i in 8:
		await process_frame
	var lit: Image = game._world_port.get_texture().get_image()
	var after: Color = lit.get_pixelv(pixel)
	print("Void lighting probe pixel ", pixel, " red: ", before.r, " -> ", after.r)
	assert(root.get_texture().get_image().save_png("res://artifacts/void-warm-light.png") == OK)
	assert(after.r > before.r + 0.03, "Void stone must respond to a warm light")
	torch.queue_free()
	await process_frame
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
	game.raid._trigger_trap(cell, GameTypes.Tile.VOID)
	assert(game.sim.trap_charges[cell] == 0)
	assert(game.hero.trap_sprung_at == cell)
	game.mobile_ui._center(cell)
	for i in 24:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/void-hero-last-charge.png") == OK)
	var previous_scale := INF
	for progress in [0.0, 0.5, 0.95]:
		game.hero.portal_t = game.PORTAL_HOLD * (1.0 - progress)
		for i in 8:
			await process_frame
		var floor_trap: Sprite3D = game.dungeon._cells[cell].get_node("MobileProp/VoidFloor")
		assert(floor_trap.texture.resource_path.ends_with("void-active-v3.png"))
		assert(game.dungeon._hero.scale.x <= previous_scale)
		previous_scale = game.dungeon._hero.scale.x
		assert(root.get_texture().get_image().save_png("res://artifacts/void-absorption-%d.png" % int(progress * 100)) == OK)
	game.raid._update_hero(game.PORTAL_HOLD)
	for i in 12:
		await process_frame
	var collapsed: Sprite3D = game.dungeon._cells[cell].get_node("MobileProp/VoidFloor")
	assert(collapsed.texture.resource_path.ends_with("void-broken-v3.png"))
	game.mobile_ui.modal.hide()
	for i in 2:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/void-after-absorption.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: Vulkan void captures, three states at four camera angles")
	quit()
