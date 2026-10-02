extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	game._new_map()
	game.sim._place_core(Vector2i(6, 6))
	for x in range(8, 11):
		game.grid[6][x] = GameTypes.Tile.VAULT
	game.gold = 305
	ui.modal.hide()
	ui.paused = false
	ui.tool = GameTypes.Tool.DIG
	ui.category = 0
	ui.tray_collapsed = false
	ui._cancel()
	ui._layout()
	game.cam_zoom = 4.5
	for walls in [false, true]:
		game.dungeon.mobile_walls_visible = walls
		for yaw in [45.0, 135.0, 225.0, 315.0]:
			game.cam_yaw = yaw
			ui._center(Vector2i(9, 6))
			game.dungeon.sync(game)
			for x in range(8, 11):
				var cell := Vector2i(x, 6)
				var sprite: Sprite3D = game.dungeon._cells[cell].get_node("MobileProp")
				for uv in [Vector2(0.5, 0.65), Vector2(0.5, 0.3)]:
					var offset := (Vector2(uv.x - 0.5, 0.5 - uv.y) * sprite.texture.get_size() + sprite.offset) * sprite.pixel_size
					var world: Vector3 = sprite.global_position + game.dungeon.camera.global_basis.x * offset.x + game.dungeon.camera.global_basis.y * offset.y
					var screen: Vector2 = game._to_world_screen(game.dungeon._world_to_screen(world, game._play_view(), game.cam_zoom))
					ui._tap(screen)
					assert(ui.vault_transfer.visible and ui.vault_transfer.source == cell, "Chest click must open correct vault with build tray open: %s yaw %s walls %s uv %s" % [cell, yaw, walls, uv])
					assert(ui.selected.x < 0 and not ui.actions.visible)
					if "--capture" in OS.get_cmdline_user_args() and not walls and yaw == 45.0 and x == 9 and uv.y > 0.6:
						for frame in 5:
							await process_frame
						assert(root.get_texture().get_image().save_png("res://artifacts/vault-click-fixed.png") == OK)
					ui.vault_transfer.close()
	game.queue_free()
	await process_frame
	print("OK: chest body/lid clicks with build tray open, three wall-backed vaults, four angles and both wall modes")
	quit()
