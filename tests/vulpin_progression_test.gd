extends SceneTree

func _init() -> void:
	var raid := RaidDirector.new()
	assert(raid.has_method("_vulpin_lockpick_chance"), "Level-based lockpicking is missing")
	var chances := [0.50, 0.55, 0.55, 0.60, 0.60, 0.65, 0.65, 0.70, 0.70, 0.75, 0.75, 0.75]
	for index in chances.size():
		raid.hero = {"level": index + 1}
		assert(is_equal_approx(raid.call("_vulpin_lockpick_chance"), chances[index]))
		assert(raid.call("_vulpin_lockpick_limit") == 1 + index / 2)
	raid.hero = {}
	assert(raid.call("_vulpin_lockpick_limit") == 1 and raid.call("_vulpin_lockpick_chance") == 0.5)
	for level in [1, 2, 3, 5, 10, 11]:
		for vault in [false, true]:
			_test_quota(level, vault)
	_test_no_jump()
	_test_treasure_route_and_trap_arrival()
	print("OK: alternating lockpick progression, per-lock raid budgets, no Vulpin jump and unchanged Ranger jump")
	quit()

func _test_quota(level: int, vault: bool) -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	var raid := RaidDirector.new()
	raid.sim = sim
	var p := Vector2i(4, 4)
	var q := Vector2i(5, 4)
	for cell in [p, q]:
		sim.grid[cell.y][cell.x] = GameTypes.Tile.VAULT if vault else GameTypes.Tile.DOOR
		if vault:
			sim.vault_locks[cell] = 1
		else:
			sim.door_hp[cell] = GameTypes.DOOR_MAX_HP
	raid.hero = {"kind": "thief", "level": level, "display": "Vulpin", "ignored": {}, "lockpick_success_chance": 0.0}
	var limit: int = raid.call("_vulpin_lockpick_limit")
	raid._start_vulpin_lockpick(p)
	for attempt in limit:
		assert(raid.hero.get("lockpicking", false))
		raid._update_hero(RaidDirector.VULPIN_LOCKPICK_HOLD + 0.01)
		assert(raid.hero.lockpick_attempts[p] == attempt + 1)
		assert(bool(raid.hero.get("lockpicking", false)) == (attempt + 1 < limit))
	assert(sim.vault_protected(p) if vault else sim._door_intact(p))
	assert(raid.hero.ignored.has(p) if vault else raid.hero.avoided_doors.has(p))
	raid._start_vulpin_lockpick(p)
	assert(not raid.hero.get("lockpicking", false), "Revisiting must not restore the quota")
	raid._start_vulpin_lockpick(q)
	assert(raid.hero.get("lockpicking", false), "A different lock gets its own budget")
	raid.hero.lockpick_success_chance = 1.0
	raid._update_hero(RaidDirector.VULPIN_LOCKPICK_HOLD + 0.01)
	assert(not sim.vault_protected(q) if vault else not sim._door_intact(q))
	assert(sim.gold == GameTypes.START_GOLD, "Unlocking itself never steals money")
	# A real new raid clears the old lock budget and spawns at level one.
	sim.grid[0][0] = GameTypes.Tile.ENTRANCE
	raid._start_raid()
	assert(raid.hero.level == 1 and not raid.hero.has("lockpick_attempts"))
	assert(not raid.hero.has("lockpick_success_chance"))
	raid._start_vulpin_lockpick(p)
	assert(raid.hero.get("lockpicking", false))

func _test_no_jump() -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	var raid := RaidDirector.new()
	raid.sim = sim
	for x in range(3, 6):
		sim.grid[3][x] = GameTypes.Tile.FLOOR
	var start := Vector2i(3, 3)
	var trap := Vector2i(4, 3)
	sim.grid[3][4] = GameTypes.Tile.SPIKE
	sim.trap_charges[trap] = 3
	raid.hero = {"kind": "thief", "level": 10, "pos": start, "known": {trap: GameTypes.Tile.SPIKE}, "visited": {}}
	assert(not raid._try_trap_jump(start, trap), "No Vulpin level can jump a trap")
	assert(raid.hero.pos == start and not raid.hero.has("jumping_trap"))
	raid.hero.kind = "ranger"
	assert(raid._try_trap_jump(start, trap), "Ranger retains its own jumping ability")
	assert(raid.hero.pos == Vector2i(5, 3) and sim.trap_charges[trap] == 3)

func _test_treasure_route_and_trap_arrival() -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	var raid := RaidDirector.new()
	raid.sim = sim
	for x in range(2, 6):
		sim.grid[3][x] = GameTypes.Tile.FLOOR
	sim.grid[3][2] = GameTypes.Tile.ENTRANCE
	sim.grid[3][4] = GameTypes.Tile.SPIKE
	sim.grid[3][5] = GameTypes.Tile.VAULT
	sim.grid[2][3] = GameTypes.Tile.DOOR
	sim.grid[1][3] = GameTypes.Tile.FLOOR
	var trap := Vector2i(4, 3)
	var door := Vector2i(3, 2)
	sim.trap_charges[trap] = 3
	sim.door_hp[door] = GameTypes.DOOR_MAX_HP
	sim.gold = 100
	raid._start_raid()
	assert(raid.hero.level == 1 and is_equal_approx(raid.call("_vulpin_lockpick_chance"), 0.5))
	raid.hero.merge({"kind": "thief", "objective": "vault", "pos": Vector2i(3, 3), "hp": 100, "max_hp": 100, "flee_ratio": 0.01}, true)
	for y in sim.grid.size():
		for x in sim.grid[y].size():
			raid.hero.known[Vector2i(x, y)] = sim.grid[y][x]
	raid._update_hero(0.01)
	assert(raid.hero.pos == trap and raid.hero.has("trap_arrival_t"), "Treasure route wins over an unrelated door, with no trap jump")
	assert(not raid.hero.get("jumping_trap", false) and not raid.hero.get("lockpicking", false))
	assert(sim.trap_charges[trap] == 3 and raid.hero.hp == 100)
	raid._update_hero(GameTypes.TURN_TIME)
	assert(sim.trap_charges[trap] == 2 and raid.hero.hp == 70, "Walking onto the trap triggers only after arrival")
	assert(sim._door_intact(door), "Vulpin does not hunt doors away from its treasure route")
	raid.hero.level = 99
	sim.grid[2][3] = GameTypes.Tile.MAGIC_DOOR
	raid._attack_door(door)
	assert(not raid.hero.get("lockpicking", false) and sim._door_intact(door), "Level never bypasses magical protection")
