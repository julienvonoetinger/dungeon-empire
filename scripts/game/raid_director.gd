class_name RaidDirector
extends RefCounted

const Tile := GameTypes.Tile
const COLS := GameTypes.COLS
const ROWS := GameTypes.ROWS
const RAID_DELAY := GameTypes.RAID_DELAY
const CORE_MAX := GameTypes.CORE_MAX
const DOOR_MAX_HP := GameTypes.DOOR_MAX_HP
const TURN_TIME := GameTypes.TURN_TIME
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
var raid_active := false
var raid_index := 0
var hero: Dictionary = {}
var raid_stats: Dictionary = {}

func reset_for_new_map() -> void:
	raid_timer = RAID_DELAY
	raid_active = false
	raid_index = 0
	hero = {}
	raid_stats = {}


func _start_raid() -> void:
	var entrance := sim._find_tile(Tile.ENTRANCE)
	if entrance.x < 0:
		return

	var template := _random_hero_template()
	var trait_name := _roll_trait()
	var mods: Dictionary = TRAITS[trait_name]
	var greed := maxf(0.15, _jitter(float(mods["greed"]), 0.15))
	var hp := maxi(20, int(template["hp"]) + randi_range(-6, 6))
	raid_index += 1
	hero = {
		"name": template["name"],
		"trait": trait_name,
		"display": "%s (%s)" % [template["name"], trait_name],
		"kind": template["kind"],
		"pos": entrance,
		"hp": hp,
		"max_hp": hp,
		"carried_gold": template["loot"],
		"move_cd": 0.0,
		"turns": 0,
		"known": {},
		"visited": {entrance: 1},
		"bias": {},
		"ignored": {},
		"fleeing": false,
		"portaling": false,
		"portal_t": 0.0,
		"portal_msg": "",
		"facing": sim._entrance_mouth(entrance),
		"greed": greed,
		"steal_capacity": maxi(1, int(round(float(template["steal_capacity"]) * greed))),
		"fear_weight": _jitter(float(template["fear_weight"]) + float(mods["fear"]), 0.20),
		"trap_weight": maxf(0.05, _jitter(float(template["trap_weight"]) + float(mods["trap"]), 0.20)),
		"objective": template["objective"],
		"door_damage": maxi(4, int(template["door_damage"]) + randi_range(-3, 3)),
		"flee_ratio": clampf(_jitter(float(template["flee_ratio"]) + float(mods["flee"]), 0.05), 0.05, 0.8),
		"patience": maxi(25, int(template["patience"]) + int(mods["patience"]) + randi_range(-10, 10))
	}
	raid_active = true
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


func _roll_trait() -> String:
	var names := TRAITS.keys()
	return String(names[randi() % names.size()])


func _jitter(base: float, spread: float) -> float:
	return base + randf_range(-spread, spread)


func _random_hero_template() -> Dictionary:
	var roll := randi() % 3
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


func _end_raid(result_text: String) -> void:
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


func _update_hero(delta: float) -> void:
	if hero.is_empty():
		return

	if bool(hero.get("portaling", false)):
		hero["portal_t"] = float(hero.get("portal_t", 0.0)) - delta
		if float(hero["portal_t"]) <= 0.0:
			_finish_town_portal()
		return

	hero["move_cd"] = float(hero["move_cd"]) - delta
	if float(hero["move_cd"]) > 0.0:
		return
	hero["move_cd"] = TURN_TIME
	hero["turns"] = int(hero["turns"]) + 1

	_remember_nearby(hero)
	_update_flee_state()

	var pos: Vector2i = hero["pos"]

	# A fleeing hero leaves the dungeon as soon as it reaches the entrance again.
	if bool(hero["fleeing"]) and int(sim.grid[pos.y][pos.x]) == Tile.ENTRANCE:
		_hero_escapes()
		return

	# Safety net: a lost hero must not lock the dungeon forever.
	if int(hero["turns"]) > int(hero["patience"]) * 3:
		raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
		_open_town_portal("%s gets lost in the maze and eventually finds the way out." % hero["display"])
		return

	var next := _choose_next_step(hero)
	if next == pos:
		_open_town_portal("%s gives up exploring for lack of a useful path." % hero["display"])
		return

	# An intact door blocks: it has to be broken before passing through.
	if sim._door_intact(next):
		_attack_door(next)
		return

	hero["facing"] = next - pos
	hero["visited"][next] = int(hero["visited"].get(next, 0)) + 1
	hero["pos"] = next
	if hero.get("trap_sprung_at", Vector2i(-1, -1)) != next:
		hero.erase("trap_sprung_at")
	_resolve_cell(next)


func _update_flee_state() -> void:
	if bool(hero["fleeing"]):
		return
	var ratio := float(hero["hp"]) / float(hero["max_hp"])
	if ratio <= float(hero["flee_ratio"]):
		hero["fleeing"] = true
		sim.message = "%s is badly wounded and looks for the exit." % hero["display"]
	elif int(hero["turns"]) >= int(hero["patience"]):
		hero["fleeing"] = true
		sim.message = "%s has seen enough and looks for the exit." % hero["display"]

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
		_kill_hero()
		return

	if bool(hero["fleeing"]):
		return

	if tile == Tile.VAULT and String(hero["kind"]) == "thief":
		_try_rob_vault(pos)
		return

	if tile == Tile.CORE:
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
	sim.loot_bags = sim.loot_bags.filter(func(b): return not bool(b.get("taken", false)))
	sim.message = "%s picks up %d gold of unsecured loot!" % [hero["display"], taken]


func _trigger_trap(p: Vector2i, tile: int) -> void:
	var charges := int(sim.trap_charges.get(p, sim._trap_max_charges(tile)))
	if charges <= 0:
		return  # Spent defense: it stays inert until repaired.
	sim.trap_charges[p] = charges - 1
	raid_stats["traps_spent"] = int(raid_stats["traps_spent"]) + 1
	if tile == Tile.SPIKE:
		var damage := 24
		if String(hero["kind"]) == "paladin":
			damage = 15   # Lithides resist physical hazards (GAME_DESIGN.md §8).
		hero["hp"] = int(hero["hp"]) - damage
		hero["trap_sprung_at"] = p
	elif tile == Tile.VOID:
		hero["trap_sprung_at"] = p
		_banish_via_void()
	else:
		hero["hp"] = int(hero["hp"]) - 10
		hero["move_cd"] = float(hero["move_cd"]) + 0.55
		hero["trap_sprung_at"] = p


func _banish_via_void() -> void:
	var carried := int(hero["carried_gold"])
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = carried
	_open_town_portal("%s is torn through a void rift and expelled from the dungeon with %d gold." % [hero["display"], carried])


func _attack_door(p: Vector2i) -> void:
	if int(sim.door_hp.get(p, DOOR_MAX_HP)) <= 0:
		return
	var hp := int(sim.door_hp.get(p, DOOR_MAX_HP)) - int(hero["door_damage"])
	hero["move_cd"] = float(hero["move_cd"]) + 0.35
	if hp <= 0:
		sim.door_hp[p] = 0
		raid_stats["doors_destroyed"] = int(raid_stats["doors_destroyed"]) + 1
		sim.message = "%s forces a door. The wreck stays after the raid." % hero["display"]
	else:
		sim.door_hp[p] = hp
		sim.message = "%s strikes a door (%d HP left)." % [hero["display"], hp]

# A thief carries away only what fits in its bag, then teleports out.


# A thief carries away only what fits in its bag, then teleports out.
func _try_rob_vault(p: Vector2i) -> void:
	var storage := sim._storage_state()
	var vaults: Dictionary = storage["vaults"]
	var available := int(vaults.get(p, 0))
	if available <= 0:
		hero["ignored"][p] = true
		sim.message = "%s finds nothing but an empty storage." % hero["display"]
		return
	var amount := mini(available, int(hero["steal_capacity"]))
	sim.gold -= amount
	hero["carried_gold"] = int(hero["carried_gold"]) + amount
	raid_stats["stolen"] = int(raid_stats["stolen"]) + amount
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = int(hero["carried_gold"])
	var left := available - amount
	var rest := ""
	if left > 0:
		rest = " %d gold stays behind." % left
	_open_town_portal("%s steals %d gold and teleports out of the dungeon.%s" % [hero["display"], amount, rest])


func _hero_reaches_core() -> void:
	var damage := 24
	if String(hero["kind"]) == "paladin":
		damage = 42
	var lost := mini(sim.core_hp, damage)
	sim.core_hp = maxi(0, sim.core_hp - damage)
	raid_stats["core_lost"] = int(raid_stats["core_lost"]) + lost
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = int(hero["carried_gold"])

	if sim.core_hp <= 0:
		sim.game_over = true
		_open_town_portal("DEFEAT — %s destroys the Core. Click Reset to start a new campaign." % hero["display"])
		return

	_open_town_portal("%s strikes the Core (-%d integrity) then vanishes." % [hero["display"], damage])


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
	var radius := 3 if String(h["kind"]) == "ranger" else 2
	var p: Vector2i = h["pos"]
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var q := Vector2i(p.x + dx, p.y + dy)
			if sim._inside(q):
				# Rolled once per cell: two heroes never price a route alike.
				if not h["known"].has(q):
					h["bias"][q] = randf_range(0.0, ROUTE_BIAS)
				h["known"][q] = sim.grid[q.y][q.x]


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
	var start: Vector2i = h["pos"]
	var candidates: Array[Vector2i] = []
	for d in DIRS:
		var q := start + d
		if sim._can_step(start, q):
			candidates.append(q)
	if candidates.is_empty():
		return start

	# 1. Objective already spotted: head there using the mental map only.
	var target_tile := _target_tile(h)
	if target_tile >= 0:
		var step := _route_step(h, _known_targets(h, target_tile))
		if step != start:
			return step

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
	if sim._is_trap_tile(seen):
		cost += ROUTE_TRAP * float(h["trap_weight"])
	elif seen == Tile.DOOR:
		cost += ROUTE_DOOR
	# A Paladin has a negative fear weight: sim.corpses draw it in instead.
	cost += _corpse_danger_near(p) * float(h["fear_weight"])
	cost += float(h["bias"].get(p, 0.0))
	return maxf(0.05, cost)

# Cheapest route to any of the goals, over the mental map alone (never the real
# grid). Returns the first step, or the current cell when nothing is reachable.


# Cheapest route to any of the goals, over the mental map alone (never the real
# grid). Returns the first step, or the current cell when nothing is reachable.
func _route_step(h: Dictionary, goals: Dictionary) -> Vector2i:
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
			var nd := float(dist[cur]) + _step_cost(h, n)
			if nd < float(dist.get(n, INF)):
				dist[n] = nd
				came[n] = cur
				open.append(n)

	if reached.x < 0:
		return start
	# Walk the parent chain back down to the cell right next to the hero.
	var cur2 := reached
	while came.has(cur2) and came[cur2] != start:
		cur2 = came[cur2]
	if not came.has(cur2):
		return start
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
	var carried := int(hero["carried_gold"])
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = carried
	var ent: Vector2i = hero["pos"]
	hero["facing"] = -sim._entrance_mouth(ent)
	_open_town_portal("%s walks out of the dungeon alive with %d gold." % [hero["display"], carried])


func _open_town_portal(result_text: String) -> void:
	if hero.is_empty() or bool(hero.get("portaling", false)):
		return
	hero["portaling"] = true
	hero["portal_t"] = portal_hold
	hero["portal_msg"] = result_text
	sim.message = "%s opens a town portal." % hero["display"]


func _finish_town_portal() -> void:
	var text := String(hero.get("portal_msg", "The hero leaves the dungeon."))
	_end_raid(text)

# --- Grid and storage ------------------------------------------------------
