extends SceneTree

const Sim = preload("res://scripts/game/dungeon_sim.gd")
const Raid = preload("res://scripts/game/raid_director.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fixture(kind: String, solid: bool = true, known: bool = true):
	var sim = Sim.new()
	sim.new_map()
	for y in range(4, 10):
		for x in range(4, 10):
			sim.grid[y][x] = GameTypes.Tile.FLOOR
	sim._place_core(Vector2i(6, 6))
	sim.grid[6][4] = GameTypes.Tile.ENTRANCE
	sim.grid[6][9] = GameTypes.Tile.VAULT
	sim.gold = 140
	var raid = Raid.new()
	raid.sim = sim
	raid.set("solid_core", solid)
	raid._start_raid()
	raid.hero.kind = kind
	raid.hero.objective = "vault" if kind == "thief" else ("explore" if kind == "ranger" else "core")
	raid.hero.hp = 200
	raid.hero.max_hp = 200
	raid.hero.patience = 200
	raid.hero.flee_ratio = 0.0
	raid.hero.steal_capacity = 100
	if known:
		for y in range(16):
			for x in range(16):
				raid.hero.known[Vector2i(x, y)] = sim.grid[y][x]
	return raid

func run_raid(raid, label: String) -> void:
	for tick in range(1500):
		if not raid.raid_active:
			break
		raid._update_hero(0.5)
		if not raid.hero.is_empty():
			var p: Vector2i = raid.hero.pos
			if raid.sim.grid[p.y][p.x] == GameTypes.Tile.CORE:
				check(false, label + " entered Core")
				break
	check(not raid.raid_active, label + " completes without stuck routing")

func _initialize() -> void:
	var probe = Raid.new()
	if probe.get("solid_core") == null:
		check(false, "RaidDirector exposes opt-in solid_core")
		quit(1)
		return
	check(probe.solid_core == false, "desktop default remains walkable")
	for kind in ["paladin", "mage", "ranger"]:
		var raid = fixture(kind)
		raid.hero.pos = Vector2i(5, 6)
		raid.hero.objective = "core"
		raid._update_hero(0.5)
		check(raid.hero.pos == Vector2i(5, 6), kind + " attacks from adjacent floor")
		check(raid.hero.facing == Vector2i.RIGHT, kind + " faces attacked Core cell")
		if kind == "paladin":
			check(raid.hero.get("core_striking", false) and raid.sim.core_hp == 100, "paladin retains delayed strike")
		run_raid(raid, kind)
		check(raid.sim.core_hp == (58 if kind == "paladin" else 76), kind + " existing damage applied once")
	for run_seed in [11, 22, 33]:
		for kind in ["paladin", "mage", "ranger", "thief"]:
			seed(run_seed)
			var raid = fixture(kind, true, false)
			run_raid(raid, "natural %s seed %d" % [kind, run_seed])
			if kind == "thief":
				check(raid.sim.core_hp == 100 and raid.sim.gold < 140, "thief routes around Core to loot without damage")
			elif kind != "ranger":
				check(raid.sim.core_hp < 100, "natural attacker finds adjacent attack position")
	for kind in ["ranger", "thief"]:
		var raid = fixture(kind)
		raid.hero.pos = Vector2i(4, 6)
		raid.sim.grid[6][5] = GameTypes.Tile.SPIKE
		raid.sim.trap_charges[Vector2i(5, 6)] = 3
		raid.hero.known[Vector2i(5, 6)] = GameTypes.Tile.SPIKE
		check(not raid._try_trap_jump(Vector2i(4, 6), Vector2i(5, 6)), kind + " cannot jump onto Core")
		check(raid.hero.pos == Vector2i(4, 6), "rejected jump preserves position")
	var thief = fixture("thief")
	thief.hero.pos = Vector2i(5, 6)
	var step: Vector2i = thief._route_step(thief.hero, {Vector2i(9, 6): true})
	check(step != Vector2i(6, 6) and step != Vector2i(5, 6), "vault route detours around solid Core")
	thief.hero.pos = Vector2i(8, 6)
	thief.hero.fleeing = true
	step = thief._choose_next_step(thief.hero)
	check(thief.sim.grid[step.y][step.x] != GameTypes.Tile.CORE, "fleeing route does not transit Core")
	for kind in ["thief", "paladin"]:
		var raid = fixture(kind)
		raid.hero.pos = Vector2i(6, 6)
		raid._update_hero(0.5)
		check(not raid.hero.is_empty() and raid.sim.grid[raid.hero.pos.y][raid.hero.pos.x] != GameTypes.Tile.CORE, "embedded " + kind + " recovered onto floor")
		run_raid(raid, "recovered " + kind)
		if kind == "thief":
			check(raid.sim.core_hp == 100, "recovered thief never attacks")
	var desktop = fixture("paladin", false)
	desktop.hero.pos = Vector2i(5, 6)
	desktop._update_hero(0.5)
	check(desktop.hero.pos == Vector2i(6, 6) and desktop.hero.get("core_striking", false), "desktop retains Core entry and strike")
	var sealed = fixture("paladin")
	sealed.hero.pos = Vector2i(6, 6)
	for y in range(5, 9):
		for x in range(5, 9):
			if sealed.sim.grid[y][x] != GameTypes.Tile.CORE:
				sealed.sim.grid[y][x] = GameTypes.Tile.ROCK
	sealed._update_hero(0.5)
	check(not sealed.raid_active and sealed.hero.is_empty() and sealed.sim.core_hp == 100, "sealed Core recovery ends raid without damage or clipping")
	sealed.reset_for_new_map()
	check(sealed.solid_core, "mode survives map reset")
	for kind in ["paladin", "mage", "ranger", "thief"]:
		seed(42)
		var raid = fixture(kind)
		load("res://scripts/mobile/mobile_starter.gd").populate(raid.sim, raid)
		raid._start_raid()
		raid.hero.kind = kind
		raid.hero.objective = "vault" if kind == "thief" else ("explore" if kind == "ranger" else "core")
		raid.hero.steal_capacity = 100
		run_raid(raid, "authored starter " + kind)
		if kind == "thief":
			check(raid.sim.core_hp == 100 and raid.sim.gold < 140, "starter thief loots without attacking Core")
		elif kind != "ranger":
			check(raid.sim.core_hp < 100, "starter attacker reaches Core perimeter")
		raid.sim.raid = null
	print("mobile_core_collision_test: %d failures" % failures)
	quit(1 if failures else 0)
