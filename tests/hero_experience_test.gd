extends SceneTree

const Roster = preload("res://scripts/game/hero_roster.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fixture() -> RaidDirector:
	var raid := RaidDirector.new()
	raid.sim = DungeonSim.new()
	raid.sim.new_map()
	raid.sim.grid[1][1] = GameTypes.Tile.ENTRANCE
	raid._start_raid()
	return raid

func finish_at_entrance(raid: RaidDirector) -> void:
	# This suite isolates XP accounting; real return routes have their own probes.
	raid.hero.pos = Vector2i(1, 1)
	raid._hero_escapes()
	raid._update_hero(GameTypes.TURN_TIME + 0.01)

func _initialize() -> void:
	ProjectSettings.set_setting("testing/vulpin_only", true)
	var api = Roster.new()
	if not api.has_method("experience_breakdown"):
		check(false, "Expedition XP is missing")
		quit(1)
		return
	var ledger := {"acquired_gold": 150, "locks": {Vector2i(2, 1): true}, "obstacles": {}, "core_damage": 0, "discoveries": {}}
	check(api.call("experience_breakdown", ledger).total == 55, "approved 150 gold plus lock example")
	ledger.acquired_gold = 4
	check(api.call("experience_breakdown", ledger).gold == 0, "gold rounds down")
	ledger.acquired_gold = 5
	check(api.call("experience_breakdown", ledger).gold == 1, "five gold earns one XP")
	ledger.obstacles[Vector2i(2, 1)] = true
	check(api.call("experience_breakdown", ledger).total == 26, "one obstacle cannot reward twice")
	var raid := fixture()
	var id: int = raid.hero.id
	var door := Vector2i(2, 1)
	raid.sim.grid[1][2] = GameTypes.Tile.DOOR
	raid.sim.door_hp[door] = 60
	raid.hero.lockpick_success_chance = 1.0
	raid._attack_door(door)
	check(raid.roster.profiles[id].xp == 0, "animation start does not grant XP")
	raid._update_hero(3.04)
	raid._resolve_vulpin_lockpick(door)
	raid.hero.pos = door
	raid.sim.loot_bags = [{"pos": door, "gold": 150, "taken": false}]
	raid._pick_up_loot(door)
	# The private observation loop is exercised separately below.
	raid._begin_retreat("success")
	check(raid.roster.profiles[id].xp == 0, "return must complete before awards")
	finish_at_entrance(raid)
	check(raid.roster.profiles[id].xp == 55, "real successful lock and acquired bag recorded once")
	check(raid.last_result.hero_level_after == 2 and raid.last_result.hero_xp_gained == 55, "result exposes advancement")
	raid._finish_departure()
	check(raid.roster.profiles[id].xp == 55, "duplicate completion cannot award again")
	_test_discovery()
	_test_outcomes()
	_test_actions()
	_test_failures_and_magic_chest()
	print("Hero experience failures: ", failures)
	quit(1 if failures else 0)

func _test_discovery() -> void:
	var raid := fixture()
	var id: int = raid.hero.id
	raid.hero.pos = Vector2i(5, 5)
	for y in GameTypes.ROWS:
		for x in GameTypes.COLS:
			raid.hero.known[Vector2i(x, y)] = raid.sim.grid[y][x]
	raid._remember_nearby(raid.hero)
	raid._remember_nearby(raid.hero)
	raid._begin_retreat("explored")
	finish_at_entrance(raid)
	check(raid.roster.profiles[id].xp == 30, "twenty discovery XP cap plus survival")
	check(raid.roster.profiles[id].discovered.size() == 25, "overflow discoveries retained")
	var ledger := {"discoveries": {}, "locks": {}, "obstacles": {}, "acquired_gold": 0, "core_damage": 0}
	check(raid.roster.finish(id, true, ledger).hero_xp_gained == 10, "no discovery credit for shared memory alone")
	# The same personal observation on a later raid is not a fresh discovery.
	var profile: Dictionary = raid.roster.profiles[id]
	raid._start_raid()
	raid.hero.id = id
	raid.hero.pos = Vector2i(5, 5)
	raid.hero.kind = profile.kind
	raid._remember_nearby(raid.hero)
	check(raid.hero.xp_ledger.discoveries.is_empty(), "revisits cannot farm capped overflow")

func _test_outcomes() -> void:
	var raid := fixture()
	var id: int = raid.hero.id
	raid._banish_via_void()
	raid._update_hero(raid.portal_hold + 0.01)
	check(raid.roster.profiles.has(id) and raid.roster.profiles[id].xp == 10, "void is a living exit; starting gold gives no XP")
	raid = fixture()
	id = raid.hero.id
	raid.hero.xp_ledger.acquired_gold = 100
	raid.hero.hp = 0
	raid._kill_hero()
	check(not raid.roster.profiles.has(id), "death permanently removes profile")
	check(raid.last_result.hero_xp_gained == 0, "death discards expedition XP")
	raid = fixture()
	id = raid.hero.id
	raid._end_raid("aborted")
	check(raid.roster.profiles[id].xp == 0, "abort is not survival")

func _test_actions() -> void:
	var raid := fixture()
	var id: int = raid.hero.id
	var vault := Vector2i(2, 1)
	raid.sim.grid[1][2] = GameTypes.Tile.VAULT
	raid.sim.vault_gold[vault] = 50
	raid.sim.gold = 50
	raid.hero.steal_capacity = 50
	raid._try_rob_vault(vault)
	check(raid.hero.xp_ledger.acquired_gold == 0, "pending theft earns nothing")
	raid._update_hero(GameTypes.VULPIN_COLLECT_HOLD + 0.01)
	finish_at_entrance(raid)
	check(raid.roster.profiles[id].xp == 20, "delayed theft awarded at departure")
	raid = fixture()
	var door := Vector2i(2, 1)
	raid.sim.grid[1][2] = GameTypes.Tile.DOOR
	raid.sim.door_hp[door] = 60
	raid.hero.door_damage = 100
	raid._apply_door_damage(door)
	raid._apply_door_damage(door)
	raid.sim.grid[1][3] = GameTypes.Tile.MAGIC_DOOR
	raid.sim.door_hp[Vector2i(3, 1)] = 60
	raid._resolve_mage_arcane_open(Vector2i(3, 1))
	raid._resolve_mage_arcane_open(Vector2i(3, 1))
	raid.sim.core_hp = 50
	raid._apply_core_damage(5)
	raid._begin_retreat("core strike")
	finish_at_entrance(raid)
	check(raid.last_result.hero_xp_gained == 45, "obstacles once each plus actual five core HP")

func _test_failures_and_magic_chest() -> void:
	var raid := fixture()
	var door := Vector2i(2, 1)
	raid.sim.grid[1][2] = GameTypes.Tile.DOOR
	raid.sim.door_hp[door] = 60
	raid.hero.lockpick_success_chance = 0.0
	raid._attack_door(door)
	raid._update_hero(3.04)
	check(raid.hero.xp_ledger.locks.is_empty(), "failed lockpick has no XP")
	var vault := Vector2i(3, 1)
	raid.sim.grid[1][3] = GameTypes.Tile.VAULT
	raid.sim.vault_gold[vault] = 0
	raid.sim.gold = 0
	raid._try_rob_vault(vault)
	check(raid.hero.xp_ledger.acquired_gold == 0 and not raid.hero.get("collecting_gold", false), "empty chest is not a reward")
	raid.sim.vault_locks[vault] = 2
	raid._resolve_mage_arcane_open(vault)
	raid._resolve_mage_arcane_open(vault)
	raid._begin_retreat("seal")
	finish_at_entrance(raid)
	check(raid.last_result.hero_xp_gained == 25, "magic chest seal rewards one success, no gold")
	raid = fixture()
	var id: int = raid.hero.id
	raid.hero.hp = 0
	raid._resolve_cell(raid.hero.pos)
	check(raid.roster.profiles.has(id) and raid.roster.profiles[id].xp == 0, "dying animation has not yet completed")
	raid._update_hero(2.0)
	check(not raid.roster.profiles.has(id) and raid.last_result.hero_xp_gained == 0, "delayed Vulpin death permanently removes individual")
