extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	var data: Dictionary = ui.save_api.read_save("res://artifacts/chest-user-repro.save")
	assert(ui.save_api.apply(data, game.sim, game.raid, ui.profile))
	ui.paused = true
	ui._cancel()
	ui.selected = Vector2i(-1, -1)
	game.mobile_selection = Vector2i(-1, -1)
	game.cam_zoom = 4.8
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		ui._center(Vector2i(7, 1))
		for walls in [true, false]:
			game.dungeon.set_mobile_walls_visible(walls)
			game._sync_world()
			for frame in 8:
				ui.modal.hide()
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/spike-user-%d-%s.png" % [yaw, "walls" if walls else "cutaway"]) == OK)
	game.cam_yaw = 45
	ui._center(Vector2i(7, 1))
	game.dungeon.set_mobile_walls_visible(false)
	game._sync_world()
	for charges in [2, 1, 0, 3]:
		game.trap_charges[Vector2i(7, 1)] = charges
		game._sync_world()
		ui._sync_trap_badges()
		for frame in 8:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/spike-charges-%d.png" % charges) == OK)
	# Inspect animation artwork without starting a raid or changing the saved run.
	var cell: Node3D = game.dungeon._cells[Vector2i(7, 1)]
	var mechanism: Node3D = cell.get_node("MobileProp")
	for state in ["active", "broken"]:
		for child in mechanism.get_children():
			child.free()
		preload("res://scripts/world/mobile_spines.gd").add_to(mechanism, state == "broken", state == "active")
		cell.get_node("MobileTrapCharges").position.y = 1.15 if state == "active" else 0.65
		for frame in 8:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/spike-user-%s.png" % state) == OK)
	quit()
