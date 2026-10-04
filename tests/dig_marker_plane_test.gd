extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._place_core(Vector2i(6, 6))
	for cell in [Vector2i(7, 4), Vector2i(7, 3), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2)]:
		game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
	var ui = game.mobile_ui
	ui.paused = false
	ui._cancel()
	var world = game.dungeon
	for walls in [true, false]:
		world.set_mobile_walls_visible(walls)
		world.sync(game)
		for yaw in [0.0, 45.0, 135.0, 225.0, 315.0]:
			game.cam_yaw = yaw
			ui._center_core()
			world.apply_camera(game.cam_zoom, game.cam_pan, game._play_view(), game.COLS, game.ROWS, yaw)
			ui._update_dig_hover()
			var height: float = world.ROCK_H if walls else maxf(world.FLOOR_H, world.ROCK_H * world.MOBILE_CUTAWAY_SCALE)
			for cell in ui.diggable_cells:
				var corners: PackedVector2Array = ui._dig_tile_corners(cell)
				var expected: Vector2 = game._to_world_screen(world._world_to_screen(Vector3(cell.x + 0.08, height + 0.025, cell.y + 0.08), game._play_view(), game.cam_zoom))
				check(corners[0].distance_to(expected) < 0.01, "all markers use the same plane: %s walls=%s yaw=%s" % [cell, walls, yaw])
				if ui.has_method("_dig_cell_at"):
					var center := (corners[0] + corners[2]) * 0.5
					check(ui._dig_cell_at(center) == cell, "marker center targets its displayed cell")
	check(ui.has_method("_dig_cell_at"), "dig interaction must use displayed marker plane")
	if ui.has_method("_dig_cell_at"):
		world.set_mobile_walls_visible(true)
		world.sync(game)
		game.cam_yaw = 45.0
		ui._center_core()
		world.apply_camera(game.cam_zoom, game.cam_pan, game._play_view(), game.COLS, game.ROWS, game.cam_yaw)
		ui._update_dig_hover()
		var target: Vector2i = ui.diggable_cells[0]
		var corners: PackedVector2Array = ui._dig_tile_corners(target)
		var center := (corners[0] + corners[2]) * 0.5
		ui._dig_pointer = center
		ui._dig_pointer_over_ui = false
		ui._update_dig_hover()
		check(ui.dig_hover == target, "hover agrees with marker")
		var gold: int = game.gold
		ui._tap(center)
		check(game.grid[target.y][target.x] == GameTypes.Tile.FLOOR and game.gold == gold - 5, "click digs the marked cell exactly once")
	if "--capture" in OS.get_cmdline_user_args():
		ui._update_dig_hover()
		ui._refresh()
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/dig-marker-plane.png")
	game.queue_free()
	await process_frame
	print("Dig marker plane failures: ", failures)
	quit(1 if failures else 0)
