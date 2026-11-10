class_name GameplaySave
extends RefCounted

const Types = preload("res://scripts/game/game_types.gd")
const Roster = preload("res://scripts/game/hero_roster.gd")
const VERSION := 1
const MAX_FILE_BYTES := 4 * 1024 * 1024
const MAX_VALUE := 2147483647
const MAX_RECORDS := 16384
const SIM_FIELDS := ["grid", "gold", "core_hp", "door_hp", "door_opened", "trap_charges", "loot_bags", "corpses", "game_over"]
const FIELDS := ["version", "grid", "gold", "core_hp", "door_hp", "door_opened", "trap_charges", "loot_bags", "corpses", "game_over", "kingdom_knowledge", "raid_index", "mage_pressure", "progression"]

static func capture(sim, raid, progression) -> Dictionary:
	sim._storage_state()
	var data := {"version": VERSION, "kingdom_knowledge": raid.kingdom_knowledge,
		"raid_index": raid.raid_index, "mage_pressure": raid.mage_pressure, "progression": progression.snapshot(), "vault_gold": sim.vault_gold}
	for field in SIM_FIELDS:
		data[field] = sim.get(field)
	if not sim.floor_gold.is_empty(): data["floor_gold"] = sim.floor_gold
	data["vault_locks"] = sim.vault_locks
	data["vault_opened"] = sim.vault_opened
	data["hero_roster"] = raid.roster.snapshot()
	if sim.lesson != Types.Lesson.FREE: data["lesson"] = sim.lesson
	if sim.invoker_resident: data["invoker_resident"] = true
	if sim.lesson in [Types.Lesson.MEET_CARPENTER, Types.Lesson.DOOR] and sim.lesson_alcove != Types.FIRST_ALCOVE:
		data["lesson_alcove"] = sim.lesson_alcove
	return data.duplicate(true)

static func apply(data: Dictionary, sim, raid, progression) -> bool:
	if not _valid(data):
		return false
	var snapshot := data.duplicate(true)
	if not progression.restore(snapshot.progression):
		return false
	for field in SIM_FIELDS:
		sim.set(field, snapshot[field])
	sim.floor_gold = snapshot.get("floor_gold", {})
	sim.vault_gold = snapshot.get("vault_gold", {})
	sim.vault_locks = snapshot.get("vault_locks", {})
	sim.vault_opened = snapshot.get("vault_opened", {})
	sim.lesson = snapshot.get("lesson", Types.Lesson.FREE)
	sim.invoker_resident = snapshot.get("invoker_resident", false)
	sim.lesson_alcove = snapshot.get("lesson_alcove", Types.FIRST_ALCOVE)
	progression.awaiting_miner = sim.lesson in [Types.Lesson.INVOKER_OFFER, Types.Lesson.VILLAGE_GIFT, Types.Lesson.MEET_MINER]
	if sim.lesson == Types.Lesson.DOOR and progression.level() < 2:
		# Old saves either started with a door, or had already paid to excavate.
		sim.lesson = Types.Lesson.ALCOVE if sim.grid[sim.lesson_alcove.y][sim.lesson_alcove.x] == Types.Tile.ROCK else Types.Lesson.MEET_CARPENTER
	elif sim.lesson == Types.Lesson.LEGACY_BAG:
		if progression.level() < 3:
			sim.lesson = Types.Lesson.MEET_CARPENTER if progression.level() < 2 else Types.Lesson.MEET_SCIENTIST
		else:
			sim.lesson = Types.Lesson.SPIKES if sim._find_tile(Types.Tile.SPIKE).x < 0 else Types.Lesson.PRACTICE_RAID
	sim.selected_tool = Types.Tool.NONE
	sim.reset_armed = false
	sim.message = ""
	sim.report = ""
	raid.reset_for_new_map()
	if snapshot.has("hero_roster"):
		raid.roster.restore(snapshot.hero_roster)
	raid.kingdom_knowledge = snapshot.kingdom_knowledge
	raid.raid_index = snapshot.raid_index
	raid.mage_pressure = snapshot.mage_pressure
	for cell in sim.repair_core_access():
		raid.kingdom_knowledge.erase(cell)
	var moved: Dictionary = sim.repair_entrance_placement()
	if not moved.is_empty():
		raid.kingdom_knowledge.erase(moved["from"])
		raid.kingdom_knowledge.erase(moved["to"])
	return true

static func write_save(path: String, data: Dictionary) -> bool:
	if path.is_empty() or not _valid(data):
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(data, false)
	file.flush()
	var ok := file.get_error() == OK and file.get_length() <= MAX_FILE_BYTES
	file.close()
	if not ok or _read_file(temporary).is_empty():
		DirAccess.remove_absolute(temporary)
		return false
	# Never replace a good backup with a corrupt primary. The final rename
	# replaces the primary directly, without deleting it first.
	if not _read_file(path).is_empty():
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			DirAccess.remove_absolute(temporary)
			return false
	if DirAccess.rename_absolute(temporary, path) != OK:
		DirAccess.remove_absolute(temporary)
		return false
	return true

static func read_save(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var data := _read_file(path)
	return _read_file(path + ".bak") if data.is_empty() else data

static func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var size := file.get_length()
	if size < 8 or size > MAX_FILE_BYTES:
		file.close()
		return {}
	# store_var prefixes the encoded Variant with its byte length.
	var payload_size := file.get_32()
	if payload_size != size - 4:
		file.close()
		return {}
	file.seek(0)
	var data = file.get_var(false)
	var ok := file.get_error() == OK
	file.close()
	if not ok or not data is Dictionary or not _valid(data):
		return {}
	return data

static func _keys(value, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size():
		return false
	for key in keys:
		if not value.has(key):
			return false
	return true

static func _integer(value, maximum: int = MAX_VALUE) -> bool:
	return value is int and value >= 0 and value <= maximum

static func _coord(value) -> bool:
	return value is Vector2i and value.x >= 0 and value.y >= 0 and value.x < Types.COLS and value.y < Types.ROWS

static func _tile(value) -> bool:
	return value is int and value in Types.Tile.values()

static func _valid(data: Dictionary) -> bool:
	var fields := FIELDS.duplicate()
	if data.has("invoker_resident"):
		if not data.invoker_resident is bool: return false
		fields.append("invoker_resident")
	if data.has("lesson"):
		if not data.lesson is int or data.lesson not in Types.Lesson.values(): return false
		fields.append("lesson")
	if data.has("lesson_alcove"):
		if not _coord(data.lesson_alcove) or data.get("lesson") not in [Types.Lesson.MEET_CARPENTER, Types.Lesson.DOOR, Types.Lesson.MEET_SCIENTIST, Types.Lesson.SPIKES, Types.Lesson.LEGACY_BAG]: return false
		fields.append("lesson_alcove")
	if data.has("vault_gold"):
		fields.append("vault_gold")
	for field in ["floor_gold", "vault_locks", "vault_opened", "hero_roster"]:
		if data.has(field):
			fields.append(field)
	if not _keys(data, fields) or not data.version is int or data.version != VERSION:
		return false
	if data.has("hero_roster") and not Roster.valid_snapshot(data.hero_roster):
		return false
	if not _integer(data.gold) or not _integer(data.core_hp, Types.CORE_MAX) or not _integer(data.raid_index):
		return false
	if not _integer(data.mage_pressure):
		return false
	if not data.game_over is bool:
		return false
	if not data.progression is Dictionary: return false
	var progression_fields := ["xp", "last_raid_id"]
	if data.progression.has("invocation_xp"):
		progression_fields.append("invocation_xp")
		if not _integer(data.progression.invocation_xp): return false
	if not _keys(data.progression, progression_fields):
		return false
	if not _integer(data.progression.xp) or not _integer(data.progression.last_raid_id):
		return false
	if data.progression.get("invocation_xp",0) > data.progression.xp: return false
	if data.get("lesson") in [Types.Lesson.INVOKER_OFFER, Types.Lesson.VILLAGE_GIFT, Types.Lesson.MEET_MINER] and data.progression.get("invocation_xp",0) != data.progression.xp: return false
	if not data.grid is Array or data.grid.size() != Types.ROWS:
		return false
	for row in data.grid:
		if not row is Array or row.size() != Types.COLS:
			return false
		for tile in row:
			if not _tile(tile):
				return false
	if data.has("lesson_alcove") and data.grid[data.lesson_alcove.y][data.lesson_alcove.x] != Types.Tile.FLOOR: return false
	var bags = data.get("floor_gold", {})
	if not bags is Dictionary or bags.size() > Types.COLS * Types.ROWS: return false
	var bag_total := 0
	for cell in bags:
		if not _coord(cell) or data.grid[cell.y][cell.x] != Types.Tile.FLOOR: return false
		if not _integer(bags[cell], Types.GOLD_BAG_CAPACITY): return false
		bag_total += bags[cell]
	if bag_total > data.gold: return false
	if data.get("lesson") == Types.Lesson.INVOKER_OFFER and (data.gold != 0 or not bags.is_empty()): return false
	if data.get("lesson") == Types.Lesson.VILLAGE_GIFT:
		if bags.size() >= Types.VILLAGE_BAG_COUNT or data.gold != bags.size() * Types.GOLD_BAG_CAPACITY or data.gold != bag_total: return false
	var balances = data.get("vault_gold", {})
	if not balances is Dictionary or balances.size() > Types.COLS * Types.ROWS:
		return false
	var locks = data.get("vault_locks", {})
	var opened = data.get("vault_opened", {})
	if not locks is Dictionary or not opened is Dictionary or locks.size() > Types.COLS * Types.ROWS or opened.size() > locks.size():
		return false
	for pos in locks:
		if not _coord(pos) or data.grid[pos.y][pos.x] != Types.Tile.VAULT or not locks[pos] is int or locks[pos] not in [1, 2]:
			return false
	for pos in opened:
		if not locks.has(pos) or not opened[pos] is bool:
			return false
	if not balances.is_empty():
		var layout := DungeonSim.new()
		layout.grid = data.grid
		layout.vault_locks = locks
		var limits := layout.vault_capacities()
		var stored := 0
		for pos in balances:
			if not _coord(pos) or not limits.has(pos) or not _integer(balances[pos], limits[pos]):
				return false
			stored += int(balances[pos])
		if stored + bag_total > data.gold:
			return false
	for field in ["door_hp", "door_opened", "trap_charges", "kingdom_knowledge"]:
		if not data[field] is Dictionary or data[field].size() > Types.COLS * Types.ROWS:
			return false
		for pos in data[field]:
			if not _coord(pos):
				return false
			var value = data[field][pos]
			var tile: int = data.grid[pos.y][pos.x]
			match field:
				"door_hp", "door_opened":
					if not Types.is_door_tile(tile):
						return false
					if field == "door_hp" and not _integer(value, Types.door_max_hp(tile)):
						return false
					if field == "door_opened" and not value is bool:
						return false
				"trap_charges":
					if tile not in [Types.Tile.SPIKE, Types.Tile.SNARE, Types.Tile.VOID]:
						return false
					if not _integer(value, 1 if tile == Types.Tile.VOID else Types.TRAP_MAX_CHARGES):
						return false
				"kingdom_knowledge":
					if not _tile(value):
						return false
	for field in ["loot_bags", "corpses"]:
		if not data[field] is Array or data[field].size() > MAX_RECORDS:
			return false
		for record in data[field]:
			var keys := ["pos", "gold", "taken"] if field == "loot_bags" else ["pos", "name", "fear"]
			# Optional presentation metadata; existing three-field corpses still load.
			if field == "corpses" and record is Dictionary:
				if record.has("kind"):
					keys.append("kind")
					if record.kind not in ["thief","paladin","ranger","mage",""]: return false
				if record.has("facing"):
					keys.append("facing")
					if record.facing not in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]: return false
			if not _keys(record, keys) or not _coord(record.pos):
				return false
			if field == "loot_bags":
				if not _integer(record.gold) or not record.taken is bool:
					return false
			else:
				if not record.name is String or record.name.length() > 1024:
					return false
				if not (record.fear is float or record.fear is int):
					return false
				if not is_finite(float(record.fear)) or record.fear < 0 or record.fear > MAX_VALUE:
					return false
	return true
