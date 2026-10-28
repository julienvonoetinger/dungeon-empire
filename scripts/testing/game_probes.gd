extends RefCounted
## Passive observation only: notably, never call _storage_state/Save.capture here.
const Types = preload("res://scripts/game/game_types.gd")

static func cell_id(kind: String, cell: Vector2i) -> String:
	return "%s:%d:%d" % [kind, cell.x, cell.y]

static func json_value(value: Variant) -> Variant:
	if value is Vector2i or value is Vector2:
		return [value.x, value.y]
	if value is Dictionary:
		var result := {}
		for key in value:
			var name := "%d:%d" % [key.x,key.y] if key is Vector2i else str(key)
			result[name] = json_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(json_value(item))
		return result
	return value

static func snapshot(game) -> Dictionary:
	var sim = game.sim
	var raid = game.raid
	var probes := {
		"session": {"phase":game.phase(), "paused":game.paused, "editable":game.can_edit(),
			"ready_for_raid":game.ready_for_raid(), "result_open":game.result_open,
			"game_over":sim.game_over, "persistence_enabled":game.persistence_enabled},
		"core": {"hp":sim.core_hp, "max_hp":Types.CORE_MAX, "cell":json_value(sim._core_origin())},
		"raid": {"active":raid.raid_active, "index":raid.raid_index, "elapsed":raid.elapsed_seconds,
			"timer":raid.raid_timer, "stats":json_value(raid.raid_stats), "result":json_value(raid.last_result)},
		"hero": json_value(raid.hero),
		"progression": {"xp":game.progression.xp, "level":game.progression.level(),
			"last_raid_id":game.progression.last_raid_id},
		"loot": {"bags":json_value(sim.loot_bags), "corpses":json_value(sim.corpses)},
	}
	probes.hero["present"] = not raid.hero.is_empty()
	var stored := 0
	var vault_count := 0
	for y in range(sim.grid.size()):
		for x in range(sim.grid[y].size()):
			var p := Vector2i(x,y)
			var tile: int = sim.grid[y][x]
			probes[cell_id("cell",p)] = {"cell":[x,y], "tile":Types.Tile.keys()[tile], "walkable":sim._walkable(p)}
			if sim._is_door_tile(tile):
				var hp: int = sim.door_hp.get(p, Types.DOOR_MAX_HP)
				var opened: bool = sim.door_opened.get(p,false)
				probes[cell_id("door",p)] = {"cell":[x,y], "tile":Types.Tile.keys()[tile], "hp":hp,
					"max_hp":Types.DOOR_MAX_HP, "status":"open" if opened else ("locked" if hp > 0 else "broken"),
					"blocking":sim._door_intact(p)}
			elif sim._is_trap_tile(tile):
				var charges: int = sim.trap_charges.get(p, Types.trap_max_charges(tile))
				probes[cell_id("trap",p)] = {"cell":[x,y], "tile":Types.Tile.keys()[tile], "charges":charges,
					"max_charges":Types.trap_max_charges(tile), "spent":charges <= 0}
			elif tile == Types.Tile.VAULT:
				var gold: int = sim.vault_gold.get(p,0)
				stored += gold
				vault_count += 1
				probes[cell_id("vault",p)] = {"cell":[x,y], "gold":gold, "capacity":Types.VAULT_CAPACITY,
					"lock_tier":sim.vault_locks.get(p,0), "opened":sim.vault_opened.get(p,false), "protected":sim.vault_protected(p)}
	probes["economy"] = {"gold":sim.gold, "stored":stored, "unstored":sim.gold-stored,
		"capacity":vault_count*Types.VAULT_CAPACITY}
	return probes

static func violations(game) -> Array:
	var out: Array = []
	var sim = game.sim
	if sim.grid.size() != Types.ROWS:
		return [{"code":"grid.shape","probe":"session","message":"Wrong row count"}]
	for row in sim.grid:
		if not row is Array or row.size() != Types.COLS:
			return [{"code":"grid.shape","probe":"session","message":"Wrong column count"}]
		for tile in row:
			if not tile is int or tile < 0 or tile >= Types.Tile.size():
				return [{"code":"grid.tile","probe":"session","message":"Invalid tile"}]
	_check(out, sim.gold >= 0, "economy.gold", "economy", "Negative gold")
	_check(out, sim.core_hp >= 0 and sim.core_hp <= Types.CORE_MAX, "core.hp", "core", "Core HP out of range")
	var core_count := 0
	var entrance_count := 0
	var stored := 0
	for y in Types.ROWS:
		for x in Types.COLS:
			var p := Vector2i(x,y)
			var tile: int = sim.grid[y][x]
			if tile == Types.Tile.CORE: core_count += 1
			if tile == Types.Tile.ENTRANCE: entrance_count += 1
			if sim._is_door_tile(tile):
				var hp: int = sim.door_hp.get(p,Types.DOOR_MAX_HP)
				_check(out, hp >= 0 and hp <= Types.DOOR_MAX_HP, "door.hp", cell_id("door",p), "Door HP out of range")
				_check(out, not sim.door_opened.get(p,false) or hp == 0, "door.open_hp", cell_id("door",p), "Open door retains resistance")
			if sim._is_trap_tile(tile):
				var maximum := Types.trap_max_charges(tile)
				var charges: int = sim.trap_charges.get(p,maximum)
				_check(out, charges >= 0 and charges <= maximum, "trap.charges", cell_id("trap",p), "Charges out of range")
			if tile == Types.Tile.VAULT:
				var gold: int = sim.vault_gold.get(p,0)
				stored += gold
				_check(out, gold >= 0 and gold <= Types.VAULT_CAPACITY, "vault.gold", cell_id("vault",p), "Vault gold out of range")
				var tier: int = sim.vault_locks.get(p,0)
				_check(out, tier >= 0 and tier <= 2, "vault.lock", cell_id("vault",p), "Invalid protection tier")
	_check(out, core_count == 0 or core_count == Types.CORE_W*Types.CORE_H, "core.footprint", "core", "Invalid core footprint")
	_check(out, entrance_count <= 1, "entrance.count", "session", "Multiple entrances")
	# Gold may be unstored while building; it may not be assigned twice.
	_check(out, stored <= sim.gold, "economy.balance", "economy", "Vault balances exceed treasury")
	for field in ["door_hp","door_opened","trap_charges","vault_gold","vault_locks","vault_opened"]:
		for p in sim.get(field):
			var valid: bool = p is Vector2i and sim._inside(p)
			if valid:
				var tile: int = sim.grid[p.y][p.x]
				valid = sim._is_door_tile(tile) if field.begins_with("door") else (sim._is_trap_tile(tile) if field == "trap_charges" else tile == Types.Tile.VAULT)
			_check(out, valid, "entity.orphan", field, "State references absent entity at %s" % str(p))
	var raid = game.raid
	_check(out, not raid.raid_active or not raid.hero.is_empty(), "hero.missing", "hero", "Active raid has no hero")
	if not raid.hero.is_empty():
		var p = raid.hero.get("pos")
		var valid: bool = p is Vector2i and sim._inside(p)
		_check(out, valid, "hero.position", "hero", "Hero outside grid")
		if valid:
			_check(out, sim._walkable(p) and (not raid.solid_core or sim.grid[p.y][p.x] != Types.Tile.CORE) and not sim._door_intact(p),
				"hero.blocked", "hero", "Hero occupies rock, solid core or closed door")
	return out

static func _check(out: Array, ok: bool, code: String, probe: String, message: String) -> void:
	if not ok: out.append({"code":code,"probe":probe,"message":message})
