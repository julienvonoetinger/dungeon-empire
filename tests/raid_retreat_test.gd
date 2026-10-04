extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fixture(trap: int = GameTypes.Tile.SPIKE) -> RaidDirector:
	var raid := RaidDirector.new()
	raid.sim = DungeonSim.new()
	raid.sim.new_map()
	for x in range(1, 6):
		raid.sim.grid[1][x] = GameTypes.Tile.FLOOR
	raid.sim.grid[1][1] = GameTypes.Tile.ENTRANCE
	raid.sim.grid[1][3] = trap
	raid.sim.trap_charges[Vector2i(3, 1)] = raid.sim._trap_max_charges(trap)
	raid.sim.grid[1][5] = GameTypes.Tile.VAULT
	raid.sim.gold = 40
	raid.sim.vault_gold[Vector2i(5, 1)] = 40
	raid._start_raid()
	raid.hero.merge({"kind": "thief", "objective": "vault", "hp": 200, "max_hp": 200, "steal_capacity": 40, "flee_ratio": 0.0, "patience": 1000}, true)
	return raid

func _initialize() -> void:
	ProjectSettings.set_setting("testing/vulpin_only", true)
	for tile in [GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE]:
		var raid := fixture(tile)
		var id: int = raid.hero.id
		var returning := false
		var reached_exit := false
		var teleported := false
		var premature_rewards := false
		var steps_back := {}
		for frame in 3600:
			if raid.hero.is_empty():
				break
			teleported = teleported or bool(raid.hero.get("portaling", false))
			if raid.hero.fleeing:
				returning = true
				steps_back[raid.hero.pos] = true
				reached_exit = reached_exit or raid.hero.pos == Vector2i(1, 1)
			premature_rewards = premature_rewards or raid.raid_stats.escaped != 0 or raid.raid_stats.carried_out != 0 or raid.roster.profiles[id].xp != 0
			raid._update_hero(1.0 / 60.0)
		check(returning and reached_exit and steps_back.has(Vector2i(3, 1)), "stolen gold requires walking back over the corridor")
		check(not teleported and not premature_rewards, "no town portal or early escape/XP accounting")
		check(not raid.raid_active and raid.last_result.get("escaped", 0) == 1, "one actual escape")
		check(raid.sim.trap_charges[Vector2i(3, 1)] == 2 and raid.raid_stats.traps_spent == 1, "trap only fires once per raid")
		raid._start_raid()
		raid._trigger_trap(Vector2i(3, 1), tile)
		check(raid.sim.trap_charges[Vector2i(3, 1)] == 1, "remaining charge rearms next raid")
	var raid := fixture()
	var id: int = raid.hero.id
	raid.hero.pos = Vector2i(4, 1)
	raid.hero.hp = 10
	raid.hero.fleeing = true
	raid.hero.carried_gold = 77
	for x in range(1, 6):
		raid.hero.known[Vector2i(x, 1)] = raid.sim.grid[1][x]
	for frame in 600:
		if raid.hero.is_empty():
			break
		raid._update_hero(1.0 / 60.0)
	check(raid.last_result.get("killed", 0) == 1 and raid.last_result.get("escaped", 0) == 0, "fresh trap on return can kill")
	check(not raid.roster.profiles.has(id) and raid.last_result.get("carried_out", -1) == 0, "death gives no escape XP or carried-out gold")
	check(raid.sim.loot_bags.size() == 1 and raid.sim.loot_bags[0].gold == 77, "return death drops carried gold")
	raid = fixture(GameTypes.Tile.VOID)
	for frame in 600:
		if raid.hero.is_empty():
			break
		raid._update_hero(1.0 / 60.0)
	check(raid.last_result.get("escaped", 0) == 1 and raid.sim.trap_charges[Vector2i(3, 1)] == 0, "void retains magical expulsion")
	print("Retreat failures: ", failures)
	quit(1 if failures else 0)
