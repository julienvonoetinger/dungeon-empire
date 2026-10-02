extends SceneTree

func _init() -> void:
	var commands = preload("res://scripts/mobile/mobile_build.gd").new()
	var profile = preload("res://scripts/game/core_progression.gd").new()
	profile.testing_unlock_defenses = true
	for tool in [GameTypes.Tool.BUILD_DOOR, GameTypes.Tool.BUILD_MAGIC_DOOR]:
		for p in [Vector2i(5, 0), Vector2i(5, GameTypes.ROWS - 1), Vector2i(0, 5), Vector2i(GameTypes.COLS - 1, 5)]:
			var sim := DungeonSim.new()
			sim.new_map()
			assert(sim._place_core(Vector2i(6, 6)))
			sim.gold = 300
			var along := Vector2i.RIGHT if p.y in [0, GameTypes.ROWS - 1] else Vector2i.DOWN
			for offset in [-1, 0, 1]:
				var cell: Vector2i = p + along * offset
				sim.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
			var before := sim.grid.duplicate(true)
			var preview: Dictionary = commands.preview(sim, profile, tool, p)
			assert(preview.valid, "Border wall must support a door at %s" % p)
			assert(sim.grid == before and sim.gold == 300)
			assert(commands.commit(sim, profile, tool, p))
			assert(sim.gold == 300 - preview.cost)
			assert(sim.door_hp[p] == GameTypes.DOOR_MAX_HP)
			# A widened passage still has no pair of opposite walls.
			var inward := Vector2i.DOWN if p.y == 0 else Vector2i.UP if p.y == GameTypes.ROWS - 1 else Vector2i.RIGHT if p.x == 0 else Vector2i.LEFT
			sim.grid[p.y][p.x] = GameTypes.Tile.FLOOR
			var neighbour: Vector2i = p + inward
			sim.grid[neighbour.y][neighbour.x] = GameTypes.Tile.FLOOR
			assert(not commands.preview(sim, profile, tool, p).valid)
	print("OK: normal and magic doors on all four borders, costs and wide-passage rejection")
	quit()
