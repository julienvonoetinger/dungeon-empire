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
	ui.paused = true
	assert(game.sim._place_core(Vector2i(6, 6)))
	game.gold = 300
	for x in range(3, 9):
		game.grid[0][x] = GameTypes.Tile.FLOOR
	for y in range(1, 6):
		game.grid[y][7] = GameTypes.Tile.FLOOR
	ui._category(0)
	ui._choose_tool(GameTypes.Tool.BUILD_DOOR)
	ui.selected = Vector2i(5, 0)
	ui._update_preview()
	ui._refresh()
	assert(ui.preview.valid and not ui.confirm.disabled)
	assert(is_equal_approx(game.dungeon._door_yaw(ui.selected, game), PI * 0.5))
	game.cam_zoom = 2.0
	ui._center(Vector2i(5, 0))
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/door-border-preview.png") == OK)
	ui._confirm()
	assert(game.grid[0][5] == GameTypes.Tile.DOOR)
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/door-border-placed.png") == OK)
	# Also inspect the frame embedded in ordinary lateral rock walls.
	for x in range(3, 9):
		game.grid[0][x] = GameTypes.Tile.ROCK
		game.grid[3][x] = GameTypes.Tile.FLOOR
	game.grid[3][5] = GameTypes.Tile.DOOR
	game.door_hp[Vector2i(5, 3)] = game.DOOR_MAX_HP
	game.cam_zoom = 3.0
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		ui._center(Vector2i(5, 3))
		for shown in [true, false]:
			game.dungeon.set_mobile_walls_visible(shown)
			for i in 6:
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/door-fit-%d-%s.png" % [yaw, shown]) == OK)
	game.door_opened[Vector2i(5, 3)] = true
	game.cam_yaw = 135
	ui._center(Vector2i(5, 3))
	await create_timer(0.35).timeout
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/door-prototype-open.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: border door preview, orientation and confirmation")
	quit()
