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

func _run(game: Node) -> void:
	await process_frame
	var ui = game.mobile_ui
	check(not game._has_core() and not game._has_entrance(), "fresh session starts without auto-placed Core or entrance")
	check(ui._is_empty_dungeon(), "fresh free-start map remains all rock")
	game.dungeon.sync(game)
	check(game.dungeon._cells.size() == GameTypes.COLS * GameTypes.ROWS and game.dungeon._cells.has(Vector2i.ZERO),
		"all-rock map has visible renderer cells")
	game.grid[8][8] = GameTypes.Tile.FLOOR
	var in_memory_save: Dictionary = ui.save_api.capture(game.sim, game.raid, ui.profile)
	game._new_map()
	check(ui.save_api.apply(in_memory_save, game.sim, game.raid, ui.profile), "nonempty save restores in memory")
	check(game.grid[8][8] == GameTypes.Tile.FLOOR and not ui._is_empty_dungeon(), "restored nonempty map is preserved")
	game._new_map()
	check(ui._is_empty_dungeon(), "all-rock saved dungeon is detected as empty")

	ui.profile.restore({"xp": 275, "last_raid_id": 19})
	game.raid_index = 19
	game.dungeon.set_mobile_walls_visible(false)
	game.cam_zoom = 1.35
	game.cam_pan = Vector2(125, -74)
	game.cam_yaw = 225.0
	ui.following = true
	ui.selected = Vector2i(9, 9)
	game.mobile_selection = ui.selected
	game.core_hp = 0
	game.game_over = true
	ui._show_defeat_recovery()
	check(ui.modal.visible and ui.modal_continue.text == "Nouveau donjon", "defeat offers a new dungeon")
	ui.modal_continue.emit_signal("pressed")
	check(not game._has_core() and not game._has_entrance(), "new dungeon after defeat remains an unplaced free start")
	check(ui.profile.xp == 275 and game.raid_index == 19 and ui.profile.last_raid_id == 19,
		"restart preserves XP and monotonic raid ID")
	check(ui._is_empty_dungeon() and ui.profile.xp == 275 and game.raid_index == 19,
		"restart preserves all-rock free start and progression")
	check(is_equal_approx(game.cam_yaw, 45.0) and is_equal_approx(game.cam_zoom, 2.0), "restart resets camera orientation and zoom")
	check(not ui.following and ui.selected == Vector2i(6, 6) and game.mobile_selection == Vector2i(6, 6),
		"restart clears stale selection and selects the Core anchor")
	check(ui.preview.get("valid", false), "restart default Core anchor has a valid ghost preview")
	check(not ui.result_open and not ui.paused and not ui.modal.visible, "restart closes defeat modal and resumes session")
	await process_frame
	check(not game.dungeon.mobile_walls_visible, "restart preserves hidden wall preference without persistence")
	check(not ui.walls_button.button_pressed, "wall button synchronizes with preserved hidden preference")
	check(not game.persistence_enabled, "restart test never writes a live save")
	game.queue_free()
	await process_frame
	print("Mobile restart: %d failures" % failures)
	quit(1 if failures else 0)
