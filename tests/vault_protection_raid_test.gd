extends SceneTree

var failures := 0

func _initialize() -> void:
	var probe := DungeonSim.new()
	if probe.get("vault_locks") == null or probe.get("vault_opened") == null or not probe.has_method("vault_protected"):
		printerr("RED: DungeonSim vault protection API is not present yet")
		quit(1)
		return
	_test_locked_thief_success_and_next_raid()
	_test_locked_thief_fails_twice()
	_test_fleeing_thief_does_not_lockpick_remotely()
	_test_magic_and_empty_vaults()
	_test_magic_only_treasure_completes_without_theft()
	_test_mage_dissipates_magic_lock()
	print("Vault protection raid test: %d failures" % failures)
	quit(1 if failures else 0)

func _fixture(kind: String, tier: int, balance: int = 90) -> RaidDirector:
	var sim := DungeonSim.new()
	sim.new_map()
	var vault := Vector2i(8, 7)
	for x in range(5, 10):
		sim.grid[7][x] = GameTypes.Tile.FLOOR
	sim.grid[7][4] = GameTypes.Tile.ENTRANCE
	sim.grid[vault.y][vault.x] = GameTypes.Tile.VAULT
	sim.vault_gold[vault] = balance
	var locks: Dictionary = sim.get("vault_locks")
	var opened: Dictionary = sim.get("vault_opened")
	locks[vault] = tier
	opened[vault] = false
	sim.gold = balance
	var raid := RaidDirector.new()
	raid.sim = sim
	raid._start_raid()
	raid.hero.merge({
		"kind": kind,
		"pos": Vector2i(7, 7),
		"objective": "vault" if kind == "thief" else "core",
		"hp": 100,
		"max_hp": 100,
		"patience": 1000,
		"flee_ratio": 0.01,
		"steal_capacity": 90,
		"fear_weight": 0.0,
		"trap_weight": 1.0,
		"visited": {},
		"bias": {},
		"known": {vault: GameTypes.Tile.VAULT},
		"lockpick_success_chance": 1.0
	}, true)
	for y in sim.grid.size():
		for x in sim.grid[y].size():
			raid.hero.known[Vector2i(x, y)] = sim.grid[y][x]
	return raid

func _test_locked_thief_success_and_next_raid() -> void:
	var raid := _fixture("thief", 1)
	var vault := Vector2i(8, 7)
	_check(_protected(raid, vault), "tier-1 vault begins protected")
	raid.hero.pos = vault
	raid.hero["vault_arrival_t"] = RaidDirector.TURN_TIME
	raid._update_hero(RaidDirector.TURN_TIME - 0.01)
	_check(not raid.hero.get("lockpicking", false), "lockpick waits for the chest arrival animation")
	raid._update_hero(0.02)
	_check(raid.hero.get("lockpicking", false), "thief must begin the existing lockpick action")
	_check(is_equal_approx(float(raid.hero.get("lockpick_t", 0.0)), 3.0333333), "vault lockpick reuses door animation duration")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 90, "locked vault is not robbed during lockpick")
	_check(not raid.hero.get("collecting_gold", false) and int(raid.hero.get("stolen_gold", 0)) == 0, "locked chest contents are never collected before unlock")
	raid._update_hero(3.04)
	_check(_opened(raid, vault) and not _protected(raid, vault), "successful pick permanently unlocks vault")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 90, "unlock does not bypass the existing theft action")
	raid._update_hero(0.13)
	_check(raid.hero.get("collecting_gold", false), "thief can steal after unlocking")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 90, "full-bag collection keeps gold until its action completes")
	var next_raid := RaidDirector.new()
	next_raid.sim = raid.sim
	var other_vault := Vector2i(8, 8)
	raid.sim.grid[other_vault.y][other_vault.x] = GameTypes.Tile.VAULT
	raid.sim.vault_gold[other_vault] = 60
	raid.sim.gold = 150
	next_raid._start_raid()
	next_raid.hero.merge({"kind": "thief", "pos": vault, "stolen_gold": 0, "steal_capacity": 150,
		"carried_gold": 0, "ignored": {}, "fleeing": false}, true)
	next_raid._try_rob_vault(vault)
	_check(not next_raid.hero.get("lockpicking", false), "unlocked status persists and skips lockpick in the next raid")
	_check(int(next_raid.hero.get("stolen_gold", 0)) == 90, "later thief can rob the already-open vault")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 0, "later raid debits the opened vault balance")
	_check(_opened(raid, vault), "opened status remains persistent")
	raid.sim.raid = null
	next_raid.sim = null

func _test_locked_thief_fails_twice() -> void:
	var raid := _fixture("thief", 1)
	var vault := Vector2i(8, 7)
	raid.hero.level = 3
	raid.hero.lockpick_success_chance = 0.0
	raid.hero.pos = vault
	raid._resolve_cell(vault)
	_check(raid.hero.get("lockpicking", false), "first failed-pick fixture starts lockpicking")
	raid._update_hero(3.04)
	_check(raid.hero.get("lockpicking", false), "first failed attempt gets exactly one retry")
	_check(not raid.hero.get("ignored", {}).has(vault), "vault remains eligible during the retry")
	raid._update_hero(3.04)
	_check(not raid.hero.get("lockpicking", false), "second failed attempt stops lockpicking")
	_check(raid.hero.get("ignored", {}).get(vault, false), "twice-failed vault is ignored for the raid")
	_check(not _opened(raid, vault), "failed picks never open vault")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 90, "failed picks never take gold")
	var starts := int(raid.hero.get("lockpick_attempts", {}).get(vault, 0))
	for i in 3:
		raid._try_rob_vault(vault)
	_check(int(raid.hero.get("lockpick_attempts", {}).get(vault, 0)) == starts, "revisits do not restart failed lockpicks")
	raid.sim.raid = null

func _test_fleeing_thief_does_not_lockpick_remotely() -> void:
	var raid := _fixture("thief", 1)
	var vault := Vector2i(8, 7)
	raid.hero.level = 3
	raid.hero.pos = vault
	raid.hero.fleeing = true
	raid.hero.lockpick_success_chance = 0.0
	raid._update_hero(0.1)
	_check(not raid.hero.get("lockpicking", false), "fleeing thief never starts a new vault lockpick")
	_check(raid.hero.pos != vault, "fleeing thief leaves the vault and walks toward the entrance")
	_check(int(raid.hero.get("stolen_gold", 0)) == 0 and int(raid.sim._storage_state().vaults.get(vault, 0)) == 90,
		"fleeing thief takes no gold from a protected vault")
	_advance_until_finished(raid, 80)
	_check(not raid.raid_active, "fleeing thief can finish the raid after abandoning the failed vault")
	_check(int(raid.hero.get("stolen_gold", 0)) == 0 and int(raid.sim._storage_state().vaults.get(vault, 0)) == 90,
		"completed failed-pick raid preserves all vault gold")
	raid.sim.raid = null

func _test_magic_and_empty_vaults() -> void:
	var magic := _fixture("thief", 2)
	var vault := Vector2i(8, 7)
	magic.hero.pos = vault
	magic._resolve_cell(vault)
	_check(not magic.hero.get("lockpicking", false), "thief cannot pick a magic vault")
	_check(magic.hero.get("ignored", {}).get(vault, false), "thief ignores magic vault instead of looping")
	_check(int(magic.sim._storage_state().vaults.get(vault, 0)) == 90, "magic vault remains unrobbed")
	_check(not magic.hero.get("collecting_gold", false) and int(magic.hero.get("stolen_gold", 0)) == 0, "magic chest contents are never collected")
	magic.hero.pos = Vector2i(7, 7)
	var through := magic._route_step(magic.hero, {Vector2i(9, 7): true})
	_check(through == vault, "ignored magic vault stays traversable on the route to the far side")
	magic.mage_pressure = 1
	magic._record_magic_door_escape()
	_check(magic.mage_pressure == 2, "abandoning a magic vault applies existing magic-door escape pressure")
	var mage_standard := _fixture("mage", 1)
	mage_standard.hero.pos = Vector2i(8, 7)
	mage_standard._resolve_cell(Vector2i(8, 7))
	_check(not mage_standard.hero.get("arcane_opening", false), "mage leaves a standard tier-1 vault sealed")
	_check(not _opened(mage_standard, Vector2i(8, 7)), "mage does not mark tier-1 vault opened")
	var empty := _fixture("thief", 0, 0)
	empty.hero.pos = Vector2i(8, 7)
	empty._resolve_cell(Vector2i(8, 7))
	_check(empty.hero.get("ignored", {}).get(Vector2i(8, 7), false), "empty vault is ignored")
	_check(not empty.hero.get("collecting_gold", false), "empty vault never starts collection")
	_check(int(empty.hero.get("stolen_gold", 0)) == 0, "empty vault gives no gold")
	magic.sim.raid = null
	mage_standard.sim.raid = null
	empty.sim.raid = null

func _test_mage_dissipates_magic_lock() -> void:
	var raid := _fixture("mage", 2)
	var vault := Vector2i(8, 7)
	raid.hero.pos = vault
	raid.hero["vault_arrival_t"] = 0.48
	raid._update_hero(0.47)
	_check(not raid.hero.get("arcane_opening", false), "mage waits for the chest arrival animation")
	raid._update_hero(0.48)
	_check(raid.hero.get("arcane_opening", false), "mage arrival at a magic vault starts delayed arcane action")
	_check(not _opened(raid, vault), "magic lock remains until arcane timer completes")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 90, "mage never steals vault contents")
	raid._update_hero(1.51)
	_check(_opened(raid, vault), "mage dissipates tier-2 lock on arrival")
	_check(int(raid.sim._storage_state().vaults.get(vault, 0)) == 90, "dissipating lock does not transfer gold")
	_check(raid.mage_pressure == 0, "mage dissipation clears magic pressure like a magic door")
	raid.sim.raid = null

func _test_magic_only_treasure_completes_without_theft() -> void:
	var raid := _fixture("thief", 2)
	var vault := Vector2i(8, 7)
	for i in 80:
		if raid.hero.get("ignored", {}).get(vault, false):
			break
		raid._update_hero(0.5)
	_check(raid.hero.get("ignored", {}).get(vault, false), "magic-only objective is marked ignored for the raid")
	_advance_until_finished(raid, 80)
	_check(not raid.raid_active, "thief eventually exits when the only treasure is behind a magic seal")
	_check(int(raid.raid_stats.get("stolen", 0)) == 0 and int(raid.sim._storage_state().vaults.get(vault, 0)) == 90,
		"completed magic-only raid steals no vault gold")
	raid.sim.raid = null

func _advance_until_finished(raid: RaidDirector, max_steps: int) -> void:
	for i in max_steps:
		if not raid.raid_active:
			return
		raid._update_hero(0.5)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _opened(raid: RaidDirector, cell: Vector2i) -> bool:
	var opened: Dictionary = raid.sim.get("vault_opened")
	return bool(opened.get(cell, false))

func _protected(raid: RaidDirector, cell: Vector2i) -> bool:
	return bool(raid.sim.call("vault_protected", cell))
