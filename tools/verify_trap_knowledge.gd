extends SceneTree
## Headless raid fixtures. Use the real session, but never load or write a player save.
const Session = preload("res://scripts/game/game_session.gd")
const Probes = preload("res://scripts/testing/game_probes.gd")
const Save = preload("res://scripts/game/gameplay_save.gd")
const ChestOrientation = preload("res://scripts/game/chest_orientation.gd")
const Tile = GameTypes.Tile
const ENTRY := Vector2i(3, 8)
const TRAP := Vector2i(4, 8)
const LANDING := Vector2i(5, 8)
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		print("FAIL: ", label)

func fixture() -> Node:
	var game = Session.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.restart(true)
	game.sim._place(TRAP, Tile.SPIKE, 0)
	return game

func start_visitor(game: Node, kind: String) -> void:
	seed(21)
	game.start_raid()
	game.raid.hero.kind = kind
	game.raid.hero.objective = {"thief":"vault", "mage":"core", "paladin":"core", "ranger":"explore"}[kind]

func finish_trip(game: Node) -> void:
	for tick in 600:
		if not game.raid.raid_active: break
		game.advance_simulation(.05)
	check(not game.raid.raid_active, "raid finished")

func run() -> void:
	for kind in ["paladin", "mage", "ranger", "thief"]:
		var game := fixture()
		start_visitor(game, kind)
		# Force a successful detection in this fixture for the sharing check.
		game.raid.hero.perception = 100
		game.raid._remember_nearby(game.raid.hero)
		var known: Dictionary = Probes.snapshot(game).hero.known
		check(known.get("4:8") == (Tile.SPIKE if kind == "thief" else Tile.FLOOR),
			kind + " reads the correct tile before stepping on it")
		check(game.sim.trap_charges[TRAP] == 3, "observation never spends a charge")
		if kind == "thief":
			check(not known.has("6:8"), "detection stays inside the Vulpin perception radius")
			game.raid.hero.fleeing = true
			finish_trip(game)
			check(game.raid.kingdom_knowledge.get(TRAP) == Tile.SPIKE and game.sim.trap_charges[TRAP] == 3,
				"a returning Vulpin reports an untriggered trap")
		elif kind == "paladin":
			game.raid.hero.fleeing = true
			finish_trip(game)
			check(game.raid.kingdom_knowledge.get(TRAP) == Tile.FLOOR,
				"walking out after only seeing the floor does not report a trap")
		game.free()
	test_report(true)
	test_report(false)
	var banished := fixture()
	banished.sim._place(TRAP, Tile.VOID, 0)
	start_visitor(banished, "mage")
	finish_trip(banished)
	check(banished.raid.last_result.escaped == 1 and banished.raid.kingdom_knowledge.get(TRAP) == Tile.VOID,
		"void banishment is a living departure and reports the triggered void")
	banished.free()
	test_landing()
	test_detection_probability()
	test_failed_detection()
	test_perception_save()
	test_force()
	test_agility()
	test_magic_doors()
	test_race_profiles()
	test_level_progression()
	test_chest_lure()
	print("Trap knowledge: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

# Cover every possible die face exactly once with deterministic raid seeds.
func seeds_for_die(sides: int) -> Array[int]:
	var dice := RandomNumberGenerator.new()
	var seeds: Array[int] = []
	seeds.resize(sides)
	var found := 0
	for candidate in range(1, 20000):
		dice.seed = candidate
		var index := dice.randi_range(1, sides) - 1
		if seeds[index] == 0:
			seeds[index] = candidate
			found += 1
			if found == sides: break
	check(found == sides, "all " + str(sides) + " die faces covered")
	return seeds

func count_detections(game, cell: Vector2i, seeds: Array[int]) -> int:
	var raid = game.raid
	var count := 0
	for seed_value in seeds:
		raid._raid_rng.seed = seed_value
		raid.hero.trap_detection_rolls.clear()
		raid.hero.known.erase(cell)
		raid._remember_nearby(raid.hero)
		if raid.hero.known[cell] == game.sim.grid[cell.y][cell.x]: count += 1
	return count

func test_chest_lure() -> void:
	const CHEST := Vector2i(10, 3)
	var ordinary := seeds_for_die(100)
	var distracted := seeds_for_die(200)
	var game := fixture()
	start_visitor(game, "thief")
	var sim = game.sim
	var raid = game.raid
	raid.hero.pos = CHEST
	raid.hero.perception = 65
	for i in ChestOrientation.DIRECTIONS.size():
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				sim.grid[CHEST.y + dy][CHEST.x + dx] = Tile.ROCK
		sim.grid[CHEST.y][CHEST.x] = Tile.VAULT
		for neighbor: Vector2i in ChestOrientation.DIRECTIONS:
			var at := CHEST + neighbor
			sim.grid[at.y][at.x] = Tile.FLOOR
		var direction: Vector2i = ChestOrientation.DIRECTIONS[i]
		var front := CHEST + direction
		var behind := CHEST - direction
		var approach := front + direction
		sim.grid[approach.y][approach.x] = Tile.FLOOR
		sim.grid[front.y][front.x] = [Tile.SPIKE, Tile.SNARE, Tile.VOID, Tile.SPIKE][i]
		check(ChestOrientation.select(sim, CHEST).facing == ChestOrientation.NAMES[i], "fixture matches the visible chest front")
		raid.hero.trait = "Greedy"
		check(count_detections(game, front, distracted) == 65, "greedy thief detects 65 of 200 at the " + ChestOrientation.NAMES[i] + " front")
		raid.hero.trait = "Cautious"
		check(count_detections(game, front, ordinary) == 65, "another thief retains 65 percent at the front")
		sim.grid[front.y][front.x] = Tile.FLOOR
		sim.grid[behind.y][behind.x] = Tile.SNARE
		raid.hero.trait = "Greedy"
		check(count_detections(game, behind, ordinary) == 65, "the rear tile retains the normal chance")
		sim.grid[behind.y][behind.x] = Tile.FLOOR
		if i == 0:
			for offset in [Vector2i.RIGHT, Vector2i(1, 1)]:
				var other: Vector2i = CHEST + offset
				var previous: int = sim.grid[other.y][other.x]
				sim.grid[other.y][other.x] = Tile.SNARE
				check(count_detections(game, other, ordinary) == 65, "side or diagonal is not in front")
				sim.grid[other.y][other.x] = previous
		sim.grid[approach.y][approach.x] = Tile.VOID
		check(count_detections(game, approach, ordinary) == 65, "two tiles ahead retains the normal chance")
	# Last layout faces west. A door opening to the south turns the chest away
	# from the trap. A first failure must remain a failure after that change.
	var trap := CHEST + Vector2i.LEFT
	sim.grid[trap.y][trap.x] = Tile.SPIKE
	sim.grid[trap.y][trap.x - 1] = Tile.FLOOR
	var door := CHEST + Vector2i.DOWN * 2
	sim.grid[door.y][door.x] = Tile.DOOR
	sim.door_hp[door] = 60
	raid.hero.perception = 100
	raid.hero.trap_detection_rolls.clear()
	raid.hero.known.erase(trap)
	raid._raid_rng.seed = distracted[199]
	raid._remember_nearby(raid.hero)
	check(raid.hero.known[trap] == Tile.FLOOR, "even 100 perception can miss a baited trap")
	sim.door_hp[door] = 0
	check(ChestOrientation.select(sim, CHEST).facing == "south", "opening the door changes the visible facing")
	raid._remember_nearby(raid.hero)
	check(raid.hero.known[trap] == Tile.FLOOR, "changing the chest facing does not give away a missed trap")
	# Two empty chests, one sealed, face the same trap across a narrow walkable lane.
	for dy in range(-2, 3):
		for dx in range(-3, 3):
			sim.grid[CHEST.y + dy][CHEST.x + dx] = Tile.ROCK
	sim.grid[CHEST.y][CHEST.x] = Tile.VAULT
	sim.grid[CHEST.y][CHEST.x - 2] = Tile.VAULT
	sim.vault_locks[CHEST] = 2
	sim.grid[trap.y][trap.x] = Tile.VOID
	sim.grid[trap.y + 1][trap.x] = Tile.FLOOR
	raid.hero.perception = 65
	check(count_detections(game, trap, distracted) == 65, "two facing chests still halve the chance only once")
	raid.hero.known[trap] = Tile.VOID
	raid.hero.trap_detection_rolls.clear()
	raid._remember_nearby(raid.hero)
	check(raid.hero.known[trap] == Tile.VOID and not raid.hero.trap_detection_rolls.has(trap), "reported traps bypass the lure")
	game.free()

func test_report(survives: bool) -> void:
	var game := fixture()
	start_visitor(game, "mage")
	game.raid.hero.morale = 1.0
	if not survives: game.raid.hero.hp = 1
	for tick in 200:
		game.advance_simulation(.05)
		if game.sim.trap_charges[TRAP] < 3: break
	check(game.sim.trap_charges[TRAP] == 2, "uninformed mage walks onto the spike")
	check(not game.raid.kingdom_knowledge.has(TRAP), "no report before completed departure")
	if survives:
		check(Probes.snapshot(game).hero.known.get("4:8") == Tile.SPIKE, "actual trigger reveals the tile")
	finish_trip(game)
	if not survives:
		check(game.raid.last_result.killed == 1 and not game.raid.kingdom_knowledge.has(TRAP),
			"a dead witness cannot warn the kingdom")
		game.free()
		return
	check(game.raid.last_result.escaped == 1 and game.raid.kingdom_knowledge.get(TRAP) == Tile.SPIKE,
		"the escaped witness reports the trap")
	game.continue_preparation()
	check(game.sim.repair_trap(TRAP) == 1 and game.raid.kingdom_knowledge.get(TRAP) == Tile.SPIKE,
		"rearming a reported trap preserves its location")
	var saved := Save.capture(game.sim, game.raid, game.progression)
	check(Save.apply(saved, game.sim, game.raid, game.progression), "save round-trip accepts the report")
	start_visitor(game, "ranger")
	game.raid._remember_nearby(game.raid.hero)
	check(game.raid.hero.known.get(TRAP) == Tile.SPIKE, "the next ranger retains the report after looking")
	game.raid.hero.fleeing = true
	finish_trip(game)
	game.continue_preparation()
	game.sim._place(TRAP, Tile.SNARE, 0)
	check(not game.raid.kingdom_knowledge.has(TRAP), "a new mechanism at the old position must be discovered again")
	game.free()

func test_detection_probability() -> void:
	var game := fixture()
	var counts := {40: 0, 70: 0}
	var ratings := {}
	var stable := true
	var monotonic := true
	var in_range := true
	var different_traps_disagree := false
	for trial in range(1, 65):
		var weaker_found := false
		for rating: int in [40, 70]:
			game.restart(true)
			game.sim._place(TRAP, Tile.SPIKE, 0)
			game.sim._place(LANDING, Tile.SNARE, 0)
			seed(trial)
			game.start_raid()
			var raid = game.raid
			var native_rating: int = raid.hero.get("perception", -1)
			ratings[native_rating] = true
			in_range = in_range and native_rating >= 40 and native_rating <= 70
			raid.hero.perception = rating
			raid._remember_nearby(raid.hero)
			var found: bool = raid.hero.known.get(TRAP) == Tile.SPIKE
			var second_found: bool = raid.hero.known.get(LANDING) == Tile.SNARE
			if second_found != found:
				different_traps_disagree = true
			counts[rating] += int(found)
			if rating == 40:
				weaker_found = found
			elif weaker_found and not found:
				monotonic = false
			raid.hero.pos = Vector2i(9, 8)
			raid._remember_nearby(raid.hero)
			raid.hero.pos = ENTRY
			for revisit in 8:
				raid._remember_nearby(raid.hero)
				stable = stable and (raid.hero.known.get(TRAP) == Tile.SPIKE) == found
	check(stable, "revisiting the same trap never rerolls detection during a raid")
	check(different_traps_disagree, "two traps in range are evaluated separately")
	check(in_range and ratings.size() > 1, "recruited Vulpins have different individual ratings in 40..70")
	check(monotonic and counts[40] > 0 and counts[70] > counts[40] and counts[70] < 64,
		"both outcomes occur and higher perception improves success for paired raid seeds")
	print("Detections over 64 raids at each rating: ", counts)
	game.free()

func test_failed_detection() -> void:
	var game := fixture()
	start_visitor(game, "thief")
	var raid = game.raid
	raid.hero.perception = 0
	raid._remember_nearby(raid.hero)
	raid.hero.fleeing = true
	finish_trip(game)
	check(raid.kingdom_knowledge.get(TRAP) == Tile.FLOOR, "a missed trap is not reported on departure")
	game.continue_preparation()
	start_visitor(game, "thief")
	raid.hero.perception = 0
	raid.hero.morale = 1.0
	finish_trip(game)
	check(game.sim.trap_charges[TRAP] == 2 and raid.kingdom_knowledge.get(TRAP) == Tile.SPIKE,
		"a missed trap is learned by triggering it and returning alive")
	game.continue_preparation()
	start_visitor(game, "thief")
	raid.hero.perception = 0
	raid._remember_nearby(raid.hero)
	check(raid.hero.known.get(TRAP) == Tile.SPIKE and not raid.hero.trap_detection_rolls.has(TRAP),
		"a reported trap stays known without a new roll")
	game.free()

func test_perception_save() -> void:
	var game := fixture()
	start_visitor(game, "thief")
	var id: int = game.raid.hero.id
	var original: int = game.raid.hero.get("perception", -1)
	var strength: int = game.raid.hero.get("strength", -1)
	var saved := Save.capture(game.sim, game.raid, game.progression)
	check(Save.apply(saved, game.sim, game.raid, game.progression), "current hero profiles reload")
	check(original >= 40 and game.raid.roster.profiles[id].stats.get("perception") == original,
		"returning hero retains its own perception")
	check(strength >= 0 and game.raid.roster.profiles[id].stats.get("strength") == strength,
		"returning hero retains its own strength")
	for endpoint in [0, 100]:
		saved.hero_roster.profiles[id].stats.strength = endpoint
		saved.hero_roster.profiles[id].stats.perception = endpoint
		saved.hero_roster.profiles[id].stats.agility = endpoint
		saved.hero_roster.profiles[id].stats.intelligence = endpoint
		check(Save.apply(saved, game.sim, game.raid, game.progression), "percentage endpoints are valid for all four stats")
	saved.hero_roster.profiles[id].stats.intelligence = 101
	check(not Save.apply(saved, game.sim, game.raid, game.progression), "out-of-range intelligence is rejected")
	saved.hero_roster.profiles[id].stats.erase("agility")
	saved.hero_roster.profiles[id].stats.erase("intelligence")
	check(Save.apply(saved, game.sim, game.raid, game.progression), "two-stat profiles still load")
	var migrated: Dictionary = game.raid.roster.profiles[id].stats
	check(migrated.get("strength") == 100 and migrated.get("perception") == 100 and migrated.has("agility") and migrated.has("intelligence"),
		"old personal ratings survive migration and new ratings are filled")
	saved.hero_roster.profiles[id].stats.erase("strength")
	saved.hero_roster.profiles[id].stats.erase("perception")
	check(Save.apply(saved, game.sim, game.raid, game.progression), "legacy profiles still load")
	check(game.raid.roster.profiles[id].stats.get("perception") == 55,
		"older Vulpins get a stable middle rating")
	saved.hero_roster.profiles[id].stats.trap_perception = 67
	check(Save.apply(saved, game.sim, game.raid, game.progression) and game.raid.roster.profiles[id].stats.get("perception") == 67,
		"existing individual trap aptitude migrates to perception")
	saved.hero_roster.profiles[id].stats.erase("trap_perception")
	saved.hero_roster.profiles[id].stats.strength = 30
	saved.hero_roster.profiles[id].stats.perception = 101
	check(not Save.apply(saved, game.sim, game.raid, game.progression), "invalid perception is rejected")
	game.free()

func test_force() -> void:
	for kind in ["mage", "paladin"]:
		for strength in [0, 100]:
			var game := fixture()
			start_visitor(game, kind)
			var raid = game.raid
			raid.hero.erase("entering")
			raid.hero.strength = strength
			raid.hero.door_damage = 35
			raid._attack_door(LANDING)
			if kind == "paladin":
				check(game.sim.door_hp[LANDING] == GameTypes.DOOR_MAX_HP, "hammer blow resolves only at impact")
				raid._update_hero(GameTypes.CORE_STRIKE_HOLD)
			if strength == 0:
				check(game.sim.door_hp[LANDING] == GameTypes.DOOR_MAX_HP and raid._route_door_blocked(raid.hero, LANDING),
					kind + " fails at 0 strength and seeks another route")
			else:
				check(game.sim.door_hp[LANDING] == GameTypes.DOOR_MAX_HP - 35,
					kind + " at 100 strength deals its usual damage")
				if kind == "paladin":
					raid._update_hero(GameTypes.CORE_STRIKE_HOLD)
				else:
					raid._attack_door(LANDING)
				check(not game.sim._door_intact(LANDING), "the capable visitor finishes breaking the door")
			game.free()

func test_race_profiles() -> void:
	var original_filter: bool = ProjectSettings.get_setting("testing/vulpin_only", false)
	ProjectSettings.set_setting("testing/vulpin_only", false)
	var game := fixture()
	var seen := {}
	for trial in range(1, 101):
		game.restart(true)
		seed(trial)
		game.start_raid()
		var visitor: Dictionary = game.raid.hero
		if seen.has(visitor.kind): continue
		seen[visitor.kind] = true
		check(visitor.strength in range(101) and visitor.perception in range(101), "valid stats on " + visitor.kind)
		var saved := Save.capture(game.sim, game.raid, game.progression)
		check(Save.apply(saved, game.sim, game.raid, game.progression), "full profile reloads for " + visitor.kind)
		var stats: Dictionary = game.raid.roster.profiles[visitor.id].stats
		check(stats.strength == visitor.strength and stats.perception == visitor.perception,
			"both attributes survive reload for " + visitor.kind)
		check(stats.has("agility") and stats.has("intelligence") and stats.agility == visitor.get("agility") and stats.intelligence == visitor.get("intelligence"),
			"agility and intelligence survive reload for " + visitor.kind)
		if seen.size() == 4: break
	check(seen.size() == 4, "all four playable profiles have both attributes")
	game.free()
	ProjectSettings.set_setting("testing/vulpin_only", original_filter)

func test_landing() -> void:
	var game := fixture()
	game.sim._place(LANDING, Tile.SNARE, 0)
	game.raid.kingdom_knowledge[TRAP] = Tile.SPIKE
	start_visitor(game, "ranger")
	var raid = game.raid
	raid.hero.agility = 100
	raid._remember_nearby(raid.hero)
	check(raid.hero.known.get(LANDING) == Tile.FLOOR, "a second, unreported trap looks like a safe landing")
	raid.hero.known[LANDING] = Tile.SNARE
	check(not raid._try_trap_jump(ENTRY, TRAP), "ranger refuses a landing with a known armed trap")
	raid.hero.known[LANDING] = Tile.FLOOR
	check(raid._try_trap_jump(ENTRY, TRAP), "ranger does not sense the hidden landing trap from a distance")
	for tick in 100:
		game.advance_simulation(.05)
		if game.sim.trap_charges[LANDING] < 3: break
	check(game.sim.trap_charges[TRAP] == 3 and game.sim.trap_charges[LANDING] == 2,
		"landing reveals the second trap and leaves the skipped trap armed")
	game.free()

func test_level_progression() -> void:
	var game := fixture()
	start_visitor(game, "thief")
	var roster = game.raid.roster
	var id: int = game.raid.hero.id
	var base := {"strength": 98, "perception": 65, "agility": 100, "intelligence": 0}
	roster.profiles[id].stats.merge(base, true)
	var report: Dictionary = roster.finish(id, true, {}) # 10 XP, still level 1.
	check(report.get("hero_aptitudes") == base, "XP below the next threshold gives no stat bonus")
	report = roster.finish(id, true, {"acquired_gold": 150}) # Exactly 50 XP.
	var level_two := {"strength": 99, "perception": 66, "agility": 100, "intelligence": 1}
	check(report.hero_level_after == 2 and report.get("hero_aptitudes") == level_two,
		"crossing one threshold adds one point to each aptitude, capped at 100")
	var locks := {}
	for x in 16:
		locks[Vector2i(x, 8)] = true
	report = roster.finish(id, true, {"locks": locks}) # 250 more XP crosses levels 3 and 4.
	var level_four := {"strength": 100, "perception": 68, "agility": 100, "intelligence": 3}
	check(report.hero_level_before == 2 and report.hero_level_after == 4 and report.get("hero_aptitudes") == level_four,
		"a two-level expedition awards both points and caps each stat individually")

	# A veteran loaded from a roster with recruitment values and XP must use its
	# level-four chances in the raid, even across repeated save/load cycles.
	var saved := Save.capture(game.sim, game.raid, game.progression)
	for cycle in 2:
		saved.hero_roster.previous_id = 0 # Allow this veteran to be selected for the fixture.
		var returned := false
		for trial in range(1, 33):
			if not Save.apply(saved, game.sim, game.raid, game.progression): break
			seed(trial)
			game.start_raid()
			if game.raid.hero.get("id") == id:
				returned = true
				break
		check(returned, "saved veteran returns through the raid director")
		if not returned: break
		var hero: Dictionary = game.raid.hero
		check(hero.level == 4 and hero.strength == 100 and hero.perception == 68 and hero.agility == 100 and hero.intelligence == 3,
			"returning level-four hero uses the earned values exactly once")
		saved = Save.capture(game.sim, game.raid, game.progression)
	game.free()

func test_agility() -> void:
	for score: int in [0, 64, 65, 100]:
		var game := fixture()
		game.sim._place(LANDING, Tile.FLOOR, 0)
		game.raid.kingdom_knowledge[TRAP] = Tile.SPIKE
		start_visitor(game, "ranger")
		var raid = game.raid
		raid.hero.erase("entering")
		raid.hero.agility = score
		if score in [64, 65]:
			raid.hero.get_or_add("trap_jump_rolls", {})[TRAP] = 65
		check(raid._try_trap_jump(ENTRY, TRAP), "eligible ranger begins a jump")
		raid._update_hero(.90)
		check(raid.hero.get("jumping_trap", false) and game.sim.trap_charges[TRAP] == 3, "no trap fires in midair")
		raid._update_hero(.11)
		var clears: bool = score >= 65
		check(raid.hero.pos == (LANDING if clears else TRAP), "jump lands on the expected cell at agility " + str(score))
		check(game.sim.trap_charges[TRAP] == (3 if clears else 2), "only a short jump spends a charge")
		game.free()

func test_magic_doors() -> void:
	for score: int in [0, 64, 65, 100]:
		var game := fixture()
		game.sim._place(LANDING, Tile.MAGIC_DOOR, 0)
		start_visitor(game, "mage")
		var raid = game.raid
		raid.hero.erase("entering")
		raid.hero.intelligence = score
		if score in [64, 65]:
			raid.hero.get_or_add("arcane_door_rolls", {})[LANDING] = 65
		raid._attack_door(LANDING)
		raid._update_hero(1.4)
		check(raid.hero.get("arcane_opening", false) and game.sim._door_intact(LANDING), "seal holds until the end of the ritual")
		raid._update_hero(.11)
		var opens: bool = score >= 65
		check(game.sim._door_intact(LANDING) != opens and game.sim.door_opened.get(LANDING, false) == opens,
			"intelligence determines the fate of the seal at " + str(score))
		if not opens:
			check(raid._route_door_blocked(raid.hero, LANDING), "failed seal is excluded from future routes")
			raid._attack_door(LANDING)
			check(not raid.hero.get("arcane_opening", false), "cannot restart a failed ritual at this door")
		game.free()
