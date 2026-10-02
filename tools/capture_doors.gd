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
	var cell := Vector2i(8, 8)
	for y in game.ROWS:
		for x in game.COLS:
			game.grid[y][x] = GameTypes.Tile.ROCK
	for y in range(4, 13):
		game.grid[y][8] = GameTypes.Tile.FLOOR
	game.grid[11][8] = GameTypes.Tile.CORE
	game.grid[12][8] = GameTypes.Tile.CORE
	game.grid[11][9] = GameTypes.Tile.CORE
	game.grid[12][9] = GameTypes.Tile.CORE
	game.cam_zoom = 3.2
	game.mobile_ui._center(cell)
	for magic in [false, true]:
		game.grid[8][8] = GameTypes.Tile.MAGIC_DOOR if magic else GameTypes.Tile.DOOR
		for state in ["closed", "damaged", "opened", "destroyed"]:
			game.door_hp[cell] = 0 if state == "destroyed" else 20 if state == "damaged" else game.DOOR_MAX_HP
			game.door_opened[cell] = state == "opened"
			for yaw in [45, 135, 225, 315]:
				game.cam_yaw = yaw
				game.mobile_ui._center(cell)
				game._sync_world()
				for i in 6:
					await process_frame
				assert(root.get_texture().get_image().save_png("res://artifacts/door-%s-%s-%d.png" % ["magic" if magic else "normal", state, yaw]) == OK)
	game.dungeon.set_mobile_walls_visible(false)
	game.door_hp[cell] = game.DOOR_MAX_HP
	game.door_opened[cell] = false
	game.cam_yaw = 45
	game.mobile_ui._center(cell)
	game._sync_world()
	for i in 6:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/door-walls-hidden.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: both doors, four states, four views and manual wall visibility")
	quit()
