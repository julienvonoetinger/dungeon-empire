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
	assert(ui.save_api.apply(ui.save_api.read_save("res://artifacts/chest-user-repro.save"), game.sim, game.raid, ui.profile))
	ui.paused = true
	ui._cancel()
	game.cam_zoom = 3.5
	game.cam_yaw = 45
	game.gold = 100
	var cell := Vector2i(7, 4)
	ui._center(cell)
	game.dungeon.set_mobile_walls_visible(false)
	for state in ["closed", "broken", "opened", "repaired"]:
		game.door_hp[cell] = 0 if state == "broken" else 60
		game.door_opened[cell] = state == "opened" or state == "repaired"
		if state == "repaired":
			assert(game.sim.repair_door(cell))
		game._sync_world()
		for frame in 8:
			ui.modal.hide()
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/door-badge-%s.png" % state) == OK)
	quit()
