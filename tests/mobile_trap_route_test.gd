extends SceneTree

var failures := 0

func _initialize() -> void:
	for direction in GameTypes.DIRS:
		for kind in ["thief", "ranger"]:
			_test_junction(direction, kind)
	_test_straight()
	_test_two_traps()
	print("Trap route test: %d failures" % failures)
	quit(1 if failures else 0)

func _fixture(direction: Vector2i, turn: bool, kind: String) -> RaidDirector:
	var sim := DungeonSim.new()
	sim.new_map()
	var raid := RaidDirector.new()
	raid.sim = sim
	raid.solid_core = true
	var start := Vector2i(7, 7)
	var trap := start + direction
	var side := Vector2i(-direction.y, direction.x)
	var goal := trap + side if turn else start + direction * 3
	for p in [start, trap, start + direction * 2, goal]:
		sim.grid[p.y][p.x] = GameTypes.Tile.FLOOR
	var entrance := start - direction
	sim.grid[entrance.y][entrance.x] = GameTypes.Tile.ENTRANCE
	sim.grid[trap.y][trap.x] = GameTypes.Tile.SNARE
	sim.trap_charges[trap] = 3
	sim.grid[goal.y][goal.x] = GameTypes.Tile.VAULT
	sim.gold = 100
	raid._start_raid()
	raid.hero.merge({"kind": kind, "pos": start, "objective": "vault", "hp": 100, "max_hp": 100,
		"patience": 1000, "flee_ratio": 0.01, "steal_capacity": 100, "fear_weight": 0.0,
		"trap_weight": 1.0, "visited": {}, "bias": {}, "known": {}}, true)
	for y in sim.grid.size():
		for x in sim.grid[y].size():
			raid.hero.known[Vector2i(x, y)] = sim.grid[y][x]
	return raid

func _test_junction(direction: Vector2i, kind: String) -> void:
	var raid := _fixture(direction, true, kind)
	var goal := raid.sim._find_tile(GameTypes.Tile.VAULT)
	var trace: Array[Vector2i] = []
	for i in 160:
		if raid.hero.is_empty() or raid.hero.get("collecting_gold", false):
			break
		raid._update_hero(0.1)
		if not raid.hero.is_empty() and (trace.is_empty() or trace.back() != raid.hero.pos):
			trace.append(raid.hero.pos)
		if raid.hero.get("pos", Vector2i(-1, -1)) == goal:
			break
	var arrived: bool = raid.hero.get("pos", Vector2i(-1, -1)) == goal
	print(kind, " junction ", direction, " path=", trace)
	if not arrived or trace.size() > 3:
		failures += 1
		printerr("FAIL: hero must turn on trapped junction instead of jumping back and forth")
	if kind == "thief" and int(raid.sim.trap_charges[raid.sim._find_tile(GameTypes.Tile.SNARE)]) != 2:
		failures += 1
		printerr("FAIL: Vulpin must trigger the junction trap through normal arrival")

func _test_straight() -> void:
	var raid := _fixture(Vector2i.RIGHT, false, "ranger")
	raid._update_hero(0.1)
	if not raid.hero.get("jumping_trap", false) or raid.hero.pos != Vector2i(9, 7):
		failures += 1
		printerr("FAIL: useful straight-line jump must remain available")
	if int(raid.sim.trap_charges[Vector2i(8, 7)]) != 3:
		failures += 1
		printerr("FAIL: jumping must not spend the avoided trap")
	raid._route_step(raid.hero, {})
	if raid.hero.has("route_second_step"):
		failures += 1
		printerr("FAIL: failed route must clear old jump intent")

func _test_two_traps() -> void:
	var raid := _fixture(Vector2i.RIGHT, true, "ranger")
	var second_trap := Vector2i(8, 8)
	var goal := Vector2i(8, 9)
	raid.sim.grid[8][8] = GameTypes.Tile.SNARE
	raid.sim.trap_charges[second_trap] = 3
	raid.sim.grid[9][8] = GameTypes.Tile.VAULT
	raid.hero.known[second_trap] = GameTypes.Tile.SNARE
	raid.hero.known[goal] = GameTypes.Tile.VAULT
	for i in 200:
		raid._update_hero(0.1)
		if raid.hero.get("pos", Vector2i.ZERO) == goal and not raid.hero.get("jumping_trap", false):
			break
	if raid.hero.get("pos", Vector2i.ZERO) != goal or raid.hero.get("collecting_gold", false):
		failures += 1
		printerr("FAIL: ranger must reach treasure beyond two traps and a turn")
	if raid.sim.trap_charges[Vector2i(8, 7)] != 2 or raid.sim.trap_charges[second_trap] != 3:
		failures += 1
		printerr("FAIL: unavoidable turning trap triggers; straight second trap is jumped")
