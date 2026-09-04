class_name DungeonSim
extends RefCounted

const Tile := GameTypes.Tile
const Tool := GameTypes.Tool
const COLS := GameTypes.COLS
const ROWS := GameTypes.ROWS
const CORE_W := GameTypes.CORE_W
const CORE_H := GameTypes.CORE_H
const CORE_MAX := GameTypes.CORE_MAX
const START_GOLD := GameTypes.START_GOLD
const VAULT_CAPACITY := GameTypes.VAULT_CAPACITY
const RAID_DELAY := GameTypes.RAID_DELAY
const DOOR_MAX_HP := GameTypes.DOOR_MAX_HP
const TRAP_MAX_CHARGES := GameTypes.TRAP_MAX_CHARGES
const COST_DIG := GameTypes.COST_DIG
const COST_VAULT := GameTypes.COST_VAULT
const COST_SPIKE := GameTypes.COST_SPIKE
const COST_SNARE := GameTypes.COST_SNARE
const COST_VOID := GameTypes.COST_VOID
const COST_DOOR := GameTypes.COST_DOOR
const COST_REPAIR_DOOR := GameTypes.COST_REPAIR_DOOR
const COST_REPAIR_TRAP := GameTypes.COST_REPAIR_TRAP
const DIRS := GameTypes.DIRS

var grid: Array = []
var selected_tool: int = Tool.DIG
var gold := START_GOLD
var core_hp := CORE_MAX
var loot_bags: Array = []
var corpses: Array = []
var door_hp: Dictionary = {}
var trap_charges: Dictionary = {}
var message := ""
var report := ""
var game_over := false
var reset_armed := false
var raid = null

func new_map() -> void:
	grid.clear()
	door_hp.clear()
	trap_charges.clear()
	loot_bags.clear()
	corpses.clear()
	for y in range(ROWS):
		var row := []
		for x in range(COLS):
			row.append(Tile.ROCK)
		grid.append(row)

	var core := Vector2i(9, 5)
	for dy in range(CORE_H):
		for dx in range(CORE_W):
			grid[core.y + dy][core.x + dx] = Tile.CORE
	for y in range(core.y - 1, core.y + CORE_H + 1):
		for x in range(core.x - 1, core.x + CORE_W + 1):
			if int(grid[y][x]) == Tile.CORE:
				continue
			grid[y][x] = Tile.FLOOR
	_place_starter_storage()
	gold = START_GOLD
	core_hp = CORE_MAX
	game_over = false
	reset_armed = false
	report = ""
	message = "The Core is sealed. Starter vaults hold the dungeon's gold. Dig a layout, then place the entrance stair."


func _has_entrance() -> bool:
	return _find_tile(Tile.ENTRANCE).x >= 0


func _unsecured_loot_total() -> int:
	var total := 0
	for bag in loot_bags:
		total += int(bag["gold"])
	return total


func _damaged_structure_count() -> int:
	var damaged := 0
	for key in door_hp.keys():
		var p: Vector2i = key
		if int(grid[p.y][p.x]) == Tile.DOOR and int(door_hp[p]) < DOOR_MAX_HP:
			damaged += 1
	for key in trap_charges.keys():
		var p: Vector2i = key
		var t := int(grid[p.y][p.x])
		if _is_trap_tile(t) and int(trap_charges[p]) < _trap_max_charges(t):
			damaged += 1
	return damaged


# --- Grid and storage ------------------------------------------------------

func _inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < COLS and p.y < ROWS


func _walkable(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) != Tile.ROCK


func _is_trap_tile(t: int) -> bool:
	return t == Tile.SPIKE or t == Tile.SNARE or t == Tile.VOID


func _trap_max_charges(t: int) -> int:
	return 1 if t == Tile.VOID else TRAP_MAX_CHARGES

# Stairs only connect along their run: corridor mouth, not the left/right flanks.
func _entrance_mouth(p: Vector2i) -> Vector2i:
	var core := _core_origin()
	var best := Vector2i.ZERO
	var best_score := -INF
	for d in DIRS:
		var n: Vector2i = p + d
		if not _walkable(n):
			continue
		if int(grid[n.y][n.x]) == Tile.ENTRANCE:
			continue
		var score := float(d.x) * float(core.x - p.x) + float(d.y) * float(core.y - p.y)
		if score > best_score:
			best_score = score
			best = d
	return best if best != Vector2i.ZERO else Vector2i.RIGHT


func _can_step(from: Vector2i, to: Vector2i) -> bool:
	if not _walkable(to):
		return false
	if absi(from.x - to.x) + absi(from.y - to.y) != 1:
		return false
	if int(grid[from.y][from.x]) == Tile.ENTRANCE:
		return to - from == _entrance_mouth(from)
	if int(grid[to.y][to.x]) == Tile.ENTRANCE:
		return from - to == _entrance_mouth(to)
	return true


func _door_intact(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) == Tile.DOOR and int(door_hp.get(p, DOOR_MAX_HP)) > 0


func _core_origin() -> Vector2i:
	return _find_tile(Tile.CORE)


func _find_tile(tile: int) -> Vector2i:
	for y in range(ROWS):
		for x in range(COLS):
			if int(grid[y][x]) == tile:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _place_starter_storage() -> void:
	var origin := Vector2i(9, 5)
	var needed := ceili(float(START_GOLD) / float(VAULT_CAPACITY))
	var placed := 0
	for y in range(origin.y + CORE_H, origin.y - 2, -1):
		for x in range(origin.x - 1, origin.x + CORE_W + 1):
			if placed >= needed:
				return
			if not _inside(Vector2i(x, y)):
				continue
			if int(grid[y][x]) != Tile.FLOOR:
				continue
			grid[y][x] = Tile.VAULT
			placed += 1


func _storage_capacity() -> int:
	return _vault_positions().size() * VAULT_CAPACITY


func _storage_free() -> int:
	return maxi(0, _storage_capacity() - gold)


func _deposit_gold(amount: int) -> int:
	var take := mini(maxi(0, amount), _storage_free())
	gold += take
	return take


func _spill_overflow_at(p: Vector2i) -> void:
	var extra := gold - _storage_capacity()
	if extra <= 0:
		return
	gold -= extra
	loot_bags.append({"pos": p, "gold": extra, "taken": false})


func _vault_positions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(ROWS):
		for x in range(COLS):
			if int(grid[y][x]) == Tile.VAULT:
				out.append(Vector2i(x, y))
	return out

# Dungeon wealth is physical: it fills the storages one by one and the
# surplus stays exposed next to the Core (GAME_DESIGN.md §5).


# Dungeon wealth is physical: it fills the storages one by one and the
# surplus stays exposed next to the Core (GAME_DESIGN.md §5).
func _storage_state() -> Dictionary:
	var vaults := {}
	var remaining := gold
	for p in _vault_positions():
		var amount := mini(remaining, VAULT_CAPACITY)
		vaults[p] = amount
		remaining -= amount
	return {"vaults": vaults, "unstored": 0, "capacity": _storage_capacity()}


func _has_open_neighbour(p: Vector2i) -> bool:
	for d in DIRS:
		if _walkable(p + d):
			return true
	return false


func _clear_cell_state(p: Vector2i) -> void:
	door_hp.erase(p)
	trap_charges.erase(p)

# --- Player input ----------------------------------------------------------


func _build_at(gp: Vector2i) -> void:
	if not _inside(gp):
		message = "No tile under the cursor."
		return
	var current := int(grid[gp.y][gp.x])
	if current == Tile.ENTRANCE or current == Tile.CORE:
		message = "The entrance and the Core cannot be modified."
		return

	match selected_tool:
		Tool.DIG:
			if current == Tile.ROCK:
				if not _has_open_neighbour(gp):
					message = "You must dig from an existing passage."
				elif gold < COST_DIG:
					message = "Not enough gold to dig (%d)." % COST_DIG
				else:
					gold -= COST_DIG
					grid[gp.y][gp.x] = Tile.FLOOR
					message = "Dug a passage."
			else:
				var was_vault := current == Tile.VAULT
				_clear_cell_state(gp)
				grid[gp.y][gp.x] = Tile.FLOOR
				if was_vault:
					_spill_overflow_at(gp)
				message = "Structure cleared."
		Tool.STORE:
			_place(gp, Tile.VAULT, COST_VAULT)
		Tool.TRAP_SPIKE:
			_place(gp, Tile.SPIKE, COST_SPIKE)
		Tool.TRAP_SNARE:
			_place(gp, Tile.SNARE, COST_SNARE)
		Tool.TRAP_VOID:
			_place(gp, Tile.VOID, COST_VOID)
		Tool.BUILD_DOOR:
			_place(gp, Tile.DOOR, COST_DOOR)
		Tool.BUILD_ENTRANCE:
			_place_entrance(gp)


func _place_entrance(p: Vector2i) -> void:
	if _has_entrance():
		message = "The entrance stair is already set. It cannot be moved."
		return
	if int(grid[p.y][p.x]) != Tile.FLOOR:
		message = "Place the stair on an open passage."
		return
	grid[p.y][p.x] = Tile.ENTRANCE
	if raid != null:
		raid.raid_timer = RAID_DELAY
	message = "Entrance opened. Heroes will find it in %ds." % int(RAID_DELAY)


func _place(p: Vector2i, tile: int, cost: int) -> void:
	var current := int(grid[p.y][p.x])
	if current == Tile.ROCK:
		message = "Dig this passage first."
		return
	if tile == Tile.DOOR and current != Tile.DOOR and not _door_between_walls(p):
		message = "A door must sit in a gap between two walls."
		return
	if current == tile:
		if tile != Tile.DOOR or int(door_hp.get(p, DOOR_MAX_HP)) > 0:
			return
	if gold < cost:
		message = "Not enough gold (%d required)." % cost
		return
	gold -= cost
	var was_vault := current == Tile.VAULT
	_clear_cell_state(p)
	grid[p.y][p.x] = tile
	if was_vault and tile != Tile.VAULT:
		_spill_overflow_at(p)
	if tile == Tile.DOOR:
		door_hp[p] = DOOR_MAX_HP
	elif _is_trap_tile(tile):
		trap_charges[p] = _trap_max_charges(tile)


func _door_between_walls(p: Vector2i) -> bool:
	# Opposite rocks: a 1-tile corridor or a hole punched through a wall.
	var ew := _is_rock_cell(p + Vector2i.LEFT) and _is_rock_cell(p + Vector2i.RIGHT)
	var ns := _is_rock_cell(p + Vector2i.UP) and _is_rock_cell(p + Vector2i.DOWN)
	return ew or ns


func _is_rock_cell(n: Vector2i) -> bool:
	return _inside(n) and int(grid[n.y][n.x]) == Tile.ROCK

# Repairs: outside raids only (GAME_DESIGN.md §7).
func _repair_structures() -> void:
	var doors := 0
	var charges := 0
	for key in door_hp.keys():
		var p: Vector2i = key
		if int(grid[p.y][p.x]) != Tile.DOOR:
			continue
		if int(door_hp[p]) <= 0 or int(door_hp[p]) >= DOOR_MAX_HP:
			continue
		if gold < COST_REPAIR_DOOR:
			break
		gold -= COST_REPAIR_DOOR
		door_hp[p] = DOOR_MAX_HP
		doors += 1
	for key in trap_charges.keys():
		var p: Vector2i = key
		var t := int(grid[p.y][p.x])
		if not _is_trap_tile(t):
			continue
		while int(trap_charges[p]) < _trap_max_charges(t) and gold >= COST_REPAIR_TRAP:
			gold -= COST_REPAIR_TRAP
			trap_charges[p] = int(trap_charges[p]) + 1
			charges += 1
	if doors == 0 and charges == 0:
		message = "Nothing to repair (or not enough gold)."
	else:
		message = "Repairs: %d door(s), %d trap charge(s)." % [doors, charges]
