extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	for y in GameTypes.ROWS:
		for x in GameTypes.COLS:
			if game.grid[y][x] != GameTypes.Tile.CORE:
				game.grid[y][x] = GameTypes.Tile.ROCK
	var cell := Vector2i(3, 3)
	for y in range(3, 8):
		game.grid[y][3] = GameTypes.Tile.FLOOR
	for x in range(3, 7):
		game.grid[7][x] = GameTypes.Tile.FLOOR
	game.grid[cell.y][cell.x] = GameTypes.Tile.VAULT
	assert(game.grid[2][3] == GameTypes.Tile.ROCK)
	assert(game.grid[3][2] == GameTypes.Tile.ROCK and game.grid[3][4] == GameTypes.Tile.ROCK)
	game.mobile_ui._cancel()
	game.mobile_ui.selected = Vector2i(-1, -1)
	game.mobile_selection = Vector2i(-1, -1)
	game.cam_zoom = 5.5
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(cell)
		for walls in [true, false]:
			game.dungeon.set_mobile_walls_visible(walls)
			for gold in [100, 0]:
				game.gold = gold
				game._sync_world()
				for frame in 8:
					game.mobile_ui.modal.hide()
					await process_frame
				assert(game.dungeon._cells[cell].has_node("MobileProp"))
				assert(root.get_texture().get_image().save_png("res://artifacts/chest-corridor-%d-%s-%s.png" % [yaw, "walls" if walls else "cutaway", "full" if gold else "empty"]) == OK)
	print("OK: dead-end vault with three rock neighbors, four angles, walls on/off, full/empty; no save writes")
	quit()
