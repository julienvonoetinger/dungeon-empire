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
	game.cam_zoom = 3.2
	var cell: Vector2i = game._core_origin()
	for walls in [true, false]:
		game.dungeon.set_mobile_walls_visible(walls)
		for hp in [100, 50, 0]:
			game.core_hp = hp
			for yaw in [45, 135, 225, 315]:
				game.cam_yaw = yaw
				game.mobile_ui._center(cell)
				game._sync_world()
				for i in 6:
					await process_frame
				assert(root.get_texture().get_image().save_png("res://artifacts/core-v2-%d-%d-%s.png" % [hp, yaw, walls]) == OK)
	# The player's initial two-cell chamber is tighter than the starter test map.
	for y in game.ROWS:
		for x in game.COLS:
			game.grid[y][x] = GameTypes.Tile.ROCK
	for y in 2:
		for x in 2:
			game.grid[cell.y + y][cell.x + x] = GameTypes.Tile.CORE
	for y in range(maxi(0, cell.y - 4), cell.y):
		game.grid[y][cell.x] = GameTypes.Tile.FLOOR
	game.cam_yaw = 45
	game.cam_zoom = 2.6
	game.core_hp = 100
	game.mobile_ui._center(cell)
	for walls in [true, false]:
		game.dungeon.set_mobile_walls_visible(walls)
		game._sync_world()
		for i in 6:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/core-v2-chamber-%s.png" % walls) == OK)
	game.queue_free()
	await process_frame
	print("OK: Core masonry states, rotations and manual walls")
	quit()
