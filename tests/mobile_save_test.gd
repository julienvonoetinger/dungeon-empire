extends SceneTree

const Sim = preload("res://scripts/game/dungeon_sim.gd")
const Raid = preload("res://scripts/game/raid_director.gd")
const Progress = preload("res://scripts/game/core_progression.gd")
var failures := 0
var save_script
var sim = Sim.new()
var raid = Raid.new()
var progress = Progress.new()
var path := "user://mobile_save_test_%d.dat" % OS.get_process_id()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func reject(data: Dictionary, label: String) -> void:
	var before: Dictionary = save_script.capture(sim, raid, progress)
	raid.raid_active = true
	raid.hero = {"sentinel": 42}
	raid.raid_timer = 7.0
	check(not save_script.apply(data, sim, raid, progress), label + " rejected")
	check(save_script.capture(sim, raid, progress) == before, label + " no partial persistent mutation")
	check(raid.raid_active and raid.hero == {"sentinel": 42} and raid.raid_timer == 7.0, label + " no partial runtime mutation")

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/mobile/mobile_save.gd"):
		check(false, "MobileSave must exist")
		quit(1)
		return
	save_script = load("res://scripts/mobile/mobile_save.gd")
	sim.new_map()
	sim.grid[1][1] = GameTypes.Tile.DOOR
	sim.grid[1][2] = GameTypes.Tile.VOID
	sim.grid[1][3] = GameTypes.Tile.FLOOR
	sim.door_hp[Vector2i(1, 1)] = 23
	sim.door_opened[Vector2i(1, 1)] = false
	sim.trap_charges[Vector2i(2, 1)] = 0
	sim.loot_bags = [{"pos": Vector2i(3, 1), "gold": 91, "taken": false}]
	sim.corpses = [{"pos": Vector2i(3, 1), "name": "Hero", "fear": 18.0}]
	sim.gold = 456
	sim.core_hp = 72
	raid.kingdom_knowledge = {Vector2i(1, 1): GameTypes.Tile.DOOR}
	raid.raid_index = 8
	raid.mage_pressure = 3
	progress.restore({"xp": 170, "last_raid_id": 8})
	var original: Dictionary = save_script.capture(sim, raid, progress)
	check(original.version == 1, "versioned snapshot")
	check(original.get("mage_pressure") == 3, "snapshot captures nonzero mage pressure")
	var detached: Dictionary = original.duplicate(true)
	sim.grid[1][1] = GameTypes.Tile.FLOOR
	sim.loot_bags[0].gold = 1
	check(original == detached, "capture deep copies nested state")
	raid.raid_active = true
	raid.hero = {"pos": Vector2i(3, 1)}
	raid.raid_stats = {"killed": 1}
	raid.last_result = {"raid_id": 8}
	raid.raid_timer = 0.0
	check(save_script.apply(original, sim, raid, progress), "valid snapshot applied")
	check(raid.mage_pressure == 3, "restore preserves mage pressure after raid reset")
	check(save_script.capture(sim, raid, progress) == original, "all structures and profile round trip")
	check(not raid.raid_active and raid.hero.is_empty() and raid.raid_timer == GameTypes.RAID_DELAY, "restore preparation state")
	check(raid.raid_stats.is_empty() and raid.last_result.is_empty(), "clear previous raid results")
	check(progress.level() == 3 and progress.claim({"raid_id": 8}).is_empty(), "profile unlocks and reward idempotence survive")
	detached = original.duplicate(true)
	check(save_script.apply(detached, sim, raid, progress), "apply detached fixture")
	detached.grid[1][1] = GameTypes.Tile.ROCK
	detached.corpses[0].fear = 0.0
	check(save_script.capture(sim, raid, progress) == original, "apply does not alias input")
	var defeated := original.duplicate(true)
	defeated.core_hp = 0
	defeated.game_over = true
	defeated.door_hp[Vector2i(1, 1)] = 0
	defeated.door_opened[Vector2i(1, 1)] = true
	defeated.loot_bags[0].taken = true
	check(save_script.apply(defeated, sim, raid, progress), "defeated snapshot accepted")
	check(save_script.capture(sim, raid, progress) == defeated, "defeat and consumed structures preserved")
	check(save_script.apply(original, sim, raid, progress), "restore initial fixture")
	var valid_sim = Sim.new()
	var valid_raid = Raid.new()
	var valid_progress = Progress.new()
	valid_sim.new_map()
	var valid_entrance := Vector2i(4, 4)
	valid_sim.grid[4][4] = GameTypes.Tile.ENTRANCE
	valid_sim.grid[4][5] = GameTypes.Tile.FLOOR
	valid_raid.kingdom_knowledge = {valid_entrance: GameTypes.Tile.ENTRANCE}
	var valid_before: Dictionary = save_script.capture(valid_sim, valid_raid, valid_progress)
	check(save_script.apply(valid_before, valid_sim, valid_raid, valid_progress), "already valid entrance snapshot applies")
	check(valid_sim.repair_entrance_placement().is_empty(), "valid entrance requires no migration")
	check(save_script.capture(valid_sim, valid_raid, valid_progress) == valid_before, "valid save migration is a no-op")
	var legacy_sim = Sim.new()
	var legacy_raid = Raid.new()
	var legacy_progress = Progress.new()
	legacy_sim.new_map()
	var old_entrance := Vector2i(8, 8)
	for p in [old_entrance, old_entrance + Vector2i.LEFT, old_entrance + Vector2i.RIGHT,
			old_entrance + Vector2i.UP, old_entrance + Vector2i.DOWN,
			old_entrance + Vector2i(-1, -1), old_entrance + Vector2i(1, -1),
			old_entrance + Vector2i(-1, 1), old_entrance + Vector2i(1, 1)]:
		legacy_sim.grid[p.y][p.x] = GameTypes.Tile.FLOOR
	legacy_sim.grid[old_entrance.y][old_entrance.x] = GameTypes.Tile.ENTRANCE
	legacy_sim.grid[7][7] = GameTypes.Tile.VAULT
	legacy_sim.grid[8][9] = GameTypes.Tile.SPIKE
	legacy_sim.trap_charges[Vector2i(9, 8)] = 2
	legacy_sim.gold = 321
	legacy_sim.core_hp = 77
	legacy_sim.loot_bags = [{"pos": Vector2i(9, 9), "gold": 23, "taken": false}]
	legacy_sim.corpses = [{"pos": Vector2i(9, 9), "name": "Legacy", "fear": 12.0}]
	legacy_raid.kingdom_knowledge = {old_entrance: GameTypes.Tile.ENTRANCE,
		Vector2i(8, 7): GameTypes.Tile.FLOOR, Vector2i(8, 9): GameTypes.Tile.FLOOR,
		Vector2i(7, 8): GameTypes.Tile.FLOOR, Vector2i(9, 8): GameTypes.Tile.FLOOR,
		Vector2i(10, 10): GameTypes.Tile.ROCK}
	legacy_raid.raid_index = 12
	legacy_progress.restore({"xp": 245, "last_raid_id": 12})
	var legacy_snapshot: Dictionary = save_script.capture(legacy_sim, legacy_raid, legacy_progress)
	check(save_script.apply(legacy_snapshot, legacy_sim, legacy_raid, legacy_progress), "legacy center entrance snapshot accepted")
	var repaired_entrance: Vector2i = legacy_sim._find_tile(GameTypes.Tile.ENTRANCE)
	check(repaired_entrance != old_entrance and absi(repaired_entrance.x - old_entrance.x) + absi(repaired_entrance.y - old_entrance.y) == 1,
		"legacy center entrance migrates to nearest connected wall opening")
	check(legacy_sim.grid[old_entrance.y][old_entrance.x] == GameTypes.Tile.FLOOR, "old entrance cell becomes floor")
	check(legacy_sim._wall_entrance_face(repaired_entrance) != Vector2i.ZERO, "migrated entrance has valid backing and approach")
	check(not legacy_raid.kingdom_knowledge.has(old_entrance) and not legacy_raid.kingdom_knowledge.has(repaired_entrance),
		"migration clears knowledge of old and new entrance cells")
	check(legacy_raid.kingdom_knowledge.has(Vector2i(10, 10)), "migration preserves unrelated map knowledge")
	check(legacy_sim.grid[7][7] == GameTypes.Tile.VAULT and legacy_sim.grid[8][9] == GameTypes.Tile.SPIKE
		and legacy_sim.trap_charges[Vector2i(9, 8)] == 2, "migration preserves other structures and trap state")
	check(legacy_sim.gold == 321 and legacy_sim.core_hp == 77 and legacy_sim.loot_bags[0].gold == 23
		and legacy_sim.corpses[0].name == "Legacy", "migration preserves economy and world contents")
	check(legacy_progress.snapshot() == {"xp": 245, "last_raid_id": 12} and legacy_raid.raid_index == 12,
		"migration preserves profile and progression")
	var migrated_snapshot: Dictionary = save_script.capture(legacy_sim, legacy_raid, legacy_progress)
	check(save_script.apply(migrated_snapshot, legacy_sim, legacy_raid, legacy_progress), "migrated save can be loaded again")
	check(save_script.capture(legacy_sim, legacy_raid, legacy_progress) == migrated_snapshot,
		"entrance migration is idempotent")
	var no_candidate_sim = Sim.new()
	var no_candidate_raid = Raid.new()
	var no_candidate_progress = Progress.new()
	no_candidate_sim.new_map()
	no_candidate_sim.grid[8][8] = GameTypes.Tile.ENTRANCE
	no_candidate_sim.raid = no_candidate_raid
	no_candidate_raid.sim = no_candidate_sim
	no_candidate_raid.kingdom_knowledge = {Vector2i(8, 8): GameTypes.Tile.ENTRANCE}
	var no_candidate: Dictionary = no_candidate_sim.repair_entrance_placement()
	check(no_candidate.get("from") == Vector2i(8, 8) and no_candidate.get("to") == Vector2i(-1, -1),
		"migration reports removal when no connected wall opening exists")
	check(no_candidate_sim.grid[8][8] == GameTypes.Tile.FLOOR, "migration frees invalid entrance cell")
	no_candidate_sim.grid[8][8] = GameTypes.Tile.ENTRANCE
	no_candidate_raid.kingdom_knowledge = {Vector2i(8, 8): GameTypes.Tile.ENTRANCE}
	var no_candidate_snapshot: Dictionary = save_script.capture(no_candidate_sim, no_candidate_raid, no_candidate_progress)
	check(save_script.apply(no_candidate_snapshot, no_candidate_sim, no_candidate_raid, no_candidate_progress),
		"save migration accepts an entrance with no replacement opening")
	check(no_candidate_sim.grid[8][8] == GameTypes.Tile.FLOOR and not no_candidate_raid.kingdom_knowledge.has(Vector2i(8, 8)),
		"save migration frees invalid entrance cell and invalidates its knowledge")
	for field in original:
		var missing := original.duplicate(true)
		missing.erase(field)
		reject(missing, "missing " + field)
	for field in ["version", "gold", "core_hp", "raid_index", "mage_pressure", "game_over", "grid", "door_hp", "door_opened", "trap_charges", "loot_bags", "corpses", "kingdom_knowledge", "progression"]:
		var wrong := original.duplicate(true)
		wrong[field] = "invalid"
		reject(wrong, "wrong type " + field)
	for version in [0, 2]:
		var wrong := original.duplicate(true)
		wrong.version = version
		reject(wrong, "unsupported version")
	for coords in [Vector2i(-1, 1), Vector2i(16, 1), Vector2i(1, 16), Vector2(1, 1), "1,1"]:
		for field in ["door_hp", "door_opened", "trap_charges", "kingdom_knowledge"]:
			var wrong := original.duplicate(true)
			wrong[field] = {coords: 1}
			reject(wrong, "malformed coordinate " + field)
		for field in ["loot_bags", "corpses"]:
			var wrong := original.duplicate(true)
			wrong[field][0].pos = coords
			reject(wrong, "malformed position " + field)
	var wrong := original.duplicate(true)
	for pressure in [-1, 2147483648, 3.0, INF, NAN, true]:
		wrong = original.duplicate(true)
		wrong.mage_pressure = pressure
		reject(wrong, "invalid mage pressure")
	wrong = original.duplicate(true)
	wrong.grid.pop_back()
	reject(wrong, "grid height")
	wrong = original.duplicate(true)
	wrong.grid[0].pop_back()
	reject(wrong, "grid width")
	for tile in [-1, 10, 1.0, null]:
		wrong = original.duplicate(true)
		wrong.grid[0][0] = tile
		reject(wrong, "tile enum")
	for field in ["gold", "core_hp", "raid_index"]:
		wrong = original.duplicate(true)
		wrong[field] = -1
		reject(wrong, "negative " + field)
	wrong = original.duplicate(true)
	wrong.core_hp = 101
	reject(wrong, "core bound")
	wrong = original.duplicate(true)
	wrong.door_hp[Vector2i(1, 1)] = 61
	reject(wrong, "door HP bound")
	wrong = original.duplicate(true)
	wrong.trap_charges[Vector2i(2, 1)] = 2
	reject(wrong, "void charge bound")
	wrong = original.duplicate(true)
	wrong.door_opened[Vector2i(1, 1)] = 1
	reject(wrong, "door opened bool")
	wrong = original.duplicate(true)
	wrong.door_hp[Vector2i.ZERO] = 10
	reject(wrong, "door on rock")
	wrong = original.duplicate(true)
	wrong.corpses[0].fear = NAN
	reject(wrong, "nonfinite fear")
	wrong = original.duplicate(true)
	wrong.loot_bags[0].gold = -1
	reject(wrong, "negative loot")
	wrong = original.duplicate(true)
	wrong.progression.xp = -1
	reject(wrong, "invalid profile")
	wrong = original.duplicate(true)
	wrong.extra = RefCounted.new()
	reject(wrong, "object payload")
	check(save_script.read_save(path).is_empty(), "missing file is empty")
	check(save_script.write_save(path, original), "first atomic write")
	check(save_script.read_save(path) == original, "binary Vector2i roundtrip")
	raid.mage_pressure = 0
	check(save_script.apply(save_script.read_save(path), sim, raid, progress) and raid.mage_pressure == 3, "nonzero mage pressure survives disk roundtrip")
	var newer := original.duplicate(true)
	newer.gold = 999
	check(save_script.write_save(path, newer), "replacement write")
	check(save_script.read_save(path) == newer, "new save replaces old")
	check(not save_script.write_save(path, wrong), "invalid write rejected")
	check(save_script.read_save(path) == newer, "invalid write preserves save")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_8(255)
	file.close()
	check(save_script.read_save(path) == original, "corrupt primary recovers previous backup")
	DirAccess.remove_absolute(path)
	check(save_script.read_save(path) == original, "missing primary recovers backup")
	DirAccess.remove_absolute(path + ".bak")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_32(999999)
	file.store_8(0)
	file.close()
	check(save_script.read_save(path).is_empty(), "truncated payload rejected")
	file = FileAccess.open(path, FileAccess.WRITE)
	newer.version = 2
	file.store_var(newer, false)
	file.close()
	check(save_script.read_save(path).is_empty(), "on-disk future version rejected")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(["wrong root"], false)
	file.close()
	check(save_script.read_save(path).is_empty(), "non-dictionary encoded payload rejected")
	check(not save_script.write_save(path + "/missing/save.dat", original), "unwritable destination returns false")
	check(not save_script.write_save("", original), "empty destination rejected")
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	no_candidate_sim.raid = null
	no_candidate_raid.sim = null
	valid_sim = null
	valid_raid = null
	valid_progress = null
	legacy_sim = null
	legacy_raid = null
	legacy_progress = null
	no_candidate_sim = null
	no_candidate_raid = null
	no_candidate_progress = null
	print("mobile_save_test: %d failures" % failures)
	quit(1 if failures else 0)
