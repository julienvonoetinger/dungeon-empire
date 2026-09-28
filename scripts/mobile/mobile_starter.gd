class_name MobileStarter
extends RefCounted

static func populate(sim: DungeonSim, raid: RaidDirector) -> void:
	var raid_index := raid.raid_index
	sim.new_map()
	raid.reset_for_new_map()
	raid.raid_index = raid_index
	sim.raid = raid
	raid.sim = sim

	# Separate chambers echo the mockup's central Core and satellite rooms.
	for room in [Rect2i(5, 5, 4, 4), Rect2i(2, 2, 3, 3),
			Rect2i(10, 3, 3, 3), Rect2i(2, 9, 3, 3)]:
		for y in range(room.position.y, room.end.y):
			for x in range(room.position.x, room.end.x):
				sim.grid[y][x] = GameTypes.Tile.FLOOR
	sim.grid[3][12] = GameTypes.Tile.ROCK
	for passage in [Vector2i(4, 5), Vector2i(9, 5), Vector2i(4, 8)]:
		sim.grid[passage.y][passage.x] = GameTypes.Tile.FLOOR
	sim._place_core(Vector2i(6, 6))
	for vault in [Vector2i(2, 3), Vector2i(3, 3)]:
		sim.grid[vault.y][vault.x] = GameTypes.Tile.VAULT
	for spike in [Vector2i(10, 4), Vector2i(11, 4)]:
		sim.grid[spike.y][spike.x] = GameTypes.Tile.SPIKE
		sim.trap_charges[spike] = GameTypes.TRAP_MAX_CHARGES
	sim.grid[10][3] = GameTypes.Tile.ENTRANCE
	sim.gold = 140
	sim.message = "The dungeon is ready."
