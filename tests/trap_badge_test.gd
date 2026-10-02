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
	for tile in [GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE, GameTypes.Tile.VOID]:
		game.grid[cell.y][cell.x] = tile
		var capacity: int = game._trap_max_charges(tile)
		game.trap_charges[cell] = capacity
		ui._sync_trap_badges()
		var badge: Control = ui.trap_badges[cell]
		assert(badge.ratio == 1.0 and badge.amount == capacity)
		assert(badge.size.x == 42 and not badge.repair_button.visible)
		assert(badge.icon != null and badge.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		game.trap_charges[cell] = capacity - 1
		ui._sync_trap_badges()
		assert(ui.trap_badges[cell] == badge)
		assert(is_equal_approx(badge.ratio, float(capacity - 1) / capacity))
		game.trap_charges[cell] = 0
		ui._sync_trap_badges()
		assert(badge.amount == 0 and badge.ratio == 0.0)
		assert(badge.repair_button.visible and badge.size.x == 134)
		game.gold = 0
		ui._sync_trap_badges()
		assert(badge.repair_button.disabled)
		assert(game.sim.repair_trap(cell) == 0)
		game.gold = 100
		game.raid.raid_active = true
		ui._sync_trap_badges()
		assert(badge.repair_button.disabled)
		assert(game.sim.repair_trap(cell) == 0 and game.gold == 100)
		game.raid.raid_active = false
		var other := Vector2i(4, 3)
		game.grid[other.y][other.x] = GameTypes.Tile.SPIKE
		game.trap_charges[other] = 0
		ui._sync_trap_badges()
		assert(not badge.repair_button.disabled)
		badge.repair_button.pressed.emit()
		assert(game.trap_charges[cell] == capacity)
		assert(game.gold == 100 - capacity * GameTypes.COST_REPAIR_TRAP)
		assert(game.trap_charges[other] == 0, "repair only the clicked trap")
		assert(not badge.repair_button.visible)
		game.trap_charges[cell] = capacity
		ui._sync_trap_badges()
		assert(badge.ratio == 1.0)
	game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
	ui._sync_trap_badges()
	assert(not ui.trap_badges.has(cell))
	game._new_map()
	ui._sync_trap_badges()
	assert(ui.trap_badges.is_empty())
	game.queue_free()
	await process_frame
	print("OK: all trap badge types, consumption, repair, removal and restart")
	quit()
