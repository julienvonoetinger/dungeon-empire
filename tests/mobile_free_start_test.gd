extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	game.starter_enabled = true
	root.add_child(game)
	call_deferred("_run", game)

func _place(ui, game: Node, tool: int, cell: Vector2i) -> bool:
	ui._choose_tool(tool)
	ui.selected = cell
	ui._update_preview()
	if not ui.preview.get("valid", false):
		return false
	ui._confirm()
	return true

func _run(game: Node) -> void:
	await process_frame
	var ui = game.mobile_ui
	check(not game._has_core() and not game._has_entrance(), "starter-enabled fresh session stays unpopulated")
	game.dungeon.sync(game)
	check(ui._is_empty_dungeon() and game.dungeon._cells.size() == GameTypes.COLS * GameTypes.ROWS,
		"free-start all-rock cells render in the mobile world (cells=%d mobile=%s)" % [game.dungeon._cells.size(), str(game.dungeon.mobile_mode)])
	check(not game._ready_for_raid(), "raid is unavailable before player places required structures")
	game.raid_timer = 11.0
	ui.paused = false
	ui.tick(90.0)
	check(is_equal_approx(game.raid_timer, 11.0) and not game.raid_active,
		"raid countdown does not run before the dungeon is ready")
	ui.paused = true
	ui.selected = Vector2i(6, 6)
	ui._update_preview()
	check(ui.preview.get("valid", false), "player can preview Core placement")
	ui._confirm()
	check(game._has_core(), "confirmed selection places Core")
	var dug := true
	for x in range(4, 0, -1):
		dug = _place(ui, game, GameTypes.Tool.DIG, Vector2i(x, 6)) and dug
	check(dug, "player can manually dig a passage from the Core")
	var stored := _place(ui, game, GameTypes.Tool.STORE, Vector2i(5, 6))
	stored = _place(ui, game, GameTypes.Tool.STORE, Vector2i(4, 6)) and stored
	check(stored and game._storage_capacity() >= game.gold, "player can build enough manual storage (stored=%s gold=%d cap=%d message=%s)" % [str(stored), game.gold, game._storage_capacity(), game.message])
	check(_place(ui, game, GameTypes.Tool.BUILD_ENTRANCE, Vector2i(1, 6)), "player can place entrance against backed perimeter wall")
	check(game._has_entrance() and game._ready_for_raid(), "manual Core, storage and entrance enable raids")
	check(not game.persistence_enabled, "test never reads or writes a real user save")
	game.queue_free()
	await process_frame
	print("Mobile free start: %d failures" % failures)
	quit(1 if failures else 0)
