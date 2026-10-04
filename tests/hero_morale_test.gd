extends SceneTree

var failures := 0
const T := GameTypes.Tile
const P := Vector2i(3, 1)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fixture(trait_name: String = "Neutral") -> RaidDirector:
	var raid := RaidDirector.new()
	raid.sim = DungeonSim.new()
	raid.sim.new_map()
	for x in range(1, 7):
		raid.sim.grid[1][x] = T.FLOOR
	raid.sim.grid[1][1] = T.ENTRANCE
	raid._start_raid()
	raid.hero.merge({"kind": "thief", "trait": trait_name, "hp": 100, "max_hp": 100,
		"flee_ratio": 0.0, "level": 9, "objective": "vault", "steal_capacity": 100}, true)
	return raid

func _initialize() -> void:
	ProjectSettings.set_setting("testing/vulpin_only", true)
	var raid := fixture()
	check(raid.hero.get("morale", -1.0) == 100.0, "every raid starts with hidden morale 100")
	for row in [["Neutral", 30.0, 24.0, 10.0, 6.0, 10.0],
		["Greedy", 25.5, 20.4, 8.5, 5.1, 20.0],
		["Cautious", 36.0, 28.8, 12.0, 6.0, 10.0],
		["Stubborn", 21.0, 16.8, 7.0, 2.0, 10.0],
		["Cowardly", 45.0, 36.0, 15.0, 6.0, 10.0]]:
		raid = fixture(row[0])
		raid.sim.trap_charges[P] = 3
		raid._trigger_trap(P, T.SPIKE)
		check(is_equal_approx(float(raid.hero.get("morale", -1)), 100.0 - row[1]), "%s: actual spike damage morale" % row[0])
		raid._trigger_trap(P, T.SPIKE)
		check(is_equal_approx(float(raid.hero.get("morale", -1)), 100.0 - row[1]), "sprung trap cannot deduct morale twice")
		raid = fixture(row[0])
		raid.sim.trap_charges[P] = 3
		raid._trigger_trap(P, T.SNARE)
		check(is_equal_approx(float(raid.hero.get("morale", -1)), 100.0 - row[2]), "%s: snare damage and immobilization" % row[0])
		raid = fixture(row[0])
		raid.sim.corpses.append({"pos": P, "fear": 18.0})
		raid._remember_nearby(raid.hero)
		raid._remember_nearby(raid.hero)
		check(is_equal_approx(float(raid.hero.get("morale", -1)), 100.0 - row[3]), "%s: one loss per discovered corpse" % row[0])
		raid._mark_vulpin_lockpick_failure(P, true)
		check(is_equal_approx(float(raid.hero.get("morale", -1)), 100.0 - row[3] - row[4]), "%s: failed unlock loss" % row[0])
		raid = fixture(row[0])
		raid.hero.morale = 50.0
		raid.sim.grid[P.y][P.x] = T.VAULT
		raid.sim.vault_gold = {P: 20}
		raid.sim.gold = 20
		raid.hero.collect_gold = 20
		raid.hero.collect_vault = P
		raid._finish_vulpin_collect()
		check(is_equal_approx(float(raid.hero.morale), 50.0 + row[5]), "%s: actual theft gain" % row[0])
		raid._finish_vulpin_collect()
		check(is_equal_approx(float(raid.hero.morale), 50.0 + row[5]), "empty chest cannot award morale")
	raid = fixture()
	raid.hero.morale = 21.0
	raid._mark_vulpin_lockpick_failure(P, true)
	check(raid.hero.fleeing and not raid.hero.get("lockpicking", false), "broken morale stops unlock retries immediately")
	raid.hero.morale = 100.0
	raid._update_flee_state()
	check(raid.hero.fleeing, "flee is sticky even after morale recovers")
	raid = fixture()
	raid.hero.turns = 9999
	raid._update_flee_state()
	check(not raid.hero.fleeing, "legacy patience no longer ends exploration")
	raid.hero.hp = 10
	raid.hero.flee_ratio = 0.2
	raid._update_flee_state()
	check(raid.hero.fleeing, "low HP retreat remains independent")
	raid = fixture()
	raid.hero.morale = 50.0
	raid.sim.grid[P.y][P.x] = T.MAGIC_DOOR
	raid.sim.door_hp[P] = 120
	raid._resolve_mage_arcane_open(P)
	check(raid.hero.morale == 55.0, "successful magical opening restores five morale")
	raid._resolve_mage_arcane_open(P)
	check(raid.hero.morale == 55.0, "already open obstacle gives no morale")
	raid._apply_core_damage(10)
	check(raid.hero.morale == 65.0, "real Core damage restores ten morale")
	raid._apply_core_damage(0)
	check(raid.hero.morale == 65.0, "zero Core damage gives no morale")
	for row in [["Neutral", 3.0], ["Greedy", 2.55], ["Cautious", 4.5], ["Stubborn", 2.1], ["Cowardly", 3.0]]:
		raid = fixture(row[0])
		raid.hero.pos = P
		raid.hero.visited[P] = 2
		raid._remember_nearby(raid.hero)
		raid.hero.morale_progress = false
		for step in 9:
			raid._record_morale_move()
		check(raid.hero.morale == 100.0, "nine unproductive moves do not lose morale")
		raid._record_morale_move()
		check(is_equal_approx(float(raid.hero.morale), 100.0 - row[1]), "%s: tenth unproductive movement" % row[0])
		raid.hero.morale_moves = 9
		raid.hero.pos = Vector2i(6, 1)
		raid.hero.visited[raid.hero.pos] = 1
		raid._record_morale_move()
		check(raid.hero.morale_moves == 0 and is_equal_approx(float(raid.hero.morale), 100.0 - row[1]), "discovery on tenth movement resets stagnation without penalty")
		raid.hero.visited[raid.hero.pos] = 2
		raid._morale_progress()
		var before: float = raid.hero.morale
		for step in 10:
			raid._record_morale_move()
		check(is_equal_approx(float(raid.hero.morale), before - row[1]), "ten moves after a completed action lose morale, not eleven")
	raid = fixture()
	raid.hero.morale = 99.0
	raid._morale_event("unlock", 5.0)
	check(raid.hero.morale == 100.0, "positive morale is capped")
	raid._morale_event("corpse", -200.0)
	check(raid.hero.morale == 0.0 and raid.hero.fleeing, "morale cannot become negative")
	raid._start_raid()
	check(raid.hero.morale == 100.0 and raid.hero.morale_corpses.is_empty(), "fresh raid resets morale and corpse memories")
	for kind in ["thief", "paladin", "ranger", "mage"]:
		raid = fixture()
		raid.hero.kind = kind
		raid.hero.pos = Vector2i(5, 1)
		raid.hero.morale = 20.0
		for x in range(1, 7):
			raid.hero.known[Vector2i(x, 1)] = raid.sim.grid[1][x]
		var walked := {}
		for frame in 600:
			if raid.hero.is_empty():
				break
			walked[raid.hero.pos] = true
			check(not raid.hero.get("portaling", false), "morale retreat never teleports")
			raid._update_hero(1.0 / 60.0)
		check(walked.has(P) and walked.has(Vector2i(1, 1)), "%s: morale retreat crosses corridor and entrance" % kind)
		check(raid.last_result.get("escaped", 0) == 1, "%s: morale retreat commits a real departure" % kind)
	for breaks_morale in [false, true]:
		raid = fixture()
		raid.hero.pos = Vector2i(4, 1)
		raid.hero.level = 1
		raid.hero.morale = 21.0 if breaks_morale else 100.0
		raid.sim.grid[P.y][P.x] = T.DOOR
		raid.sim.door_hp[P] = 120
		for x in range(2, 5):
			raid.sim.grid[2][x] = T.FLOOR
			raid.hero.visited[Vector2i(x, 2)] = 2
		for y in range(1, 3):
			for x in range(1, 7):
				raid.hero.known[Vector2i(x, y)] = raid.sim.grid[y][x]
		raid._mark_vulpin_lockpick_failure(P, false)
		check(raid._route_step(raid.hero, {Vector2i(1, 1): true}) == Vector2i(4, 2), "route avoids an abandoned lock, including on morale retreat")
		if breaks_morale:
			var bypass := false
			for frame in 900:
				if raid.hero.is_empty():
					break
				bypass = bypass or raid.hero.pos == Vector2i(3, 2)
				check(not raid.hero.get("lockpicking", false), "morale retreat never retries abandoned doors")
				raid._update_hero(1.0 / 60.0)
			check(bypass and raid.last_result.get("escaped", 0) == 1, "morale retreat takes the walkable detour instead of stalling")
	print("Hero morale failures: ", failures)
	quit(1 if failures else 0)
