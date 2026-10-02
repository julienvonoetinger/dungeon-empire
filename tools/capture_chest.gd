extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.tray_collapsed = true
	game.mobile_ui._layout()
	var cell := Vector2i(2, 3)
	game.mobile_ui.selected = Vector2i(-1, -1)
	game.mobile_selection = cell
	game.cam_zoom = 2.6
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(cell)
		for walls in [true, false]:
			game.dungeon.set_mobile_walls_visible(walls)
			for gold in [100, 0]:
				game.gold = gold
				game._sync_world()
				for i in 8:
					await process_frame
				var chest: Sprite3D = game.dungeon._cells[cell].get_node("MobileProp")
				var point := chest.global_position
				assert(is_equal_approx(point.x, cell.x + 0.5) and is_equal_approx(point.z, cell.y + 0.5))
				assert(root.get_texture().get_image().save_png("res://artifacts/chest-%d-%s-%s.png" % [yaw, "walls" if walls else "open", "full" if gold else "empty"]) == OK)
	game.queue_free()
	await process_frame
	print("OK: centered full/empty chests, four camera orientations, walls visible/hidden")
	quit()
