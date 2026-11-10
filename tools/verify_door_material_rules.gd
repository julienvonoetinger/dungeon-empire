extends SceneTree
## Construction, raid and save contracts for the material-specific doors.
const Session = preload("res://scripts/game/game_session.gd")
const Save = preload("res://scripts/game/gameplay_save.gd")
const Probes = preload("res://scripts/testing/game_probes.gd")
const GATE := Vector2i(5, 8)
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)

func run() -> void:
	var game := Session.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.restart(true)
	var tool: int = GameTypes.Tool.get("BUILD_REINFORCED_DOOR", -1)
	var tile: int = GameTypes.Tile.get("REINFORCED_DOOR", -1)
	check(tool >= 0 and tile >= 0, "Reinforced door is a distinct buildable structure")
	var types: Object = GameTypes
	check(types.has_method("door_material"), "Gameplay and HUD can resolve a door's shared material key")
	if types.has_method("door_material"):
		check(types.call("door_material", 7) == "wood" and types.call("door_material", 9) == "arcane" and types.call("door_material", tile) == "iron", "Existing and reinforced doors select their distinct materials")
	if tool >= 0 and tile >= 0:
		check_reinforced(game, tool, tile)
	game.free()
	print("%d door rule checks, %d failures." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)

func check_reinforced(game, tool: int, tile: int) -> void:
	var sim: DungeonSim = game.sim
	var raid: RaidDirector = game.raid
	var gold := sim.gold
	check(not game.check_action(GATE, tool).valid, "Core level one cannot build the reinforced door")
	game.progression.xp = 280
	check(not game.check_action(GATE, tool).valid, "The advanced model has no gameplay unlock yet")
	game.progression.testing_unlock_defenses = true
	check(game.check_action(GATE, tool).cost == 60, "Isolated material preview quotes 60 gold")
	game.choose_tool(tool)
	game.activate_cell(GATE)
	check(sim.gold == gold and sim.grid[GATE.y][GATE.x] == 7, "Replacing a legacy standard door requires confirmation")
	game.confirm_action()
	check(sim.grid[GATE.y][GATE.x] == tile and sim.gold == gold - 60, "Construction charges and places the reinforced door")
	check(sim.door_hp.get(GATE) == 120 and sim._door_intact(GATE), "A new reinforced door blocks at 120 HP")
	var probe: Dictionary = Probes.snapshot(game).get("door:5:8", {})
	check(probe.get("max_hp") == 120 and probe.get("hp") == 120 and probe.get("blocking") == true, "Observers report the reinforced resistance")
	check(Probes.violations(game).is_empty(), "The probe accepts full reinforced resistance")
	var save: Dictionary = Save.capture(sim, raid, game.progression)
	check(Save.apply(save, sim, raid, game.progression), "Full reinforced resistance survives save validation and restore")
	save.door_hp[GATE] = 121
	check(not Save.apply(save, sim, raid, game.progression), "Save validation rejects over-strength reinforced doors")
	save.grid[GATE.y][GATE.x] = 7
	save.door_hp[GATE] = 61
	check(not Save.apply(save, sim, raid, game.progression), "Legacy standard doors still reject 61 HP")
	for mechanical in [GameTypes.Tile.DOOR, GameTypes.Tile.REINFORCED_DOOR]:
		sim.grid[GATE.y][GATE.x] = mechanical
		sim.door_hp[GATE] = 40
		raid.hero = {"kind": "mage", "display": "Mycean", "strength": 100, "door_force_rolls": {}, "door_damage": 10}
		raid._attack_door(GATE)
		check(raid._route_door_blocked(raid.hero, GATE) and sim.door_hp[GATE] == 40, "Mycean avoids mechanical door %d without damage" % mechanical)
		check(not raid._try_force_door(GATE) and sim.door_hp[GATE] == 40, "A pending Mycean strike cannot damage door %d" % mechanical)
	sim.grid[GATE.y][GATE.x] = GameTypes.Tile.MAGIC_DOOR
	raid.hero = {"kind": "mage", "display": "Mycean", "intelligence": 100, "arcane_door_rolls": {}}
	raid._attack_door(GATE)
	check(raid.hero.get("arcane_open_pos") == GATE and sim._door_intact(GATE), "Mycean begins the ritual at a closed magic door")
	raid._resolve_mage_arcane_open(GATE)
	check(sim.door_opened.get(GATE) == true and not sim._door_intact(GATE), "Successful Mycean ritual opens the magic door")
	sim.grid[GATE.y][GATE.x] = tile
	sim.door_opened.erase(GATE)
	sim.door_hp[GATE] = 90
	check(sim._damaged_structure_count() == 1, "90 of 120 HP counts as damaged")
	var spent := sim.gold
	sim._repair_structures()
	check(sim.door_hp.get(GATE) == 120 and sim.gold == spent - 15, "Bulk repairs restore reinforced resistance to 120")
	raid.hero = {"kind": "thief", "display": "Vulpin", "lockpick_success_chance": 1.0}
	raid._attack_door(GATE)
	check(raid.hero.get("lockpick_pos") == GATE, "A thief can pick the reinforced mechanical lock")
	raid._resolve_vulpin_lockpick(GATE)
	check(not sim._door_intact(GATE) and sim.door_opened.get(GATE) == true, "Picking opens the passage without wrecking it")
	save = Save.capture(sim, raid, game.progression)
	check(Save.apply(save, sim, raid, game.progression) and sim.door_opened.get(GATE) == true, "Opened reinforced doors survive a save round-trip")
	spent = sim.gold
	check(sim.repair_door(GATE) and sim.door_hp.get(GATE) == 120 and sim.gold == spent - 15 and not sim.door_opened.has(GATE), "Single repair restores and relocks a picked door")
	raid.hero = {"kind": "paladin", "display": "Lithide", "strength": 100, "door_force_rolls": {}, "door_damage": 120, "known": {}, "ignored": {}}
	raid.raid_stats = {"doors_destroyed": 0}
	raid._attack_door(GATE)
	check(not raid.hero.get("door_striking", false) and raid._route_door_blocked(raid.hero, GATE), "Paladin seeks another route at an intact reinforced door")
	check(not raid._try_force_door(GATE) and sim.door_hp[GATE] == 120 and raid.raid_stats.doors_destroyed == 0, "A pending paladin strike cannot damage iron")
	for kind in ["paladin", "mage", "ranger"]:
		sim.door_hp[GATE] = 120
		sim.door_opened.erase(GATE)
		raid.hero = {"kind": kind, "display": kind, "lockpick_success_chance": 1.0}
		raid._start_vulpin_lockpick(GATE)
		check(not raid.hero.get("lockpicking", false), "%s cannot start picking iron" % kind)
		raid._resolve_vulpin_lockpick(GATE)
		check(sim._door_intact(GATE) and not sim.door_opened.has(GATE), "%s cannot complete a pending lockpick" % kind)
	raid.hero = {"kind": "thief", "display": "Vulpin", "lockpick_success_chance": 0.0}
	raid._attack_door(GATE)
	raid._resolve_vulpin_lockpick(GATE)
	check(sim.door_hp[GATE] == 120 and raid.hero.get("avoided_doors", {}).has(GATE), "A failed level-one pick leaves the iron door locked and sends the Vulpin elsewhere")
	var access := Vector2i(7, 8)
	sim.grid[access.y][access.x] = tile
	sim.door_hp[access] = 120
	sim.repair_core_access()
	check(sim.loot_bags.any(func(bag): return bag.pos == access and bag.gold == 60), "Core-access migration returns the material's build price")
