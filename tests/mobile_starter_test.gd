extends SceneTree

const Sim = preload("res://scripts/game/dungeon_sim.gd")
const Raid = preload("res://scripts/game/raid_director.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func reachable(sim, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in GameTypes.DIRS:
			var next: Vector2i = cell + direction
			if not seen.has(next) and sim._can_step(cell, next):
				seen[next] = true
				pending.append(next)
	return seen

func _initialize() -> void:
	var path := "res://scripts/mobile/mobile_starter.gd"
	if not ResourceLoader.exists(path):
		check(false, "MobileStarter must exist")
		quit(1)
		return
	var starter = load(path)
	var sim = Sim.new()
	var raid = Raid.new()
	sim.new_map()
	sim.game_over = true
	sim.core_hp = 0
	sim.door_hp[Vector2i.ZERO] = 1
	sim.door_opened[Vector2i.ZERO] = true
	sim.trap_charges[Vector2i.ZERO] = 0
	sim.corpses = [{"pos": Vector2i.ZERO}]
	sim.loot_bags = [{"pos": Vector2i.ZERO}]
	raid.raid_index = 19
	raid.raid_active = true
	raid.hero = {"old": true}
	raid.kingdom_knowledge = {Vector2i.ZERO: GameTypes.Tile.ROCK}
	starter.populate(sim, raid)
	check(raid.raid_index == 19, "population preserves monotonic raid index")
	check(not raid.raid_active and raid.hero.is_empty() and raid.raid_timer == GameTypes.RAID_DELAY, "fresh preparation state")
	check(raid.kingdom_knowledge.is_empty(), "old map knowledge cleared")
	check(sim.gold == 140 and sim.core_hp == GameTypes.CORE_MAX and not sim.game_over, "starter economy and health")
	check(sim.loot_bags.is_empty() and sim.corpses.is_empty(), "old debris cleared")
	check(sim.door_hp.is_empty() and sim.door_opened.is_empty(), "no invalid starter doors")
	check(sim._core_origin() == Vector2i(6, 6), "Core anchored at 6,6")
	var core_count := 0
	var entrance_count := 0
	var spikes := 0
	var open_count := 0
	check(sim.grid.size() == 16, "16 rows")
	for y in range(16):
		check(sim.grid[y].size() == 16, "16 columns")
		for x in range(16):
			var tile: int = sim.grid[y][x]
			var pos := Vector2i(x, y)
			if x < 2 or y < 2 or x >= 14 or y >= 14:
				check(tile == GameTypes.Tile.ROCK, "two-cell outer rock border")
			if tile != GameTypes.Tile.ROCK:
				open_count += 1
			if tile == GameTypes.Tile.CORE:
				core_count += 1
				check(x in [6, 7] and y in [6, 7], "Core is 2x2")
			if tile == GameTypes.Tile.ENTRANCE:
				entrance_count += 1
				check(x < 6 and y > 7, "entrance in lower-left room")
			if tile == GameTypes.Tile.SPIKE:
				spikes += 1
				check(x > 8 and y < 6, "spikes in upper-right room")
				check(sim.trap_charges.get(pos) == 3, "spike fully charged")
			check(tile not in [GameTypes.Tile.SNARE, GameTypes.Tile.VOID, GameTypes.Tile.DOOR, GameTypes.Tile.MAGIC_DOOR], "level-one starter structures only")
	check(core_count == 4 and entrance_count == 1 and spikes == 2, "starter tile counts")
	check(open_count == 45, "compact authored 45-tile layout")
	check(sim.trap_charges.size() == 2, "no stale trap state")
	var vaults: Array[Vector2i] = sim._vault_positions()
	check(vaults.size() == 2 and sim._storage_capacity() == 300, "two vaults provide 300 capacity")
	for pos in vaults:
		check(pos.x < 6 and pos.y < 6, "vaults in upper-left room")
	check(sim._has_required_storage(), "ready to run raid with secured gold")
	var entrance: Vector2i = sim._find_tile(GameTypes.Tile.ENTRANCE)
	check(entrance == Vector2i(2, 10), "starter entrance is mounted at the backed wall opening")
	check(sim._wall_entrance_face(entrance) == Vector2i.RIGHT, "starter entrance faces into its accessible room")
	check(sim.grid[entrance.y][entrance.x - 1] == GameTypes.Tile.ROCK, "starter entrance has solid backing")
	check(sim._entrance_mouth(entrance) == Vector2i.RIGHT, "starter stair mouth faces into the room")
	var seen := reachable(sim, entrance)
	check(seen.size() == open_count, "all rooms reachable using actual entrance stepping rules")
	check(seen.has(Vector2i(6, 6)), "entrance reaches Core")
	for pos in vaults:
		check(seen.has(pos), "entrance reaches vault")
	# These rock strips separate the chambers; a large open rectangle fails.
	for pos in [Vector2i(5, 3), Vector2i(7, 4), Vector2i(9, 4), Vector2i(9, 7), Vector2i(5, 10)]:
		check(sim.grid[pos.y][pos.x] == GameTypes.Tile.ROCK, "room partitions remain rock")
	var layout: Array = sim.grid.duplicate(true)
	raid._start_raid()
	check(raid.raid_active and raid.raid_index == 20 and not raid.hero.is_empty(), "real RaidDirector can start next raid")
	check(raid.hero.get("pos") == entrance, "hero spawns at authored entrance")
	starter.populate(sim, raid)
	check(raid.raid_index == 20 and sim.grid == layout, "repeat population deterministic without resetting raid IDs")
	sim.raid = null
	raid.sim = null
	print("mobile_starter_test: %d failures" % failures)
	quit(1 if failures else 0)
