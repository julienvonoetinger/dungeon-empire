extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var started := Time.get_ticks_msec()
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.tray_collapsed = false
	game.mobile_ui._layout()
	for y in game.ROWS:
		for x in game.COLS:
			game.grid[y][x] = GameTypes.Tile.ROCK
	for y in range(6, 8):
		for x in range(5, 7):
			game.grid[y][x] = GameTypes.Tile.CORE
	for x in range(7, 15):
		game.grid[7][x] = GameTypes.Tile.VAULT if x < 11 else GameTypes.Tile.FLOOR
	game.grid[7][14] = GameTypes.Tile.ENTRANCE
	game.core_hp = 100
	game.gold = 60
	game.cam_zoom = 1.30
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(Vector2i(9, 7))
		for shown in [true, false]:
			game.dungeon.set_mobile_walls_visible(shown)
			game._sync_world()
			for i in 6:
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/environment-%s-%d.png" % [shown, yaw]) == OK)
	root.size = Vector2i(960, 540)
	game.cam_yaw = 45
	game.mobile_ui._center(Vector2i(9, 7))
	game._sync_world()
	for i in 6:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/environment-small.png") == OK)
	root.size = Vector2i(1280, 720)
	game.cam_zoom = 2.15
	game.mobile_ui.tray_collapsed = true
	game.mobile_ui._layout()
	game.mobile_ui._center(Vector2i(10, 7))
	for shown in [true, false]:
		game.dungeon.set_mobile_walls_visible(shown)
		game._sync_world()
		for i in 6:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/environment-detail-%s.png" % shown) == OK)
	game.cam_zoom = 3.2
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(Vector2i(14, 7))
		game.dungeon.set_mobile_walls_visible(true)
		for i in 6:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/entrance-detail-%d.png" % yaw) == OK)
		game.dungeon.set_mobile_walls_visible(false)
		for i in 6:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/entrance-detail-hidden-%d.png" % yaw) == OK)
	# Exercise anchoring on the game's two-cell placement grid.
	for y in game.ROWS:
		for x in game.COLS:
			game.grid[y][x] = GameTypes.Tile.ROCK
	game.mobile_selection = Vector2i(6, 6)
	game.mobile_ui.selected = Vector2i(6, 6)
	game.dungeon.set_mobile_walls_visible(true)
	game.mobile_ui._center(Vector2i(6, 6))
	for i in 6:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/environment-core-preview.png") == OK)
	assert(game._place_core(Vector2i(6, 6)))
	game.mobile_ui._cancel()
	for i in 6:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/environment-core-anchored.png") == OK)
	print("OK: environment views and small viewport; total capture ms=", Time.get_ticks_msec() - started)
	game.queue_free()
	await process_frame
	quit()
