class_name RaidDirector
extends RefCounted

signal raid_finished(result: Dictionary)
var last_result: Dictionary = {}
var _completed_raid_id := -1

const Tile := GameTypes.Tile
const COLS := GameTypes.COLS
const ROWS := GameTypes.ROWS
const RAID_DELAY := GameTypes.RAID_DELAY
const CORE_MAX := GameTypes.CORE_MAX
const DOOR_MAX_HP := GameTypes.DOOR_MAX_HP
const TURN_TIME := GameTypes.TURN_TIME
const CORE_STRIKE_HOLD := GameTypes.CORE_STRIKE_HOLD
const VULPIN_COLLECT_HOLD := GameTypes.VULPIN_COLLECT_HOLD
const VULPIN_LOCKPICK_HOLD := 3.0333333
const VULPIN_DYING_HOLD := 1.5
const MAGE_ARCANE_OPEN_HOLD := 1.5
const TRAITS := GameTypes.TRAITS
const DIRS := GameTypes.DIRS
const ROUTE_STEP := GameTypes.ROUTE_STEP
const ROUTE_TRAP := GameTypes.ROUTE_TRAP
const ROUTE_DOOR := GameTypes.ROUTE_DOOR
const ROUTE_REVISIT := GameTypes.ROUTE_REVISIT
const ROUTE_REVISIT_MAX := GameTypes.ROUTE_REVISIT_MAX
const ROUTE_BIAS := GameTypes.ROUTE_BIAS

var sim: DungeonSim
var portal_hold := 1.15
var raid_timer := RAID_DELAY
var elapsed_seconds := 0.0
var raid_active := false
var raid_index := 0
var hero: Dictionary = {}
var raid_stats: Dictionary = {}
var kingdom_knowledge: Dictionary = {}
var mage_pressure := 0
var solid_core: bool = false
const Roster := preload("res://scripts/game/hero_roster.gd")
var roster := Roster.new()

func reset_for_new_map() -> void:
	roster.reset()
	last_result = {}
	_completed_raid_id = -1
	raid_timer = RAID_DELAY
	elapsed_seconds = 0.0
	raid_active = false
	raid_index = 0
	hero = {}
	raid_stats = {}
	kingdom_knowledge = {}
	mage_pressure = 0


func _start_raid() -> void:
	var entrance := sim._find_tile(Tile.ENTRANCE)
	if entrance.x < 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var profile: Dictionary = roster.select_return(mage_pressure, bool(ProjectSettings.get_setting("testing/vulpin_only", false)), rng)
	if profile.is_empty():
		profile = _new_hero_profile()
	if profile.kind == "mage":
		mage_pressure = 0
	roster.previous_id = int(profile.id)
	raid_index += 1
	hero = {
		"raid_id": raid_index,
		"id": profile.id,
		"name": Roster.display_name(profile),
		"class_name": profile.class_name,
		"level": Roster.level_for_xp(profile.xp),
		"trait": profile.trait,
		"display": "%s, %s (%s)" % [Roster.display_name(profile), profile.class_name, profile.trait],
		"kind": profile.kind,
		"pos": entrance,
		"hp": profile.stats.max_hp,
		"carried_gold": _starting_gold(profile.kind),
		"stolen_gold": 0,
		"xp_ledger": {"acquired_gold": 0, "locks": {}, "obstacles": {}, "core_damage": 0, "discoveries": {}},
		"move_cd": 0.0,
		"turns": 0,
		"known": kingdom_knowledge.duplicate(),
		"visited": {entrance: 1},
		"bias": {},
		"ignored": {},
		"fleeing": false,
		"morale": 100.0,
		"morale_cells": {},
		"morale_corpses": {},
		"morale_moves": 0,
		"morale_progress": false,
		"triggered_traps": {},
		"portaling": false,
		"void_absorbing": false,
		"portal_t": 0.0,
		"portal_msg": "",
		"facing": sim._entrance_mouth(entrance)
	}
	hero.merge(profile.stats.duplicate(true))
	raid_active = true
	elapsed_seconds = 0.0
	raid_timer = 0.0
	raid_stats = {
		"killed": 0,
		"escaped": 0,
		"stolen": 0,
		"carried_out": 0,
		"doors_destroyed": 0,
		"traps_spent": 0,
		"core_lost": 0
	}
	sim.report = ""
	sim.message = "RAID %d: %s enters the dungeon. All changes are locked." % [raid_index, hero["display"]]

func _starting_gold(kind: String) -> int:
	var limits: Array = {"thief": [80, 150], "paladin": [140, 240], "ranger": [95, 175], "mage": [110, 190]}[kind]
	return randi_range(limits[0], limits[1])

func _new_hero_profile() -> Dictionary:
	var template := _random_hero_template()
	var trait_name := _roll_trait()
	var mods: Dictionary = TRAITS[trait_name]
	var greed := maxf(0.15, _jitter(float(mods["greed"]), 0.15))
	return roster.recruit({
		"kind": template.kind, "trait": trait_name,
		"max_hp": maxi(20, int(template.hp) + randi_range(-6, 6)),
		"greed": greed,
		"steal_capacity": maxi(1, int(round(float(template.steal_capacity) * greed))),
		"fear_weight": _jitter(float(template.fear_weight) + float(mods.fear), 0.20),
		"trap_weight": maxf(0.05, _jitter(float(template.trap_weight) + float(mods.trap), 0.20)),
		"objective": template.objective,
		"door_damage": maxi(4, int(template.door_damage) + randi_range(-3, 3)),
		"flee_ratio": clampf(_jitter(float(template.flee_ratio) + float(mods.flee), 0.05), 0.05, 0.8),
		"patience": maxi(25, int(template.patience) + int(mods.patience) + randi_range(-10, 10))})


func _roll_trait() -> String:
	var names := TRAITS.keys()
	return String(names[randi() % names.size()])


func _jitter(base: float, spread: float) -> float:
	return base + randf_range(-spread, spread)


func _random_hero_template() -> Dictionary:
	var roll := randi() % (4 + maxi(0, mage_pressure))
	if bool(ProjectSettings.get_setting("testing/vulpin_only", false)):
		roll = 0
	if roll == 0:
		return {
			"name": "Vulpin Thief",
			"kind": "thief",
			"hp": 68,
			"loot": randi_range(80, 150),
			"steal_capacity": randi_range(90, 160),
			"fear_weight": 1.2,
			"trap_weight": 1.0,
			"objective": "vault",
			"door_damage": 18,
			"flee_ratio": 0.45,
			"patience": 90
		}
	elif roll == 1:
		return {
			"name": "Lithide Paladin",
			"kind": "paladin",
			"hp": 115,
			"loot": randi_range(140, 240),
			"steal_capacity": 0,
			"fear_weight": -0.25,
			"trap_weight": 0.55,
			"objective": "core",
			"door_damage": 34,
			"flee_ratio": 0.15,
			"patience": 140
		}
	elif roll == 2:
		return {
			"name": "Batrafian Ranger",
			"kind": "ranger",
			"hp": 82,
			"loot": randi_range(95, 175),
			"steal_capacity": 0,
			"fear_weight": 0.75,
			"trap_weight": 1.55,
			"objective": "explore",
			"door_damage": 20,
			"flee_ratio": 0.4,
			"patience": 70
		}
	mage_pressure = 0
	return {
		"name": "Sable Mage",
		"kind": "mage",
		"hp": 74,
		"loot": randi_range(110, 190),
		"steal_capacity": 0,
		"fear_weight": 0.45,
		"trap_weight": 0.85,
		"objective": "core",
		"door_damage": 8,
		"flee_ratio": 0.3,
		"patience": 110
	}


func _end_raid(result_text: String) -> void:
	if _completed_raid_id == raid_index:
		return
	_completed_raid_id = raid_index
	last_result = raid_stats.duplicate(true)
	var ledger: Dictionary = hero.get("xp_ledger", {}).duplicate(true)
	ledger["acquired_gold"] = mini(int(ledger.get("acquired_gold", 0)), int(hero.get("carried_gold", 0)))
	var killed := int(raid_stats.get("killed", 0)) > 0
	if killed or bool(hero.get("departed_alive", false)):
		last_result.merge(roster.finish(int(hero.get("id", 0)), not killed, ledger), true)
	last_result.merge({"raid_id": raid_index, "core_hp": sim.core_hp,
		"hero_kind": hero.get("kind", ""), "hero_name": hero.get("display", ""),
		"hero_class": hero.get("class_name", ""),
		"text": result_text, "loot_remaining": sim._unsecured_loot_total(),
		"structures_damaged": sim._damaged_structure_count()}, true)
	raid_active = false
	raid_timer = RAID_DELAY
	hero = {}
	sim.message = result_text
	if not sim.game_over:
		sim.message += "  Preparation: repairs and collection available."
	# Report fields follow GAME_DESIGN.md §3.
	sim.report = "Raid %d report — killed: %d | escaped: %d | gold stolen: %d | carried out: %d | loot remaining: %d | doors destroyed: %d | structures damaged: %d | Core: %d%%" % [
		raid_index,
		int(raid_stats.get("killed", 0)),
		int(raid_stats.get("escaped", 0)),
		int(raid_stats.get("stolen", 0)),
		int(raid_stats.get("carried_out", 0)),
		sim._unsecured_loot_total(),
		int(raid_stats.get("doors_destroyed", 0)),
		sim._damaged_structure_count(),
		sim.core_hp
	]
	raid_finished.emit(last_result.duplicate(true))


func _update_hero(delta: float) -> void:
	if hero.is_empty():
		return
	if raid_active:
		elapsed_seconds += delta
	if bool(hero.get("exiting", false)):
		hero["exit_t"] = maxf(0.0, float(hero["exit_t"]) - delta)
		if float(hero["exit_t"]) <= 0.00001:
			_finish_departure()
		return
	if hero.has("exit_arrival_t"):
		hero["exit_arrival_t"] = maxf(0.0, float(hero["exit_arrival_t"]) - delta)
		if float(hero["exit_arrival_t"]) <= 0.00001:
			hero.erase("exit_arrival_t")
			_hero_escapes()
		return
	if hero.has("trap_arrival_t") or hero.has("vault_arrival_t"):
		var timer := "trap_arrival_t" if hero.has("trap_arrival_t") else "vault_arrival_t"
		hero[timer] = maxf(0.0, float(hero[timer]) - delta)
		if float(hero[timer]) <= 0.00001:
			hero.erase(timer)
			# Transit does not pause; actual vault actions own their separate timers.
			var spike_arrival := timer == "trap_arrival_t" and int(sim.grid[hero.pos.y][hero.pos.x]) == Tile.SPIKE
			hero["move_cd"] = 0.0 if spike_arrival or timer == "vault_arrival_t" else 0.12
			_resolve_cell(hero["pos"])
		return
	if solid_core and not _recover_from_core():
		return
	if bool(hero.get("dying", false)):
		hero["dying_t"] = float(hero.get("dying_t", 0.0)) - delta
		if float(hero["dying_t"]) <= 0.0:
			hero.erase("dying")
			hero.erase("dying_t")
			_kill_hero()
		return

	if bool(hero.get("collecting_gold", false)):
		hero["collect_t"] = float(hero.get("collect_t", 0.0)) - delta
		if float(hero["collect_t"]) <= 0.0:
			_finish_vulpin_collect()
			var collect_result := String(hero.get("collect_result", "%s leaves the dungeon." % hero["display"]))
			hero.erase("collecting_gold")
			hero.erase("collect_t")
			hero.erase("collect_result")
			_begin_retreat(collect_result)
		return

	if bool(hero.get("door_striking", false)):
		hero["door_strike_t"] = float(hero.get("door_strike_t", 0.0)) - delta
		if float(hero["door_strike_t"]) <= 0.0:
			var door: Vector2i = hero.get("door_strike_pos", Vector2i(-1, -1))
			hero.erase("door_striking")
			hero.erase("door_strike_t")
			hero.erase("door_strike_pos")
			_apply_door_damage(door)
			if sim._door_intact(door):
				_attack_door(door)
		return

	if bool(hero.get("lockpicking", false)):
		hero["lockpick_t"] = float(hero.get("lockpick_t", 0.0)) - delta
		if float(hero["lockpick_t"]) <= 0.0:
			var lock_door: Vector2i = hero.get("lockpick_pos", Vector2i(-1, -1))
			hero.erase("lockpicking")
			hero.erase("lockpick_t")
			hero.erase("lockpick_pos")
			_resolve_vulpin_lockpick(lock_door)
		return

	if bool(hero.get("arcane_opening", false)):
		hero["arcane_open_t"] = float(hero.get("arcane_open_t", 0.0)) - delta
		if float(hero["arcane_open_t"]) <= 0.0:
			var magic_door: Vector2i = hero.get("arcane_open_pos", Vector2i(-1, -1))
			hero.erase("arcane_opening")
			hero.erase("arcane_open_t")
			hero.erase("arcane_open_pos")
			_resolve_mage_arcane_open(magic_door)
		return

	if bool(hero.get("jumping_trap", false)):
		hero["jump_t"] = float(hero.get("jump_t", 0.0)) - delta
		if float(hero["jump_t"]) <= 0.00001:
			hero.erase("jumping_trap")
			hero.erase("jump_t")
			hero.erase("jump_from")
			hero["move_cd"] = 0.0
			_resolve_cell(hero["pos"])
		return

	if bool(hero.get("core_striking", false)):
		hero["core_strike_t"] = float(hero.get("core_strike_t", 0.0)) - delta
		if float(hero["core_strike_t"]) <= 0.0:
			var result_text := _apply_core_damage(int(hero.get("core_strike_damage", 42)))
			hero.erase("core_striking")
			hero.erase("core_strike_damage")
			_begin_retreat(result_text)
		return

	if bool(hero.get("portaling", false)):
		hero["portal_t"] = float(hero.get("portal_t", 0.0)) - delta
		if float(hero["portal_t"]) <= 0.0:
			_finish_departure()
		return

	hero["move_cd"] = float(hero["move_cd"]) - delta
	if float(hero["move_cd"]) > 0.0:
		return
	hero["move_cd"] = TURN_TIME
	hero["turns"] = int(hero["turns"]) + 1

	_remember_nearby(hero)
	_update_flee_state()

	var pos: Vector2i = hero["pos"]
	if not bool(hero["fleeing"]) and int(sim.grid[pos.y][pos.x]) == Tile.VAULT and String(hero.get("kind", "")) == "thief":
		_try_rob_vault(pos)
		if bool(hero.get("lockpicking", false)) or bool(hero.get("collecting_gold", false)) or bool(hero.get("portaling", false)):
			return

	# A fleeing hero leaves the dungeon as soon as it reaches the entrance again.
	if bool(hero["fleeing"]) and int(sim.grid[pos.y][pos.x]) == Tile.ENTRANCE:
		_hero_escapes()
		return

	var next := _choose_next_step(hero)
	if next == pos:
		_begin_retreat("%s stops exploring and heads for the entrance." % hero["display"])
		next = _route_step(hero, _known_targets(hero, Tile.ENTRANCE))
		if next == pos:
			# A legal, immutable raid map always retains the route used to enter.
			# Corrupt/debug layouts are aborted, never counted as a magical escape.
			_end_raid("Raid interrupted: no known return path to the entrance.")
			return
	if solid_core and int(sim.grid[next.y][next.x]) == Tile.CORE:
		hero["facing"] = next - pos
		if _can_attack_core(hero):
			_hero_reaches_core()
		return

	# An intact door blocks: it has to be broken before passing through.
	if sim._door_intact(next):
		hero["facing"] = next - pos
		_attack_door(next)
		return
	# A jump may skip a straight route segment, never the junction where we turn.
	var planned_landing: Vector2i = hero.get("route_second_step", Vector2i(-1, -1))
	if planned_landing == next + (next - pos) and _try_trap_jump(pos, next):
		return

	hero["facing"] = next - pos
	hero["visited"][next] = int(hero["visited"].get(next, 0)) + 1
	hero["move_from"] = pos
	hero["pos"] = next
	_record_morale_move()
	if hero.get("trap_sprung_at", Vector2i(-1, -1)) != next:
		hero.erase("trap_sprung_at")
	if bool(hero["fleeing"]) and int(sim.grid[next.y][next.x]) == Tile.ENTRANCE:
		hero["exit_arrival_t"] = TURN_TIME
	elif sim._is_trap_tile(int(sim.grid[next.y][next.x])):
		hero["trap_arrival_t"] = TURN_TIME
	elif int(sim.grid[next.y][next.x]) == Tile.VAULT:
		hero["vault_arrival_t"] = TURN_TIME
	else:
		_resolve_cell(next)


func _try_trap_jump(from: Vector2i, trap: Vector2i) -> bool:
	if absi(trap.x - from.x) + absi(trap.y - from.y) != 1:
		return false
	if not sim._inside(from) or not sim._can_step(from, trap):
		return false
	var kind := String(hero.get("kind", ""))
	if kind != "ranger":
		return false
	if not hero.get("known", {}).has(trap) or not sim._is_trap_tile(int(hero["known"][trap])):
		return false
	if int(sim.trap_charges.get(trap, 0)) <= 0:
		return false
	if hero.get("triggered_traps", {}).has(trap):
		return false
	var landing := trap + (trap - from)
	if not sim._can_step(trap, landing) or sim._door_intact(landing):
		return false
	if solid_core and int(sim.grid[landing.y][landing.x]) == Tile.CORE:
		return false
	if sim._is_trap_tile(int(sim.grid[landing.y][landing.x])) and int(sim.trap_charges.get(landing, 0)) > 0 and not hero.get("triggered_traps", {}).has(landing):
		return false
	hero["facing"] = trap - from
	hero["visited"][landing] = int(hero["visited"].get(landing, 0)) + 1
	hero["pos"] = landing
	hero["jumping_trap"] = true
	hero["jump_from"] = from
	hero["jump_t"] = GameTypes.TRAP_JUMP_TIME
	_record_morale_move()
	return true


func _try_vulpin_trap_jump(from: Vector2i, trap: Vector2i) -> bool:
	return _try_trap_jump(from, trap)


func _can_attack_core(h: Dictionary) -> bool:
	return String(h.get("kind", "")) != "thief" and not bool(h.get("fleeing", false))


func _recover_from_core() -> bool:
	var start: Vector2i = hero["pos"]
	if int(sim.grid[start.y][start.x]) != Tile.CORE:
		return true
	# A mode change can leave a legacy hero inside the footprint. Search only
	# the connected Core cells for a free perimeter tile, never through walls.
	var pending: Array[Vector2i] = [start]
	var seen := {start: true}
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in DIRS:
			var next: Vector2i = cell + direction
			if seen.has(next) or not sim._can_step(cell, next):
				continue
			seen[next] = true
			if int(sim.grid[next.y][next.x]) == Tile.CORE:
				pending.append(next)
			elif not sim._door_intact(next):
				hero["pos"] = next
				hero["facing"] = cell - next
				hero["visited"][next] = int(hero["visited"].get(next, 0)) + 1
				return true
	_end_raid("%s cannot leave the sealed Core chamber." % hero["display"])
	return false


func _update_flee_state() -> void:
	if bool(hero["fleeing"]):
		return
	var ratio := float(hero["hp"]) / float(hero["max_hp"])
	if ratio <= float(hero["flee_ratio"]):
		hero["fleeing"] = true
		sim.message = "%s is badly wounded and looks for the exit." % hero["display"]
	elif float(hero.get("morale", 100.0)) <= 20.0:
		hero["fleeing"] = true
		sim.message = "%s loses heart and looks for the exit." % hero["display"]


func _morale_event(event: String, value: float) -> void:
	var trait_name := String(hero.get("trait", ""))
	if value < 0.0:
		if trait_name == "Greedy":
			value *= 0.85
		elif trait_name == "Stubborn":
			value = -2.0 if event == "unlock_failure" else value * 0.7
		elif event in ["damage", "snare", "corpse"]:
			if trait_name == "Cautious":
				value *= 1.2
			elif trait_name == "Cowardly":
				value *= 1.5
		elif event == "stagnation" and trait_name == "Cautious":
			value *= 1.5
	elif event == "theft" and trait_name == "Greedy":
		value = 20.0
	hero["morale"] = clampf(float(hero.get("morale", 100.0)) + value, 0.0, 100.0)
	if float(hero["morale"]) <= 20.0 and not bool(hero.get("fleeing", false)):
		hero["fleeing"] = true
		sim.message = "%s loses heart and looks for the exit." % hero.get("display", "Hero")


func _morale_progress() -> void:
	hero["morale_moves"] = 0
	hero["morale_progress"] = true


func _record_morale_move() -> void:
	hero["morale_progress"] = false
	_remember_morale_nearby(hero)
	if int(hero["visited"].get(hero["pos"], 0)) == 1:
		_morale_progress()
	if bool(hero.get("morale_progress", false)):
		hero["morale_progress"] = false
		return
	hero["morale_moves"] = int(hero.get("morale_moves", 0)) + 1
	if int(hero["morale_moves"]) >= 10:
		hero["morale_moves"] = 0
		_morale_event("stagnation", -3.0)

# Resolves arriving on a cell: loot, traps, then objective.


# Resolves arriving on a cell: loot, traps, then objective.
func _resolve_cell(pos: Vector2i) -> void:
	_pick_up_loot(pos)

	var tile: int = int(sim.grid[pos.y][pos.x])
	if sim._is_trap_tile(tile):
		_trigger_trap(pos, tile)

	if bool(hero.get("portaling", false)):
		return

	if int(hero["hp"]) <= 0:
		if String(hero.get("kind", "")) == "thief":
			hero["dying"] = true
			hero["dying_t"] = VULPIN_DYING_HOLD
			sim.message = "%s falls to the ground." % hero["display"]
			return
		_kill_hero()
		return

	if bool(hero["fleeing"]):
		return

	if tile == Tile.VAULT and String(hero["kind"]) == "thief":
		_try_rob_vault(pos)
		return
	if tile == Tile.VAULT and String(hero["kind"]) == "mage" and sim.vault_protected(pos) and int(sim.vault_locks.get(pos, 0)) == 2:
		if not bool(hero.get("arcane_opening", false)):
			hero["arcane_opening"] = true
			hero["arcane_open_t"] = MAGE_ARCANE_OPEN_HOLD
			hero["arcane_open_pos"] = pos
			sim.message = "%s begins dissipating a magic vault seal." % hero["display"]
		return

	if tile == Tile.CORE:
		if String(hero.get("kind", "")) == "thief":
			# A Vulpin may discover the Core while exploring, but it is a thief,
			# not a Core attacker. Keep exploring for treasure or head home.
			hero["known"][pos] = Tile.CORE
			return
		_hero_reaches_core()


func _pick_up_loot(pos: Vector2i) -> void:
	var taken := 0
	for bag in sim.loot_bags:
		if bag["pos"] == pos:
			taken += int(bag["gold"])
			bag["taken"] = true
	if taken <= 0:
		return
	hero["carried_gold"] = int(hero["carried_gold"]) + taken
	_record_xp_gold(taken)
	sim.loot_bags = sim.loot_bags.filter(func(b): return not bool(b.get("taken", false)))
	sim.message = "%s picks up %d gold of unsecured loot!" % [hero["display"], taken]


func _trigger_trap(p: Vector2i, tile: int) -> void:
	if hero.get("triggered_traps", {}).has(p):
		return
	var charges := int(sim.trap_charges.get(p, sim._trap_max_charges(tile)))
	if charges <= 0:
		return  # Spent defense: it stays inert until repaired.
	sim.trap_charges[p] = charges - 1
	if not hero.has("triggered_traps"):
		hero["triggered_traps"] = {}
	hero["triggered_traps"][p] = true
	raid_stats["traps_spent"] = int(raid_stats["traps_spent"]) + 1
	if tile == Tile.SPIKE:
		var damage := GameTypes.DAMAGE_SPIKE
		if String(hero["kind"]) == "paladin":
			damage = GameTypes.DAMAGE_SPIKE_PALADIN   # Lithides resist physical hazards (GAME_DESIGN.md §8).
		var lost := mini(maxi(0, int(hero["hp"])), damage)
		hero["hp"] = int(hero["hp"]) - damage
		_morale_event("damage", -100.0 * lost / float(hero["max_hp"]))
		hero["trap_sprung_at"] = p
	elif tile == Tile.VOID:
		hero["trap_sprung_at"] = p
		_banish_via_void()
	else:
		var lost := mini(maxi(0, int(hero["hp"])), GameTypes.DAMAGE_SNARE)
		hero["hp"] = int(hero["hp"]) - GameTypes.DAMAGE_SNARE
		_morale_event("damage", -100.0 * lost / float(hero["max_hp"]))
		_morale_event("snare", -8.0)
		hero["move_cd"] = GameTypes.SNARE_HOLD_TIME
		hero["trap_sprung_at"] = p


func _banish_via_void() -> void:
	var carried := int(hero["carried_gold"])
	hero["void_absorbing"] = true
	hero["portaling"] = true
	hero["portal_t"] = portal_hold
	hero["portal_msg"] = "%s is swallowed by a void rift with %d gold." % [hero["display"], carried]
	sim.message = "%s is pulled into the void." % hero["display"]


func _attack_door(p: Vector2i) -> void:
	if int(sim.door_hp.get(p, DOOR_MAX_HP)) <= 0:
		return
	if int(sim.grid[p.y][p.x]) == Tile.MAGIC_DOOR:
		_attack_magic_door(p)
		return
	if String(hero.get("kind", "")) == "paladin":
		if bool(hero.get("door_striking", false)):
			return
		if _known_targets(hero, Tile.CORE).is_empty():
			var unknown_attempts: Dictionary = hero.get("unknown_door_attempts", {})
			var count := int(unknown_attempts.get(p, 0))
			if count >= 2:
				return
			unknown_attempts[p] = count + 1
			hero["unknown_door_attempts"] = unknown_attempts
		hero["door_striking"] = true
		hero["door_strike_t"] = CORE_STRIKE_HOLD
		hero["door_strike_pos"] = p
		sim.message = "%s raises its hammer against a door." % hero["display"]
		return
	if String(hero.get("kind", "")) == "thief":
		_start_vulpin_lockpick(p)
		return
	_apply_door_damage(p)

func _vulpin_lockpick_limit() -> int:
	var level := maxi(1, int(hero.get("level", 1)))
	return 1 + (level - 1) / 2

func _vulpin_lockpick_chance() -> float:
	var level := maxi(1, int(hero.get("level", 1)))
	var chance := minf(0.75, 0.50 + 0.05 * (level / 2))
	return clampf(float(hero.get("lockpick_success_chance", chance)), 0.0, 1.0)

func _start_vulpin_lockpick(p: Vector2i) -> void:
	if bool(hero.get("lockpicking", false)) or int(hero.get("lockpick_attempts", {}).get(p, 0)) >= _vulpin_lockpick_limit():
		return
	hero["lockpicking"] = true
	hero["lockpick_t"] = VULPIN_LOCKPICK_HOLD
	hero["lockpick_pos"] = p
	sim.message = "%s starts picking a lock." % hero["display"]


func _attack_magic_door(p: Vector2i) -> void:
	if String(hero.get("kind", "")) == "mage":
		if bool(hero.get("arcane_opening", false)):
			return
		hero["arcane_opening"] = true
		hero["arcane_open_t"] = MAGE_ARCANE_OPEN_HOLD
		hero["arcane_open_pos"] = p
		sim.message = "%s begins an arcane opening ritual." % hero["display"]
		return
	var avoided: Dictionary = hero.get("avoided_doors", {})
	avoided[p] = true
	hero["avoided_doors"] = avoided
	hero["saw_magic_door_blocker"] = true
	sim.message = "%s cannot open the arcane door." % hero["display"]


func _resolve_mage_arcane_open(p: Vector2i) -> void:
	if sim._inside(p) and int(sim.grid[p.y][p.x]) == Tile.VAULT:
		if sim.vault_protected(p) and int(sim.vault_locks.get(p, 0)) == 2:
			sim.vault_opened[p] = true
			mage_pressure = 0
			_record_xp_obstacle(p, "obstacles")
			_morale_event("unlock", 5.0)
			sim.message = "%s dissipates the magic vault seal." % hero["display"]
		return
	if p.x < 0 or not sim._door_intact(p) or int(sim.grid[p.y][p.x]) != Tile.MAGIC_DOOR:
		return
	sim.door_hp[p] = 0
	sim.door_opened[p] = true
	mage_pressure = 0
	_record_xp_obstacle(p, "obstacles")
	_morale_event("unlock", 5.0)
	sim.message = "%s unseals the arcane door." % hero["display"]


func _resolve_vulpin_lockpick(p: Vector2i) -> void:
	if sim._inside(p) and int(sim.grid[p.y][p.x]) == Tile.VAULT:
		if not sim.vault_protected(p) or int(sim.vault_locks.get(p, 0)) != 1:
			return
		if randf() < _vulpin_lockpick_chance():
			sim.vault_opened[p] = true
			_record_xp_obstacle(p, "locks")
			_morale_event("unlock", 5.0)
			sim.message = "%s picks the vault lock and leaves its contents untouched." % hero["display"]
			return
		_mark_vulpin_lockpick_failure(p, true)
		return
	if not sim._door_intact(p):
		return
	if randf() < _vulpin_lockpick_chance():
		sim.door_hp[p] = 0
		sim.door_opened[p] = true
		_record_xp_obstacle(p, "locks")
		_morale_event("unlock", 5.0)
		sim.message = "%s picks the lock and slips through the door." % hero["display"]
		return
	_mark_vulpin_lockpick_failure(p, false)

func _mark_vulpin_lockpick_failure(p: Vector2i, vault: bool) -> void:
	var attempts: Dictionary = hero.get("lockpick_attempts", {})
	var count := int(attempts.get(p, 0)) + 1
	attempts[p] = count
	hero["lockpick_attempts"] = attempts
	_morale_event("unlock_failure", -6.0)
	if bool(hero.get("fleeing", false)):
		return
	if count < _vulpin_lockpick_limit():
		sim.message = "%s fails to pick the lock and tries again." % hero["display"]
		if vault:
			_start_vulpin_lockpick(p)
		else:
			_attack_door(p)
		return
	if vault:
		hero["ignored"][p] = true
		sim.message = "%s abandons the stubborn vault lock and seeks another route." % hero["display"]
		return
	var avoided: Dictionary = hero.get("avoided_doors", {})
	avoided[p] = true
	hero["avoided_doors"] = avoided
	sim.message = "%s abandons the stubborn lock and looks for another route." % hero["display"]


func _apply_door_damage(p: Vector2i) -> void:
	if p.x < 0 or int(sim.door_hp.get(p, DOOR_MAX_HP)) <= 0:
		return
	var hp := int(sim.door_hp.get(p, DOOR_MAX_HP)) - int(hero.get("door_damage", 18))
	_morale_progress()
	hero["move_cd"] = float(hero.get("move_cd", 0.0)) + 0.35
	if hp <= 0:
		sim.door_hp[p] = 0
		_record_xp_obstacle(p, "obstacles")
		raid_stats["doors_destroyed"] = int(raid_stats["doors_destroyed"]) + 1
		sim.message = "%s forces a door. The wreck stays after the raid." % hero["display"]
	else:
		sim.door_hp[p] = hp
		sim.message = "%s strikes a door (%d HP left)." % [hero["display"], hp]

# A thief takes only what fits in its bag, then returns to the entrance.
func _try_rob_vault(p: Vector2i) -> void:
	if bool(hero.get("fleeing", false)):
		return
	if bool(hero.get("ignored", {}).get(p, false)):
		return
	if sim.vault_protected(p):
		var tier := int(sim.vault_locks.get(p, 0))
		if tier == 2:
			hero["ignored"][p] = true
			# Abandoning a magic vault seal contributes the same mage pressure as a magic door.
			hero["saw_magic_door_blocker"] = true
			sim.message = "%s cannot open the magic vault seal and moves on." % hero["display"]
		elif tier == 1:
			if int(hero.get("lockpick_attempts", {}).get(p, 0)) >= _vulpin_lockpick_limit():
				hero["ignored"][p] = true
			else:
				_start_vulpin_lockpick(p)
		return
	var storage := sim._storage_state()
	var vaults: Dictionary = storage["vaults"]
	var available := int(vaults.get(p, 0))
	if available <= 0:
		hero["ignored"][p] = true
		sim.message = "%s finds nothing but an empty storage." % hero["display"]
		return
	var remaining_capacity := maxi(0, int(hero["steal_capacity"]) - int(hero.get("stolen_gold", 0)))
	if remaining_capacity <= 0:
		_begin_retreat("%s heads for the entrance with a full bag." % hero["display"])
		return
	var amount := mini(available, remaining_capacity)
	if amount == remaining_capacity or amount == sim.gold:
		_start_vulpin_exit(amount, p)
		return
	var left := available - amount
	amount = sim.withdraw_vault_gold(p, amount)
	_record_xp_gold(amount)
	if amount > 0:
		_morale_event("theft", 10.0)
	hero["carried_gold"] = int(hero.get("carried_gold", 0)) + amount
	hero["stolen_gold"] = int(hero.get("stolen_gold", 0)) + amount
	raid_stats["stolen"] = int(raid_stats["stolen"]) + amount
	if left <= 0:
		hero["ignored"][p] = true
	sim.message = "%s pockets %d gold and looks for another vault." % [hero["display"], amount]


func _start_vulpin_exit(pending_gold: int = 0, vault: Vector2i = Vector2i(-1, -1)) -> void:
	if bool(hero.get("collecting_gold", false)) or pending_gold <= 0 or int(sim._storage_state().vaults.get(vault, 0)) <= 0:
		return
	hero["collecting_gold"] = true
	hero["collect_t"] = VULPIN_COLLECT_HOLD
	hero["collect_gold"] = pending_gold
	hero["collect_vault"] = vault
	hero["collect_result"] = "%s fills its bag and heads for the entrance." % hero["display"]
	sim.message = "%s gathers the last useful gold before leaving." % hero["display"]


func _finish_vulpin_collect() -> void:
	var amount := int(hero.get("collect_gold", 0))
	var vault: Vector2i = hero.get("collect_vault", Vector2i(-1, -1))
	if amount > 0:
		amount = sim.withdraw_vault_gold(vault, amount)
		_record_xp_gold(amount)
		if amount > 0:
			_morale_event("theft", 10.0)
		hero["carried_gold"] = int(hero.get("carried_gold", 0)) + amount
		hero["stolen_gold"] = int(hero.get("stolen_gold", 0)) + amount
		raid_stats["stolen"] = int(raid_stats["stolen"]) + amount
		if vault.x >= 0:
			hero["ignored"][vault] = true


func _hero_reaches_core() -> void:
	var damage := 24
	if String(hero["kind"]) == "paladin":
		damage = 42

	if String(hero["kind"]) == "paladin":
		hero["core_striking"] = true
		hero["core_strike_t"] = CORE_STRIKE_HOLD
		hero["core_strike_damage"] = damage
		sim.message = "%s raises its hammer against the Core." % hero["display"]
		return

	_begin_retreat(_apply_core_damage(damage))


func _apply_core_damage(damage: int) -> String:
	var lost := mini(sim.core_hp, damage)
	if lost > 0:
		_morale_progress()
		_morale_event("core", 10.0)
	if hero.has("xp_ledger"):
		hero.xp_ledger.core_damage += lost
	sim.core_hp = maxi(0, sim.core_hp - damage)
	raid_stats["core_lost"] = int(raid_stats["core_lost"]) + lost
	var result_text := "%s strikes the Core (-%d integrity) and heads for the entrance." % [hero["display"], damage]
	if sim.core_hp <= 0:
		sim.game_over = true
		result_text = "DEFEAT — %s destroys the Core. Click Reset to start a new campaign." % hero["display"]
	return result_text


func _kill_hero() -> void:
	var death_pos: Vector2i = hero["pos"]
	sim.corpses.append({
		"pos": death_pos,
		"name": hero["name"],
		"fear": 18.0
	})
	var carried := int(hero["carried_gold"])
	if carried > 0:
		sim.loot_bags.append({
			"pos": death_pos,
			"gold": carried,
			"taken": false
		})

	# Essence absorbed by the Core (GAME_DESIGN.md §4: weak ~2, experienced ~3, champion ~5).
	var heal := 2
	if String(hero["kind"]) == "ranger":
		heal = 3
	elif String(hero["kind"]) == "paladin":
		heal = 5
	sim.core_hp = mini(CORE_MAX, sim.core_hp + heal)
	raid_stats["killed"] = int(raid_stats["killed"]) + 1
	_end_raid("%s dies. The Core absorbs its essence (+%d); body and loot stay where they fell." % [hero["display"], heal])

# --- AI: partial knowledge and decision ------------------------------------


# --- AI: partial knowledge and decision ------------------------------------

func _remember_nearby(h: Dictionary) -> void:
	_remember_morale_nearby(h)
	var radius := 3 if String(h["kind"]) == "ranger" else 2
	var p: Vector2i = h["pos"]
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var q := Vector2i(p.x + dx, p.y + dy)
			if sim._inside(q):
				var profile: Dictionary = roster.profiles.get(int(h.get("id", 0)), {})
				if h.has("xp_ledger") and not profile.get("discovered", {}).has(q):
					h.xp_ledger.discoveries[q] = true
				# Rolled once per cell: two heroes never price a route alike.
				if not h["known"].has(q):
					h["bias"][q] = randf_range(0.0, ROUTE_BIAS)
				h["known"][q] = sim.grid[q.y][q.x]


func _remember_morale_nearby(h: Dictionary) -> void:
	var radius := 3 if String(h["kind"]) == "ranger" else 2
	var p: Vector2i = h["pos"]
	if not h.has("morale_cells"):
		h["morale_cells"] = {}
	if not h.has("morale_corpses"):
		h["morale_corpses"] = {}
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var q := p + Vector2i(dx, dy)
			if sim._inside(q) and not h.morale_cells.has(q):
				h.morale_cells[q] = true
				_morale_progress()
	# Corpses remain in a fixed array during a raid, so stacked bodies are distinct.
	for i in sim.corpses.size():
		var corpse_pos: Vector2i = sim.corpses[i]["pos"]
		if absi(corpse_pos.x - p.x) <= radius and absi(corpse_pos.y - p.y) <= radius and not h.morale_corpses.has(i):
			h.morale_corpses[i] = true
			_morale_event("corpse", -10.0)


func _target_tile(h: Dictionary) -> int:
	if bool(h["fleeing"]):
		return Tile.ENTRANCE
	var objective := String(h["objective"])
	if objective == "vault":
		return Tile.VAULT
	if objective == "core":
		return Tile.CORE
	return -1  # The ranger maps the place without a fixed target.

# The hero reasons on routes, never on a single step: a trap or a corpse makes
# a corridor expensive, it never makes it impassable. Judging one neighbour at
# a time made a hero retreat into the entrance forever in front of a trapped
# corridor, because backing off always looked cheaper than the only way on.
# GAME_DESIGN.md §10: "high-level AI decides what it wants, pathfinding decides
# how to reach what it currently knows".


# The hero reasons on routes, never on a single step: a trap or a corpse makes
# a corridor expensive, it never makes it impassable. Judging one neighbour at
# a time made a hero retreat into the entrance forever in front of a trapped
# corridor, because backing off always looked cheaper than the only way on.
# GAME_DESIGN.md §10: "high-level AI decides what it wants, pathfinding decides
# how to reach what it currently knows".
func _choose_next_step(h: Dictionary) -> Vector2i:
	h.erase("route_second_step")
	var start: Vector2i = h["pos"]
	if bool(h.get("fleeing", false)):
		return _route_step(h, _known_targets(h, Tile.ENTRANCE))
	var candidates: Array[Vector2i] = []
	for d in DIRS:
		var q := start + d
		if sim._can_step(start, q):
			if solid_core and int(sim.grid[q.y][q.x]) == Tile.CORE and not _can_attack_core(h):
				continue
			if _route_door_blocked(h, q):
				continue
			candidates.append(q)
	if candidates.is_empty():
		return start

	# 1. Objective already spotted: head there using the mental map only.
	var target_tile := _target_tile(h)
	if target_tile >= 0:
		var known_goals := _known_targets(h, target_tile)
		var step := _route_step(h, known_goals)
		if step != start:
			return step
		if String(h["kind"]) == "thief" and target_tile == Tile.VAULT and known_goals.is_empty():
			# With no treasure and no unexplored frontier left, the thief has no
			# reason to remain in the dungeon.
			if _frontier_cells(h).is_empty():
				h["fleeing"] = true
				return _route_step(h, _known_targets(h, Tile.ENTRANCE))

	# 2. Nothing spotted: walk towards the closest edge of the known world.
	var explore := _route_step(h, _frontier_cells(h))
	if explore != start:
		return explore

	# 3. Everything reachable is mapped: go back over the least trodden ground.
	var revisit := _route_step(h, _least_visited_cells(h))
	if revisit != start:
		return revisit

	# 4. Nowhere left to route: decide on the spot.
	return _local_step(h, candidates)

# Cells of the wanted kind the hero remembers, minus those it wrote off.


# Cells of the wanted kind the hero remembers, minus those it wrote off.
func _known_targets(h: Dictionary, target_tile: int) -> Dictionary:
	var goals := {}
	for k in h["known"].keys():
		var p: Vector2i = k
		if int(h["known"][p]) == target_tile and not h["ignored"].has(p):
			goals[p] = true
	return goals

# Known passages touching something still unseen: the edge of the mental map.


# Known passages touching something still unseen: the edge of the mental map.
func _frontier_cells(h: Dictionary) -> Dictionary:
	var goals := {}
	for k in h["known"].keys():
		var p: Vector2i = k
		if int(h["known"][p]) == Tile.ROCK:
			continue
		if solid_core and int(h["known"][p]) == Tile.CORE:
			continue
		for d in DIRS:
			var n := p + d
			if sim._inside(n) and not h["known"].has(n):
				goals[p] = true
				break
	return goals


func _least_visited_cells(h: Dictionary) -> Dictionary:
	var start: Vector2i = h["pos"]
	var lowest := 1 << 30
	var goals := {}
	for k in h["known"].keys():
		var p: Vector2i = k
		if int(h["known"][p]) == Tile.ROCK or p == start:
			continue
		if solid_core and int(h["known"][p]) == Tile.CORE and not _can_attack_core(h):
			continue
		var seen_count := int(h["visited"].get(p, 0))
		if seen_count < lowest:
			lowest = seen_count
			goals.clear()
		if seen_count == lowest:
			goals[p] = true
	return goals

# Price the hero puts on entering a cell, based on what it believes is there.
# Never zero or negative: a route always costs something to walk.


# Price the hero puts on entering a cell, based on what it believes is there.
# Never zero or negative: a route always costs something to walk.
func _step_cost(h: Dictionary, p: Vector2i) -> float:
	var cost := ROUTE_STEP
	cost += minf(float(int(h["visited"].get(p, 0))) * ROUTE_REVISIT, ROUTE_REVISIT_MAX)
	var seen := int(h["known"].get(p, Tile.ROCK))
	if sim._is_trap_tile(seen) and not h.get("triggered_traps", {}).has(p):
		cost += ROUTE_TRAP * float(h["trap_weight"])
	elif seen == Tile.DOOR or seen == Tile.MAGIC_DOOR:
		cost += ROUTE_DOOR
	# A Paladin has a negative fear weight: sim.corpses draw it in instead.
	cost += _corpse_danger_near(p) * float(h["fear_weight"])
	cost += float(h["bias"].get(p, 0.0))
	return maxf(0.05, cost)

# Cheapest route to any of the goals, over the mental map alone (never the real
# grid). Returns the first step, or the current cell when nothing is reachable.


# Cheapest route to any of the goals, over the mental map alone (never the real
# grid). Returns the first step, or the current cell when nothing is reachable.
func _route_door_blocked(h: Dictionary, cell: Vector2i) -> bool:
	if not sim._door_intact(cell):
		return false
	if bool(h.get("fleeing", false)) or String(h.get("kind", "")) == "ranger":
		return true
	if bool(h.get("avoided_doors", {}).get(cell, false)):
		return true
	return String(h.get("kind", "")) == "paladin" and int(h.get("unknown_door_attempts", {}).get(cell, 0)) >= 2 and _known_targets(h, Tile.CORE).is_empty()


func _route_step(h: Dictionary, goals: Dictionary) -> Vector2i:
	h.erase("route_second_step")
	var start: Vector2i = h["pos"]
	if goals.is_empty():
		return start

	var dist := {start: 0.0}
	var came := {}
	var closed := {}
	var open: Array[Vector2i] = [start]
	var reached := Vector2i(-1, -1)

	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if float(dist[open[i]]) < float(dist[open[best_i]]):
				best_i = i
		var cur: Vector2i = open[best_i]
		open.remove_at(best_i)
		if closed.has(cur):
			continue
		closed[cur] = true
		if cur != start and goals.has(cur):
			reached = cur
			break
		for d in DIRS:
			var n := cur + d
			if closed.has(n) or not h["known"].has(n):
				continue
			if int(h["known"][n]) == Tile.ROCK:
				continue
			if not sim._can_step(cur, n):
				continue
			if _route_door_blocked(h, n):
				continue
			# Core goals terminate an attack route; no route may pass through it.
			if solid_core and int(sim.grid[n.y][n.x]) == Tile.CORE:
				if not goals.has(n) or not _can_attack_core(h):
					continue
			var nd := float(dist[cur]) + _step_cost(h, n)
			if nd < float(dist.get(n, INF)):
				dist[n] = nd
				came[n] = cur
				open.append(n)

	if reached.x < 0:
		return start
	# Walk the parent chain back down to the cell right next to the hero.
	var cur2 := reached
	var second := Vector2i(-1, -1)
	while came.has(cur2) and came[cur2] != start:
		second = cur2
		cur2 = came[cur2]
	if not came.has(cur2):
		return start
	h["route_second_step"] = second
	return cur2

# Last resort, used only when the whole known dungeon is already routed out:
# a plain local preference so the hero still does something readable.


# Last resort, used only when the whole known dungeon is already routed out:
# a plain local preference so the hero still does something readable.
func _local_step(h: Dictionary, candidates: Array[Vector2i]) -> Vector2i:
	var best := candidates[0]
	var best_score := -INF
	for q in candidates:
		var score := randf_range(-2.5, 2.5)
		score -= float(int(h["visited"].get(q, 0))) * 4.0
		score -= _corpse_danger_near(q) * float(h["fear_weight"])
		var seen := int(h["known"].get(q, Tile.ROCK))
		if sim._is_trap_tile(seen):
			score -= 8.0 * float(h["trap_weight"])
		if seen == Tile.ENTRANCE and bool(h["fleeing"]):
			score += 25.0
		if score > best_score:
			best_score = score
			best = q
	return best


func _corpse_danger_near(p: Vector2i) -> float:
	var danger := 0.0
	for corpse in sim.corpses:
		var cp: Vector2i = corpse["pos"]
		var dist := absi(cp.x - p.x) + absi(cp.y - p.y)
		if dist == 0:
			danger += float(corpse["fear"])
		elif dist == 1:
			danger += float(corpse["fear"]) * 0.5
	return danger / 10.0


func _hero_escapes() -> void:
	if hero.is_empty() or bool(hero.get("exiting", false)):
		return
	var ent: Vector2i = hero["pos"]
	if int(sim.grid[ent.y][ent.x]) != Tile.ENTRANCE:
		return
	hero["facing"] = -sim._entrance_mouth(ent)
	hero["fleeing"] = true
	hero["exiting"] = true
	hero["exit_t"] = TURN_TIME


func _begin_retreat(result_text: String) -> void:
	if hero.is_empty():
		return
	if sim.game_over:
		_end_raid(result_text)
		return
	hero["fleeing"] = true
	sim.message = result_text


func _finish_departure() -> void:
	if hero.is_empty():
		return
	var via_void := bool(hero.get("void_absorbing", false)) and float(hero.get("portal_t", 1.0)) <= 0.00001
	var via_exit := bool(hero.get("exiting", false)) and float(hero.get("exit_t", 1.0)) <= 0.00001 and int(sim.grid[hero.pos.y][hero.pos.x]) == Tile.ENTRANCE
	if not via_void and not via_exit:
		return
	hero["departed_alive"] = true
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = int(hero["carried_gold"])
	var text := String(hero.get("portal_msg", "")) if via_void else "%s walks out of the dungeon alive with %d gold." % [hero["display"], hero["carried_gold"]]
	_record_magic_door_escape()
	_merge_hero_knowledge()
	_end_raid(text)

func _record_xp_gold(amount: int) -> void:
	if amount > 0:
		_morale_progress()
	if hero.has("xp_ledger"):
		hero.xp_ledger.acquired_gold += maxi(0, amount)

func _record_xp_obstacle(cell: Vector2i, category: String) -> void:
	_morale_progress()
	if hero.has("xp_ledger"):
		hero.xp_ledger[category][cell] = true


func _record_magic_door_escape() -> void:
	if String(hero.get("kind", "")) == "mage":
		return
	if not bool(hero.get("saw_magic_door_blocker", false)):
		return
	mage_pressure += 1


func _merge_hero_knowledge() -> void:
	for cell in hero.get("known", {}).keys():
		kingdom_knowledge[cell] = hero["known"][cell]


func invalidate_kingdom_knowledge(cell: Vector2i) -> void:
	kingdom_knowledge.erase(cell)

# --- Grid and storage ------------------------------------------------------
