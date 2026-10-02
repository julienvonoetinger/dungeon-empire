extends SceneTree

var game
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	game.starter_enabled = false
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ui = game.mobile_ui
	check(ui != null, "Mobile UI ready")
	ui.size = Vector2(1280, 720)
	ui._layout()
	check(ui.walls_button != null, "manual wall visibility button exists")
	if ui.walls_button != null:
		check(ui.walls_button.get_global_rect().end.y <= 720, "wall visibility button fits the 720 logical viewport")
	ui.paused = true
	ui.selected = Vector2i(6, 6)
	ui._update_preview()
	check(ui.preview.valid, "Core preview valid")
	check(not game._has_core(), "Preview does not place core")
	ui._confirm()
	check(game._has_core(), "Confirmation places core")
	ui._center_core()
	var first: Vector2 = game.cam_pan
	ui._center_core()
	check(first.distance_to(game.cam_pan) < 0.01, "Recenter converges without drift")
	ui._choose_tool(GameTypes.Tool.DIG)
	ui.selected = Vector2i(5, 6)
	ui._update_preview()
	check(ui.preview.cost == 5, "Dig cost shown")
	ui._confirm()
	check(game.gold == 315, "Confirm pays once")
	ui._confirm()
	check(game.gold == 315, "Second confirmation cannot spend again")
	ui._choose_tool(GameTypes.Tool.TRAP_SNARE)
	ui.selected = Vector2i(5, 6)
	ui._update_preview()
	check(ui.preview.valid, "Playtest session unlocks Entrave at level one")
	ui.profile.testing_unlock_defenses = false
	ui._update_preview()
	check(not ui.preview.valid, "Progression gate still works outside playtest mode")
	ui.profile.testing_unlock_defenses = true
	ui._cancel()
	game.core_hp = 90
	for y in range(8, 11):
		for x in range(8, 11):
			game.grid[y][x] = GameTypes.Tile.FLOOR
	game.loot_bags = [{"pos": Vector2i(8, 8), "gold": 20, "taken": false}]
	game.corpses = [{"pos": Vector2i(8, 8), "name": "Test", "fear": 18.0}]
	ui._choose_tool(GameTypes.Tool.ABSORB)
	ui.paused = false
	ui._tap(game._cell_pos(Vector2i(8, 8)))
	check(ui.selected == Vector2i(8, 8), "Full-storage loot must not block selecting corpse; selected %s" % ui.selected)
	check(game.gold == 315 and game.corpses.size() == 1, "Tap previews without collecting or absorbing")
	ui._confirm()
	check(game.corpses.is_empty() and game.loot_bags.size() == 1, "Explicit absorption works independently of loot")
	game.core_hp = 100
	ui.paused = true
	for item in ui.buttons.values():
		check(item.button.custom_minimum_size.x >= 48 and item.button.custom_minimum_size.y >= 48, "Touch target minimum")
	game.raid_index = 1
	game.raid_active = true
	game.raid_stats = {"killed": 1, "escaped": 0, "carried_out": 0, "traps_spent": 3, "core_lost": 0}
	game._end_raid("Victory")
	check(ui.result_open and ui.modal.visible, "Result opens")
	check(ui.profile.xp == 80, "XP awarded")
	var reward_gold: int = game.gold
	ui._raid_finished(game.raid.last_result)
	check(ui.profile.xp == 80 and game.gold == reward_gold, "Result cannot double reward")
	ui._continue()
	check(not ui.result_open and not ui.paused, "Continue resumes prep")
	game.core_hp = 0
	game.game_over = true
	game.raid_index = 2
	game.raid_stats = {"killed": 0, "escaped": 1, "carried_out": 5, "core_lost": 100}
	game._end_raid("Defeat")
	ui._continue()
	check(not game.game_over and not game._has_core(), "Defeat permits new dungeon")
	check(game.raid_index == ui.profile.last_raid_id and ui.profile.xp == 80, "New dungeon retains profile and monotonic raid IDs")
	game.queue_free()
	await process_frame
	print("Mobile session: %d failures" % failures)
	quit(1 if failures else 0)
