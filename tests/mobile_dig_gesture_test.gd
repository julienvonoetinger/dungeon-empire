extends SceneTree

var strokes: Array = []
var pans: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _point(game, cell: Vector2i) -> Vector2:
	var center: Vector2 = game._cell_pos(cell)
	for y in range(-64, 65, 4):
		for x in range(-64, 65, 4):
			var point := center + Vector2(x, y)
			if game._screen_to_grid(point) == cell:
				return point
	assert(false, "No selectable point for %s" % cell)
	return center

func _run() -> void:
	var router := MobileInputRouter.new()
	router.painting_enabled = true
	router.painted.connect(func(a, b): strokes.append([a, b]))
	router.panned.connect(func(delta): pans.append(delta))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100, 100)
	router.handle_event(press)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(200, 100)
	router.handle_event(move)
	assert(strokes.size() == 1 and pans.is_empty())
	move.position = Vector2(300, 100)
	router.handle_event(move, true)
	assert(strokes.size() == 1, "No digging over UI")
	move.position = Vector2(400, 100)
	router.handle_event(move)
	assert(strokes.back()[0] == strokes.back()[1], "No stroke through UI on reentry")
	router.cancel()
	strokes.clear()
	press.button_index = MOUSE_BUTTON_RIGHT
	router.handle_event(press)
	router.handle_event(move)
	assert(strokes.is_empty() and not pans.is_empty(), "Right drag still pans")
	router.cancel()
	for index in 2:
		var touch := InputEventScreenTouch.new()
		touch.index = index
		touch.pressed = true
		touch.position = Vector2(100 + 100 * index, 100)
		router.handle_event(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(80, 100)
	router.handle_event(drag)
	assert(strokes.is_empty(), "Pinch never digs")
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game._new_map()
	game.sim._place_core(Vector2i(6, 6))
	game.gold = 10
	var ui = game.mobile_ui
	ui.modal.hide()
	ui.paused = false
	ui.category = 0
	ui.tray_collapsed = false
	ui.tool = GameTypes.Tool.DIG
	ui._cancel()
	game.dungeon.mobile_walls_visible = false
	game.dungeon.sync(game)
	var unreachable := Vector2i(3, 5)
	var unreachable_point := _point(game, unreachable)
	ui._dig_pointer = unreachable_point
	ui._dig_pointer_over_ui = false
	ui._update_dig_hover()
	assert(ui.dig_hover.x < 0 and not ui.dig_hint.visible, "Unreachable rock has no marker or price")
	ui._tap(unreachable_point)
	ui._update_dig_hover()
	assert(ui.selected.x < 0 and not ui.actions.visible and not ui.dig_hint.visible, "Invalid click stays silent")
	assert(game.gold == 10 and game.grid[unreachable.y][unreachable.x] == GameTypes.Tile.ROCK)
	for cell in [Vector2i(4, 6), Vector2i(3, 6)]:
		game.dungeon.mobile_walls_visible = false
		game.dungeon.sync(game)
		var point: Vector2 = _point(game, cell)
		assert(game._screen_to_grid(point) == cell)
		ui._dig_pointer = point
		ui._dig_pointer_over_ui = false
		ui._update_dig_hover()
		assert(ui.dig_hover == cell and ui.dig_hover_valid, "Hover targets the exact dig cell")
		assert(ui.selected.x < 0 and not ui.actions.visible, "Hover never opens confirmation")
		if "--capture" in OS.get_cmdline_user_args():
			for frame in 3:
				await process_frame
			root.get_texture().get_image().save_png("res://artifacts/dig-hover.png")
		ui._tap(point)
		assert(game.grid[cell.y][cell.x] == GameTypes.Tile.FLOOR)
		assert(ui.selected.x < 0 and not ui.actions.visible)
		ui._dig_stroke(point, point)
	assert(game.gold == 0, "Only new rock costs gold")
	ui._dig_pointer = _point(game, Vector2i(2, 6))
	ui._update_dig_hover()
	assert(ui.dig_hover.x < 0 and not ui.dig_hint.visible, "No funds hides unavailable excavation")
	ui._dig_pointer_over_ui = true
	ui._update_dig_hover()
	assert(ui.dig_hover.x < 0, "No hover through UI")
	ui._tap(game._cell_pos(Vector2i(2, 6)))
	assert(game.grid[6][2] == GameTypes.Tile.ROCK, "Stop without funds")
	game.gold = 100
	game.raid_active = true
	ui._dig_stroke(game._cell_pos(Vector2i(2, 6)), game._cell_pos(Vector2i(2, 6)))
	assert(game.gold == 100 and game.grid[6][2] == GameTypes.Tile.ROCK)
	game.raid_active = false
	game.dungeon.sync(game)
	var start := _point(game, Vector2i(2, 6))
	var finish := _point(game, Vector2i(1, 6))
	var pan: Vector2 = game.cam_pan
	ui._dig_stroke(start, finish)
	assert(game.grid[6][2] == GameTypes.Tile.FLOOR and game.grid[6][1] == GameTypes.Tile.FLOOR, "A long stroke digs connected cells")
	assert(game.cam_pan == pan, "Digging does not move camera")
	game.grid[6][5] = GameTypes.Tile.SPIKE
	ui._dig_stroke(_point(game, Vector2i(5, 6)), _point(game, Vector2i(5, 6)))
	assert(game.grid[6][5] == GameTypes.Tile.SPIKE, "Drag never demolishes structures")
	game.grid[6][5] = GameTypes.Tile.FLOOR
	ui.tool = GameTypes.Tool.TRAP_SPIKE
	ui._tap(_point(game, Vector2i(5, 6)))
	assert(ui.selected == Vector2i(5, 6) and game.grid[6][5] == GameTypes.Tile.FLOOR, "Other tools still preview")
	game.queue_free()
	await process_frame
	print("OK: paint vs pan, UI and pinch guards, immediate dig, costs, funds and raid guards")
	quit()
