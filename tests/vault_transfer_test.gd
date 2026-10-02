extends SceneTree

func _init() -> void:
	var sim := DungeonSim.new()
	var raid := RaidDirector.new()
	sim.raid = raid
	raid.sim = sim
	sim.new_map()
	var a := Vector2i(3, 3)
	var b := Vector2i(4, 3)
	sim.grid[a.y][a.x] = GameTypes.Tile.VAULT
	sim.grid[b.y][b.x] = GameTypes.Tile.VAULT
	sim.gold = 120
	assert(sim.transfer_gold(a, b, 45) == 45)
	assert(sim.gold == 120)
	assert(sim._storage_state().vaults == {a: 75, b: 45})
	assert(sim.transfer_gold(a, b, 999) == 75)
	assert(sim.transfer_gold(a, b, 1) == 0)
	assert(sim.transfer_gold(b, b, 1) == 0)
	assert(sim.transfer_gold(b, a, -1) == 0)
	assert(sim.transfer_gold(b, Vector2i(-1, 0), 1) == 0)
	raid.raid_active = true
	assert(sim.transfer_gold(b, a, 20) == 0)
	raid.raid_active = false
	sim.game_over = true
	assert(sim.transfer_gold(b, a, 20) == 0)
	sim.game_over = false
	var profile = preload("res://scripts/game/core_progression.gd").new()
	var save = preload("res://scripts/mobile/mobile_save.gd")
	var data: Dictionary = save.capture(sim, raid, profile)
	var restored := DungeonSim.new()
	assert(save.apply(data, restored, raid, profile))
	assert(restored._storage_state().vaults == {a: 0, b: 120})
	assert(restored.withdraw_vault_gold(b, 40) == 40)
	assert(restored._storage_state().vaults == {a: 0, b: 80})
	assert(restored.gold == 80)
	restored.gold -= 15
	assert(restored._storage_state().vaults[b] == 65)
	assert(restored._deposit_gold(200) == 200)
	assert(restored.transfer_gold(a, b, 999) == 35)
	assert(restored._storage_state().vaults == {a: 115, b: 150})
	assert(restored.transfer_gold(a, b, 1) == 0, "Full destination rejects transfer")
	raid.sim = restored
	raid.hero = {"ignored": {}, "display": "Test thief", "steal_capacity": 999, "stolen_gold": 0, "carried_gold": 0}
	raid.raid_stats = {"stolen": 0}
	raid._try_rob_vault(b)
	assert(restored._storage_state().vaults == {a: 115, b: 0}, "Theft debits the visited vault, not the first vault")
	assert(restored.gold == 115 and raid.hero.carried_gold == 150)
	restored.grid[b.y][b.x] = GameTypes.Tile.FLOOR
	assert(not restored._storage_state().vaults.has(b))
	data.erase("vault_gold")
	assert(save.apply(data, restored, raid, profile), "Legacy saves remain supported")
	assert(restored._storage_state().vaults == {a: 120, b: 0})
	data["vault_gold"] = {a: 151}
	assert(not save.apply(data, restored, raid, profile))
	sim.new_map()
	assert(sim.vault_gold.is_empty())
	sim.raid = null
	raid.sim = null
	print("OK: transfers, limits, guards, targeted theft, spending and save migration")
	quit()
