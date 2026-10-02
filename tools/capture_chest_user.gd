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
	print("Vaults: ", game._storage_state()["vaults"])
	game.cam_zoom = 2.8
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		ui._center(Vector2i(7, 1))
		for walls in [true, false]:
			game.dungeon.set_mobile_walls_visible(walls)
			game._sync_world()
			for vault_cell in [Vector2i(5, 0), Vector2i(9, 0)]:
				var cell_root: Node3D = game.dungeon._cells[vault_cell]
				for wall in cell_root.get_children():
					if wall.name.begins_with("MobileMasonry"):
						var stone: MeshInstance3D = wall.get_child(0)
						var bounds: AABB = wall.transform * stone.transform * stone.get_aabb()
						assert(bounds.end.z <= 0.001, "Map border wall must not consume the vault floor")
			for frame in 8:
				ui.modal.hide()
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/chest-user-%d-%s.png" % [yaw, "walls" if walls else "cutaway"]) == OK)
	quit()
