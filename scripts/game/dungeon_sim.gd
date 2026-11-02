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
const COST_MAGIC_DOOR := GameTypes.COST_MAGIC_DOOR
const COST_REPAIR_DOOR := GameTypes.COST_REPAIR_DOOR
const COST_REPAIR_TRAP := GameTypes.COST_REPAIR_TRAP
const DIRS := GameTypes.DIRS
const ROOM_CELLS: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]
const ROOM_SIDES := ["N","E","S","W"]
const ROOM_OUT := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var grid: Array = []
var selected_tool: int = Tool.NONE
var gold := START_GOLD
var vault_gold: Dictionary = {}
var vault_locks: Dictionary = {}
var vault_opened: Dictionary = {}
var core_hp := CORE_MAX
var loot_bags: Array = []
var corpses: Array = []
var door_hp: Dictionary = {}
var door_opened: Dictionary = {}
var trap_charges: Dictionary = {}
var message := ""
var report := ""
var game_over := false
var reset_armed := false
var raid = null

func new_map() -> void:
	vault_gold.clear()
	vault_locks.clear()
	vault_opened.clear()
	grid.clear()
	door_hp.clear()
	door_opened.clear()
	trap_charges.clear()
	loot_bags.clear()
	corpses.clear()
	for y in range(ROWS):
		var row := []
		for x in range(COLS):
			row.append(Tile.ROCK)
		grid.append(row)
	gold = START_GOLD
	core_hp = CORE_MAX
	game_over = false
	reset_armed = false
	selected_tool = Tool.NONE
	report = ""
	message = "Choose an anchoring site for the Dungeon Core."


func _has_core() -> bool:
	return _core_origin().x >= 0


func _can_place_core(origin: Vector2i) -> bool:
	if _has_core():
		return false
	var min_x := 0
	var min_y := 0
	var max_x := COLS - CORE_W
	var max_y := ROWS - CORE_H
	if origin.x < min_x or origin.x > max_x or origin.y < min_y or origin.y > max_y:
		return false
	return (origin.x - min_x) % CORE_W == 0 and (origin.y - min_y) % CORE_H == 0


func _place_core(origin: Vector2i) -> bool:
	if not _can_place_core(origin):
		message = "The Core must anchor inside the marked influence field."
		return false
	for dy in range(CORE_H):
		for dx in range(CORE_W):
			grid[origin.y + dy][origin.x + dx] = Tile.CORE
	repair_core_access()
	message = "The Core awakens. Its surrounding passage is free. Dig out from this room."
	return true


func _is_core_access(p: Vector2i) -> bool:
	var origin := _core_origin()
	if origin.x < 0 or not _inside(p):
		return false
	var footprint := Rect2i(origin, Vector2i(CORE_W, CORE_H))
	return footprint.grow(1).has_point(p) and not footprint.has_point(p)


func repair_core_access() -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	var origin := _core_origin()
	if origin.x < 0:
		return changed
	var previous_capacity := _storage_capacity()
	for y in range(maxi(0, origin.y - 1), mini(ROWS, origin.y + CORE_H + 1)):
		for x in range(maxi(0, origin.x - 1), mini(COLS, origin.x + CORE_W + 1)):
			var p := Vector2i(x, y)
			var tile := int(grid[y][x])
			if not _is_core_access(p) or (tile != Tile.ROCK and not _is_door_tile(tile)):
				continue
			# Old saves keep the value of doors displaced by the access rule.
			if _is_door_tile(tile):
				loot_bags.append({"pos": p, "gold": COST_DOOR if tile == Tile.DOOR else COST_MAGIC_DOOR, "taken": false})
			_clear_cell_state(p)
			grid[y][x] = Tile.FLOOR
			changed.append(p)
	if not changed.is_empty():
		_spill_overflow_at(changed.front(), previous_capacity)
	return changed


func _has_entrance() -> bool:
	return _find_tile(Tile.ENTRANCE).x >= 0


func _has_required_storage() -> bool:
	return _has_core() and _has_entrance() and _storage_capacity() >= gold


func _unsecured_loot_total() -> int:
	var total := 0
	for bag in loot_bags:
		total += int(bag["gold"])
	return total


func _damaged_structure_count() -> int:
	var damaged := 0
	for p in vault_locks:
		if _inside(p) and int(grid[p.y][p.x]) == Tile.VAULT and bool(vault_opened.get(p, false)):
			damaged += 1
	for key in door_hp.keys():
		var p: Vector2i = key
		if _is_door_tile(int(grid[p.y][p.x])) and int(door_hp[p]) < DOOR_MAX_HP:
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


func _is_door_tile(t: int) -> bool:
	return t == Tile.DOOR or t == Tile.MAGIC_DOOR


func _trap_max_charges(t: int) -> int:
	return 1 if t == Tile.VOID else TRAP_MAX_CHARGES

func _wall_entrance_face(p: Vector2i) -> Vector2i:
	if not _inside(p) or int(grid[p.y][p.x]) not in [Tile.FLOOR, Tile.ENTRANCE]:
		return Vector2i.ZERO
	var core := _core_origin()
	var best := Vector2i.ZERO
	var best_score := -INF
	for direction in DIRS:
		if _walkable(p - direction) or not _walkable(p + direction):
			continue
		if int(grid[p.y + direction.y][p.x + direction.x]) == Tile.ENTRANCE:
			continue
		var score := Vector2(direction).dot(Vector2(core - p)) if core.x >= 0 else 0.0
		if score > best_score:
			best = direction
			best_score = score
	return best

func repair_entrance_placement() -> Dictionary:
	var old := _find_tile(Tile.ENTRANCE)
	if old.x < 0 or (not _is_core_access(old) and _wall_entrance_face(old) != Vector2i.ZERO):
		return {}
	# Migrate only the entrance, never overwrite a paid structure or excavate rock.
	grid[old.y][old.x] = Tile.FLOOR
	var queue: Array[Vector2i] = [old]
	var seen := {old: true}
	var cursor := 0
	var destination := Vector2i(-1, -1)
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		if int(grid[cell.y][cell.x]) == Tile.FLOOR and not _is_core_access(cell) and _wall_entrance_face(cell) != Vector2i.ZERO:
			destination = cell
			break
		for direction in DIRS:
			var next := cell + direction
			if not seen.has(next) and _walkable(next) and int(grid[next.y][next.x]) != Tile.CORE:
				seen[next] = true
				queue.append(next)
	if destination.x >= 0:
		grid[destination.y][destination.x] = Tile.ENTRANCE
		message = "Entrance repositioned against a wall."
	else:
		message = "Old entrance removed: place a new entrance against a wall for free."
	return {"from": old, "to": destination}

# Entrances connect through their mouth, never through their stone backing.
func _entrance_mouth(p: Vector2i) -> Vector2i:
	var wall_face := _wall_entrance_face(p)
	if wall_face != Vector2i.ZERO:
		return wall_face
	var core := _core_origin()
	if core.x < 0:
		return Vector2i.RIGHT
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
	return _inside(p) and _is_door_tile(int(grid[p.y][p.x])) and int(door_hp.get(p, DOOR_MAX_HP)) > 0


func _core_origin() -> Vector2i:
	return _find_tile(Tile.CORE)


func _find_tile(tile: int) -> Vector2i:
	for y in range(ROWS):
		for x in range(COLS):
			if int(grid[y][x]) == tile:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _storage_capacity() -> int:
	var total := 0
	for limit: int in vault_capacities().values(): total += limit
	return total


func _deposit_gold(amount: int) -> int:
	var take := clampi(amount, 0, maxi(0, _storage_capacity() - gold))
	gold += take
	_storage_state()
	return take


func _spill_overflow_at(p: Vector2i, previous_capacity: int = -1) -> void:
	var capacity := _storage_capacity()
	if previous_capacity >= 0 and capacity >= previous_capacity: return
	var extra := gold - capacity
	if extra > 0:
		gold -= extra
		loot_bags.append({"pos": p, "gold": extra, "taken": false})
	_storage_state()


func _vault_positions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(ROWS):
		for x in range(COLS):
			if int(grid[y][x]) == Tile.VAULT:
				out.append(Vector2i(x, y))
	return out

func _treasure_at_origin(origin: Vector2i) -> Dictionary:
	if not _inside(origin) or not _inside(origin + Vector2i.ONE):
		return {}
	var members: Array[Vector2i] = []
	for offset in ROOM_CELLS:
		var p := origin + offset
		# A picked lock keeps its protection tier until repaired.
		if grid[p.y][p.x] != Tile.VAULT or int(vault_locks.get(p, 0)) != 0: return {}
		members.append(p)
	var result := {}
	for i in ROOM_SIDES.size():
		var out: Vector2i = ROOM_OUT[i]
		var axis := Vector2i.RIGHT if out.y != 0 else Vector2i.DOWN
		var first := origin + Vector2i(maxi(out.x,0), maxi(out.y,0)) + out
		for slot in 2:
			var opening := first + axis * slot
			if not _is_excavated(opening): continue
			if not result.is_empty() or grid[opening.y][opening.x] == Tile.CORE: return {}
			result = {"origin":origin,"cells":members,"side":ROOM_SIDES[i],"slot":slot,"entrance":opening}
	return result

func treasure_rooms() -> Array[Dictionary]:
	var rooms: Array[Dictionary] = []
	for origin in _vault_positions():
		var room := _treasure_at_origin(origin)
		if not room.is_empty(): rooms.append(room)
	return rooms

func storage_cells(cell: Vector2i) -> Array[Vector2i]:
	if not _inside(cell) or grid[cell.y][cell.x] != Tile.VAULT: return []
	for offset in ROOM_CELLS:
		var room := _treasure_at_origin(cell - offset)
		if not room.is_empty(): return room.cells
	return [cell]

func stored_gold(cells: Array) -> int:
	var total := 0
	for cell in cells: total += int(vault_gold.get(cell, 0))
	return total

func vault_capacities() -> Dictionary:
	# Keep grid order for redistributing gold when a room forms or dissolves.
	var limits := {}
	for p in _vault_positions(): limits[p] = VAULT_CAPACITY
	for origin: Vector2i in limits:
		var room := _treasure_at_origin(origin)
		if not room.is_empty():
			for p in room.cells: limits[p] = GameTypes.TREASURY_MEMBER_CAPACITY
	return limits

# Preserve assigned balances; reconcile purchases, deposits and removed vaults
# against the total treasury. New or legacy vaults fill in grid order.
func _storage_state() -> Dictionary:
	var vaults := {}
	var limits := vault_capacities()
	var capacity := 0
	for p in limits:
		capacity += int(limits[p])
		vaults[p] = clampi(int(vault_gold.get(p, 0)), 0, limits[p])
	var assigned := 0
	for amount in vaults.values():
		assigned += int(amount)
	var difference := gold - assigned
	for p in vaults:
		var change := clampi(difference, -int(vaults[p]), int(limits[p]) - int(vaults[p]))
		vaults[p] += change
		difference -= change
	vault_gold = vaults.duplicate()
	return {"vaults": vaults, "unstored": maxi(0, difference), "capacity": capacity}


func transfer_gold(source: Vector2i, destination: Vector2i, requested: int) -> int:
	if game_over or (raid != null and raid.raid_active) or requested <= 0 or source == destination:
		return 0
	var from := storage_cells(source)
	var to := storage_cells(destination)
	if from.is_empty() or to.is_empty() or from.has(destination):
		return 0
	_storage_state()
	var amount := mini(requested, mini(stored_gold(from), GameTypes.store_capacity(to) - stored_gold(to)))
	if amount <= 0:
		return 0
	_change_storage(from, -amount)
	_change_storage(to, amount)
	if raid != null:
		for cell in from + to: raid.invalidate_kingdom_knowledge(cell)
	return amount


func _change_storage(cells: Array[Vector2i], delta: int) -> void:
	var limit := GameTypes.capacity_per_chest(cells)
	for cell in cells:
		var balance := int(vault_gold.get(cell, 0))
		var change := clampi(delta, -balance, limit - balance)
		vault_gold[cell] = balance + change
		delta -= change
		if delta == 0: break

func withdraw_vault_gold(cell: Vector2i, requested: int) -> int:
	_storage_state()
	var cells := storage_cells(cell)
	var amount := mini(maxi(0, requested), stored_gold(cells))
	if amount > 0:
		_change_storage(cells, -amount)
		gold -= amount
	return amount


func _has_open_neighbour(p: Vector2i) -> bool:
	for d in DIRS:
		if _walkable(p + d):
			return true
	return false


func _is_excavated(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) != Tile.ROCK


func _is_diggable_rock(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) == Tile.ROCK and _has_open_neighbour(p)


func _faces_map_limit(p: Vector2i) -> bool:
	if not _is_excavated(p):
		return false
	for d in DIRS:
		if not _inside(p + d):
			return true
	return false


func _clear_cell_state(p: Vector2i) -> void:
	vault_locks.erase(p)
	vault_opened.erase(p)
	door_hp.erase(p)
	door_opened.erase(p)
	trap_charges.erase(p)


func _can_place_tile(p: Vector2i, tile: int) -> bool:
	if not _inside(p):
		return false
	var current := int(grid[p.y][p.x])
	if current == Tile.ROCK or current == Tile.ENTRANCE or current == Tile.CORE:
		return false
	if _is_core_access(p) and (_is_door_tile(tile) or tile == Tile.ENTRANCE):
		return false
	if _is_door_tile(tile) and current != tile and not _door_between_walls(p):
		return false
	return true

# --- Player input ----------------------------------------------------------


func _build_at(gp: Vector2i) -> void:
	if game_over:
		return
	if raid != null and bool(raid.raid_active):
		return
	if not _inside(gp):
		message = "No tile under the cursor."
		return
	var current := int(grid[gp.y][gp.x])
	if current == Tile.ROCK:
		_try_dig(gp)
		return
	if selected_tool == Tool.NONE:
		return
	if current == Tile.ENTRANCE or current == Tile.CORE:
		message = "The entrance and the Core cannot be modified."
		return

	match selected_tool:
		Tool.DIG:
			var was_vault := current == Tile.VAULT
			_clear_cell_state(gp)
			grid[gp.y][gp.x] = Tile.FLOOR
			if raid != null:
				raid.invalidate_kingdom_knowledge(gp)
			if was_vault:
				_spill_overflow_at(gp)
			message = "Structure cleared."
		Tool.STORE:
			build_vault(gp, 0)
		Tool.STORE_LOCKED:
			build_vault(gp, 1)
		Tool.STORE_MAGIC:
			build_vault(gp, 2)
		Tool.TRAP_SPIKE:
			_place(gp, Tile.SPIKE, COST_SPIKE)
		Tool.TRAP_SNARE:
			_place(gp, Tile.SNARE, COST_SNARE)
		Tool.TRAP_VOID:
			_place(gp, Tile.VOID, COST_VOID)
		Tool.BUILD_DOOR:
			_place(gp, Tile.DOOR, COST_DOOR)
		Tool.BUILD_MAGIC_DOOR:
			_place(gp, Tile.MAGIC_DOOR, COST_MAGIC_DOOR)
		Tool.BUILD_ENTRANCE:
			_place_entrance(gp)


func vault_protected(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) == Tile.VAULT and int(vault_locks.get(p, 0)) > 0 and not bool(vault_opened.get(p, false))

func build_vault(p: Vector2i, tier: int) -> bool:
	if game_over or (raid != null and raid.raid_active) or tier < 0 or tier > 2 or not _inside(p):
		return false
	if not _can_place_tile(p, Tile.VAULT):
		message = "Place the chest on an excavated tile."
		return false
	var existing := int(grid[p.y][p.x]) == Tile.VAULT
	var previous := int(vault_locks.get(p, 0)) if existing else 0
	if existing and tier <= previous:
		message = "This chest already has this protection or better."
		return false
	var cost: int = GameTypes.VAULT_PROTECTION_COSTS[tier] - GameTypes.VAULT_PROTECTION_COSTS[previous]
	if gold < cost:
		message = "Not enough gold: %d required." % cost
		return false
	var previous_capacity := int(_storage_state().capacity)
	if not existing:
		_clear_cell_state(p)
		grid[p.y][p.x] = Tile.VAULT
	gold -= cost
	if tier > 0:
		vault_locks[p] = tier
		if existing: _spill_overflow_at(p, previous_capacity)
	vault_opened.erase(p)
	if raid != null:
		raid.invalidate_kingdom_knowledge(p)
	message = "Chest upgraded." if existing else "Chest placed."
	return true

func repair_vault(p: Vector2i) -> bool:
	if game_over or (raid != null and raid.raid_active) or not _inside(p):
		return false
	if int(grid[p.y][p.x]) != Tile.VAULT or int(vault_locks.get(p, 0)) <= 0 or vault_protected(p):
		return false
	if gold < GameTypes.COST_REPAIR_VAULT:
		message = "Not enough gold: %d required." % GameTypes.COST_REPAIR_VAULT
		return false
	gold -= GameTypes.COST_REPAIR_VAULT
	vault_opened.erase(p)
	if raid != null:
		raid.invalidate_kingdom_knowledge(p)
	message = "Chest protection restored."
	return true

func dig_failure_reason(gp: Vector2i) -> String:
	if not _inside(gp) or int(grid[gp.y][gp.x]) != Tile.ROCK:
		return "This tile is not rock."
	for direction in DIRS:
		var neighbour := gp + direction
		if _inside(neighbour) and int(grid[neighbour.y][neighbour.x]) == Tile.ENTRANCE:
			return "This rock supports the entrance."
	if not _has_open_neighbour(gp):
		return "You must dig from an existing passage."
	if gold < COST_DIG:
		return "Not enough gold to dig (%d)." % COST_DIG
	return ""

func _try_dig(gp: Vector2i) -> void:
	var reason := dig_failure_reason(gp)
	if not reason.is_empty():
		message = reason
		return
	var previous_capacity := _storage_capacity()
	gold -= COST_DIG
	grid[gp.y][gp.x] = Tile.FLOOR
	_spill_overflow_at(gp, previous_capacity)
	if raid != null:
		raid.invalidate_kingdom_knowledge(gp)
	message = "Dug a passage."


func _place_entrance(p: Vector2i) -> void:
	if _is_core_access(p):
		message = "Keep the passage around the Core clear: place the entrance farther away."
		return
	if _has_entrance():
		message = "The entrance stair is already set. It cannot be moved."
		return
	if not _inside(p) or int(grid[p.y][p.x]) != Tile.FLOOR or _wall_entrance_face(p) == Vector2i.ZERO:
		message = "Place the entrance against a wall, with a clear passage in front."
		return
	grid[p.y][p.x] = Tile.ENTRANCE
	if raid != null:
		raid.raid_timer = RAID_DELAY
	if _has_required_storage():
		message = "Entrance opened. Heroes will find it in %ds." % int(RAID_DELAY)
	else:
		message = "Entrance opened. Build enough storage before heroes can find it."


func _place(p: Vector2i, tile: int, cost: int) -> void:
	var current := int(grid[p.y][p.x])
	if current == Tile.ROCK:
		message = "Dig this passage first."
		return
	if not _can_place_tile(p, tile):
		message = "Keep the passage around the Core clear." if _is_core_access(p) else "A door must sit in a gap between two walls."
		return
	if current == tile:
		if not _is_door_tile(tile) or int(door_hp.get(p, DOOR_MAX_HP)) > 0:
			return
	if gold < cost:
		message = "Not enough gold (%d required)." % cost
		return
	gold -= cost
	var was_vault := current == Tile.VAULT
	_clear_cell_state(p)
	grid[p.y][p.x] = tile
	if raid != null:
		raid.invalidate_kingdom_knowledge(p)
	if was_vault and tile != Tile.VAULT:
		_spill_overflow_at(p)
	if _is_door_tile(tile):
		door_hp[p] = DOOR_MAX_HP
		door_opened.erase(p)
		if raid != null:
			raid.invalidate_kingdom_knowledge(p)
	elif _is_trap_tile(tile):
		trap_charges[p] = _trap_max_charges(tile)


func _door_between_walls(p: Vector2i) -> bool:
	if not _inside(p):
		return false
	# Opposite rocks: a 1-tile corridor or a hole punched through a wall.
	var ew := _is_rock_cell(p + Vector2i.LEFT) and _is_rock_cell(p + Vector2i.RIGHT)
	var ns := _is_rock_cell(p + Vector2i.UP) and _is_rock_cell(p + Vector2i.DOWN)
	return ew or ns


func _is_rock_cell(n: Vector2i) -> bool:
	# The map boundary has the same solid wall as an unexcavated cell.
	return not _inside(n) or int(grid[n.y][n.x]) == Tile.ROCK

# Repairs: outside raids only (GAME_DESIGN.md §7).
func repair_trap(p: Vector2i) -> int:
	if game_over or (raid != null and raid.raid_active) or not _inside(p):
		return 0
	var tile := int(grid[p.y][p.x])
	if not _is_trap_tile(tile):
		return 0
	var charges := 0
	while int(trap_charges.get(p, _trap_max_charges(tile))) < _trap_max_charges(tile) and gold >= COST_REPAIR_TRAP:
		gold -= COST_REPAIR_TRAP
		trap_charges[p] = int(trap_charges[p]) + 1
		charges += 1
	return charges

func repair_door(p: Vector2i) -> bool:
	if game_over or (raid != null and raid.raid_active) or not _inside(p):
		return false
	if not _is_door_tile(int(grid[p.y][p.x])) or gold < COST_REPAIR_DOOR:
		return false
	if int(door_hp.get(p, DOOR_MAX_HP)) >= DOOR_MAX_HP and not bool(door_opened.get(p, false)):
		return false
	gold -= COST_REPAIR_DOOR
	door_hp[p] = DOOR_MAX_HP
	door_opened.erase(p)
	if raid != null:
		raid.invalidate_kingdom_knowledge(p)
	return true

func _repair_structures() -> void:
	var doors := 0
	var charges := 0
	for key in door_hp.keys():
		var p: Vector2i = key
		if not _is_door_tile(int(grid[p.y][p.x])):
			continue
		if int(grid[p.y][p.x]) == Tile.MAGIC_DOOR:
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
