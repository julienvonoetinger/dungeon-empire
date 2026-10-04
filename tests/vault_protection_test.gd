extends SceneTree

func _init() -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	assert(sim.has_method("build_vault"), "Chest protection construction is missing")
	var p := Vector2i(4, 4)
	var q := Vector2i(5, 4)
	sim.grid[p.y][p.x] = GameTypes.Tile.FLOOR
	sim.grid[q.y][q.x] = GameTypes.Tile.FLOOR
	assert(sim.call("build_vault", p, 0))
	assert(sim.gold == 320 and sim._storage_capacity() == 150)
	assert(sim.call("build_vault", q, 1))
	assert(sim.gold == 280 and sim.call("vault_protected", q))
	sim.vault_gold = {p: 150, q: 130}
	assert(sim.call("build_vault", q, 2))
	assert(sim.gold == 240 and sim._storage_state().vaults[q] == 130, "Upgrade does not relocate the chest balance")
	assert(not sim.call("build_vault", q, 1), "No downgrade")
	assert(not sim.call("build_vault", q, 2), "No repeated purchase")
	sim.get("vault_opened")[q] = true
	assert(not sim.call("vault_protected", q))
	assert(sim._damaged_structure_count() == 1, "An opened chest protection appears in the raid repair summary")
	assert(not sim.call("build_vault", q, 2), "Construction cannot relock for free")
	assert(sim.call("repair_vault", q))
	assert(sim.gold == 225 and sim.call("vault_protected", q))
	assert(not sim.call("repair_vault", q))
	assert(sim.transfer_gold(q, p, 10) == 10, "Protection never blocks owner transfers")
	var raid := RaidDirector.new()
	raid.sim = sim
	sim.raid = raid
	raid.raid_active = true
	assert(not sim.call("build_vault", p, 1))
	sim.get("vault_opened")[q] = true
	assert(not sim.call("repair_vault", q))
	raid.raid_active = false
	sim.game_over = true
	assert(not sim.call("build_vault", p, 1))
	assert(not sim.call("repair_vault", q))
	sim.game_over = false
	var profile := CoreProgression.new()
	profile.testing_unlock_defenses = true
	sim._place_core(Vector2i(10, 10))
	var commands := MobileBuild.new()
	var before := sim.vault_locks.duplicate(true)
	var before_gold := sim.gold
	var check := commands.preview(sim, profile, GameTypes.Tool.STORE_LOCKED, p)
	assert(check.valid and check.cost == 40)
	assert(sim.vault_locks == before and sim.gold == before_gold, "Preview must not purchase or change protection")
	assert(commands.commit(sim, profile, GameTypes.Tool.STORE_LOCKED, p))
	assert(sim.vault_protected(p) and sim.gold == before_gold - 40)
	sim.vault_locks.erase(p)
	var data := MobileSave.capture(sim, raid, profile)
	var restored := DungeonSim.new()
	assert(MobileSave.apply(data, restored, raid, profile))
	assert(restored.get("vault_locks") == {q: 2} and restored.get("vault_opened") == {q: true})
	for invalid in [{p: 3}, {Vector2i(-1, 0): 1}, {Vector2i(0, 0): 1}, {p: "1"}]:
		var bad := data.duplicate(true)
		bad.vault_locks = invalid
		assert(not MobileSave.apply(bad, restored, raid, profile))
	var orphan := data.duplicate(true)
	orphan.vault_opened = {p: true}
	assert(not MobileSave.apply(orphan, restored, raid, profile))
	data.erase("vault_locks")
	data.erase("vault_opened")
	assert(MobileSave.apply(data, restored, raid, profile), "Legacy standard chests load unchanged")
	assert(restored.get("vault_locks").is_empty() and restored.get("vault_opened").is_empty())
	sim.gold = 14
	assert(not sim.call("repair_vault", q))
	assert(not sim.call("build_vault", p, 1))
	sim._clear_cell_state(q)
	assert(not sim.get("vault_locks").has(q) and not sim.get("vault_opened").has(q))
	sim.new_map()
	assert(sim.get("vault_locks").is_empty() and sim.get("vault_opened").is_empty())
	sim.raid = null
	raid.sim = null
	print("OK: chest tiers, upgrades, costs, protection guards, transfers and backward-compatible saves")
	quit()
