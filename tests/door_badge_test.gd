extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	game._new_map()
	var cell := Vector2i(3, 3)
	var other := Vector2i(4, 3)
	game.grid[other.y][other.x] = GameTypes.Tile.DOOR
	game.door_hp[other] = 0
	for tile in [GameTypes.Tile.DOOR, GameTypes.Tile.MAGIC_DOOR]:
		game.grid[cell.y][cell.x] = tile
		game.door_hp[cell] = GameTypes.DOOR_MAX_HP
		ui._sync_door_badges()
		var badge: Control = ui.door_badges[cell]
		assert(badge.ratio == 1.0 and not badge.repair_button.visible)
		game.door_hp[cell] = 30
		ui._sync_door_badges()
		assert(badge.ratio == 0.5 and not badge.repair_button.visible)
		for opened in [false, true]:
			game.door_hp[cell] = 60 if opened else 0
			game.door_opened[cell] = opened
			game.gold = 0
			ui._sync_door_badges()
			assert(badge.repair_button.visible and badge.repair_button.disabled)
			assert(not game.sim.repair_door(cell))
			game.gold = 100
			game.raid.raid_active = true
			ui._sync_door_badges()
			assert(badge.repair_button.disabled and not game.sim.repair_door(cell))
			game.raid.raid_active = false
			ui._sync_door_badges()
			badge.repair_button.pressed.emit()
			assert(game.gold == 85 and game.door_hp[cell] == 60)
			assert(not game.door_opened.get(cell, false))
			assert(game.door_hp[other] == 0)
			assert(not badge.repair_button.visible and badge.ratio == 1.0)
			assert(not game.sim.repair_door(cell) and game.gold == 85)
	game._new_map()
	ui._sync_door_badges()
	assert(ui.door_badges.is_empty())
	game.queue_free()
	await process_frame
	print("OK: door rings, broken/open repairs, raid/funds guards, isolation and reset")
	quit()
