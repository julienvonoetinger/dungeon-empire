extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/ui-symbols-%s.png" % label) == OK)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	for cell in [Vector2i(2, 3), Vector2i(3, 3)]:
		game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
	for cell in [Vector2i(5, 6), Vector2i(5, 7)]:
		game.grid[cell.y][cell.x] = GameTypes.Tile.VAULT
	game.gold = 180
	game.grid[5][5] = GameTypes.Tile.DOOR
	game.grid[8][8] = GameTypes.Tile.MAGIC_DOOR
	for i in 3:
		var cell := Vector2i(6 + i, 5)
		var tile: int = [GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE, GameTypes.Tile.VOID][i]
		game.grid[cell.y][cell.x] = tile
		game.trap_charges[cell] = game._trap_max_charges(tile) if i != 1 else 0
	game.cam_zoom = 1.55
	ui._center_core()
	ui._cancel()
	ui.tray_collapsed = true
	ui._layout()
	ui._refresh()
	await _capture("overview")
	for category in 3:
		ui._category(category)
		await _capture(["doors", "chests", "traps"][category])
	root.size = Vector2i(960, 540)
	ui._layout()
	ui._refresh()
	await _capture("small")
	game.queue_free()
	await process_frame
	print("OK: dedicated UI icon captures at desktop and compact sizes")
	quit()
