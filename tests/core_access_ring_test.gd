extends SceneTree

var failures := 0

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func _init() -> void:
	for y in range(0, GameTypes.ROWS, 2):
		for x in range(0, GameTypes.COLS, 2):
			var sim := DungeonSim.new()
			sim.new_map()
			var origin := Vector2i(x, y)
			check(sim._place_core(origin), "place Core %s" % origin)
			var ring: Array[Vector2i] = []
			for cy in range(maxi(0, y - 1), mini(GameTypes.ROWS, y + 3)):
				for cx in range(maxi(0, x - 1), mini(GameTypes.COLS, x + 3)):
					if cx >= x and cx < x + 2 and cy >= y and cy < y + 2:
						continue
					ring.append(Vector2i(cx, cy))
			check(sim.gold == GameTypes.START_GOLD, "access ring is free")
			var all_floor := true
			for cell in ring:
				all_floor = all_floor and sim.grid[cell.y][cell.x] == GameTypes.Tile.FLOOR
			check(all_floor, "all clipped access cells must be floor at %s" % origin)
			if not all_floor:
				continue
			var queue: Array[Vector2i] = [ring[0]]
			var seen := {ring[0]: true}
			while not queue.is_empty():
				var p: Vector2i = queue.pop_front()
				for direction in GameTypes.DIRS:
					var next: Vector2i = p + direction
					if next in ring and not seen.has(next) and sim._can_step(p, next):
						seen[next] = true
						queue.append(next)
			check(seen.size() == ring.size(), "all sides connect without crossing Core at %s" % origin)
			for cell in ring:
				for tile in [GameTypes.Tile.DOOR, GameTypes.Tile.MAGIC_DOOR]:
					check(not sim._can_place_tile(cell, tile), "access cannot be blocked by a door")
				sim._place_entrance(cell)
				check(sim.grid[cell.y][cell.x] == GameTypes.Tile.FLOOR, "entrance cannot sever ring")
				check(sim._can_place_tile(cell, GameTypes.Tile.VAULT), "walkable vault allowed")
				check(sim._can_place_tile(cell, GameTypes.Tile.SNARE), "walkable trap allowed")
	_test_saved_dungeon()
	_test_opposite_corridors()
	print("Core access ring: %d failures" % failures)
	quit(1 if failures else 0)

func _test_saved_dungeon() -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	var raid := RaidDirector.new()
	var profile := CoreProgression.new()
	raid.sim = sim
	sim.raid = raid
	for y in range(6, 8):
		for x in range(6, 8):
			sim.grid[y][x] = GameTypes.Tile.CORE
	var door := Vector2i(5, 6)
	var magic := Vector2i(8, 6)
	var vault := Vector2i(6, 5)
	var trap := Vector2i(7, 5)
	for p in [door, magic]:
		sim.grid[p.y][p.x] = GameTypes.Tile.DOOR if p == door else GameTypes.Tile.MAGIC_DOOR
		sim.door_hp[p] = 20
		sim.door_opened[p] = true
		raid.kingdom_knowledge[p] = sim.grid[p.y][p.x]
	sim.grid[vault.y][vault.x] = GameTypes.Tile.VAULT
	sim.gold = 100
	sim.vault_gold[vault] = 100
	sim.grid[trap.y][trap.x] = GameTypes.Tile.SNARE
	sim.trap_charges[trap] = 2
	sim.grid[8][6] = GameTypes.Tile.ENTRANCE
	sim.grid[9][6] = GameTypes.Tile.FLOOR
	var snapshot := MobileSave.capture(sim, raid, profile)
	check(MobileSave.apply(snapshot, sim, raid, profile), "load legacy layout")
	check(sim.grid[6][5] == GameTypes.Tile.FLOOR and sim.grid[6][8] == GameTypes.Tile.FLOOR, "remove blocking legacy doors")
	check(sim.door_hp.is_empty() and sim.door_opened.is_empty(), "clear displaced door state")
	check(sim._unsecured_loot_total() == 120 and sim.gold == 100, "refund legacy door value without moving treasury gold")
	check(sim.vault_gold[vault] == 100 and sim.trap_charges[trap] == 2, "preserve traversable vault and trap")
	check(not raid.kingdom_knowledge.has(door) and not raid.kingdom_knowledge.has(magic), "forget displaced doors")
	check(sim._find_tile(GameTypes.Tile.ENTRANCE) == Vector2i(6, 9), "relocate entrance outside access ring")
	var migrated := MobileSave.capture(sim, raid, profile)
	check(MobileSave.apply(migrated, sim, raid, profile), "reload migrated layout")
	check(MobileSave.capture(sim, raid, profile) == migrated, "migration idempotent without duplicated refunds")
	sim.raid = null
	raid.sim = null

func _test_opposite_corridors() -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	sim._place_core(Vector2i(6, 6))
	var raid := RaidDirector.new()
	raid.sim = sim
	raid.solid_core = true
	for x in [3, 4, 9, 10]:
		sim.grid[6][x] = GameTypes.Tile.FLOOR
	sim._place_entrance(Vector2i(10, 6))
	check(sim._has_entrance(), "entrance at right corridor end")
	var known := {}
	for y in GameTypes.ROWS:
		for x in GameTypes.COLS:
			known[Vector2i(x, y)] = sim.grid[y][x]
	for endpoints in [[Vector2i(10, 6), Vector2i(3, 6)], [Vector2i(3, 6), Vector2i(10, 6)]]:
		var h := {"pos": endpoints[0], "kind": "thief", "known": known, "visited": {}, "bias": {}, "fear_weight": 1.0, "trap_weight": 1.0}
		for step in 24:
			if h.pos == endpoints[1]:
				break
			var next := raid._route_step(h, {endpoints[1]: true})
			check(next != h.pos and sim.grid[next.y][next.x] != GameTypes.Tile.CORE, "hero routes around solid Core without getting stuck")
			h.pos = next
		check(h.pos == endpoints[1], "both corridors accessible from the right entrance, including return route")
	raid.sim = null
