extends SceneTree

func _init() -> void:
	if not ResourceLoader.exists("res://scripts/mobile/mobile_build.gd"):
		push_error("Mobile build commands missing")
		quit(1)
		return
	var commands = load("res://scripts/mobile/mobile_build.gd").new()
	var sim := DungeonSim.new()
	var raid := RaidDirector.new()
	raid.sim = sim
	sim.raid = raid
	sim.new_map()
	var profile = load("res://scripts/game/core_progression.gd").new()
	var before := sim.grid.duplicate(true)
	assert(commands.preview(sim, profile, GameTypes.Tool.NONE, Vector2i(6, 6)).valid)
	assert(sim.grid == before)
	assert(commands.commit(sim, profile, GameTypes.Tool.NONE, Vector2i(6, 6)))
	assert(sim._has_core())
	var money := sim.gold
	var preview: Dictionary = commands.preview(sim, profile, GameTypes.Tool.DIG, Vector2i(4, 6))
	assert(preview.valid and preview.cost == 5)
	assert(sim.gold == money and sim.grid[6][4] == GameTypes.Tile.ROCK)
	assert(commands.commit(sim, profile, GameTypes.Tool.DIG, Vector2i(4, 6)))
	assert(sim.gold == money - 5)
	assert(not commands.preview(sim, profile, GameTypes.Tool.TRAP_SNARE, Vector2i(5, 6)).valid)
	var saved_profile: Dictionary = profile.snapshot()
	profile.set("testing_unlock_defenses", true)
	for defense in [GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID, GameTypes.Tool.BUILD_MAGIC_DOOR]:
		assert(profile.allows(defense), "Testing mode unlocks all defenses at level one")
	assert(commands.preview(sim, profile, GameTypes.Tool.TRAP_VOID, Vector2i(5, 6)).cost == GameTypes.COST_VOID)
	assert(commands.commit(sim, profile, GameTypes.Tool.TRAP_VOID, Vector2i(5, 6)))
	assert(profile.snapshot() == saved_profile, "Test unlock must not change saved progression")
	assert(not profile.allows(-1) and not profile.allows(GameTypes.Tool.size()))
	profile.set("testing_unlock_defenses", false)
	assert(not profile.allows(GameTypes.Tool.TRAP_VOID))
	var entrance_sim := DungeonSim.new()
	entrance_sim.new_map()
	var center := Vector2i(8, 8)
	for p in [center, center + Vector2i.LEFT, center + Vector2i.RIGHT, center + Vector2i.UP, center + Vector2i.DOWN]:
		entrance_sim.grid[p.y][p.x] = GameTypes.Tile.FLOOR
	assert(entrance_sim._wall_entrance_face(Vector2i(6, 8)) == Vector2i.ZERO)
	entrance_sim._place_entrance(center)
	assert(entrance_sim.grid[center.y][center.x] == GameTypes.Tile.FLOOR, "reject entrance placed in an open room center")
	assert(entrance_sim._wall_entrance_face(center) == Vector2i.ZERO, "open room has no wall-backed entrance face")
	# Old direct fixtures can still choose a walkable legacy mouth without wall backing.
	assert(entrance_sim._entrance_mouth(center) in GameTypes.DIRS, "legacy entrance mouth fallback remains cardinal")
	var wall_entrance := Vector2i(4, 4)
	entrance_sim.grid[wall_entrance.y][wall_entrance.x] = GameTypes.Tile.FLOOR
	entrance_sim.grid[wall_entrance.y][wall_entrance.x - 1] = GameTypes.Tile.ROCK
	entrance_sim.grid[wall_entrance.y][wall_entrance.x + 1] = GameTypes.Tile.FLOOR
	assert(entrance_sim._wall_entrance_face(wall_entrance) == Vector2i.RIGHT)
	assert(entrance_sim._entrance_mouth(wall_entrance) == Vector2i.RIGHT, "valid wall-facing direction takes precedence")
	entrance_sim._place_entrance(wall_entrance)
	assert(entrance_sim.grid[wall_entrance.y][wall_entrance.x] == GameTypes.Tile.ENTRANCE)
	var support_rock := wall_entrance + Vector2i.LEFT
	var gold_before_support_dig: int = entrance_sim.gold
	entrance_sim._try_dig(support_rock)
	assert(entrance_sim.grid[support_rock.y][support_rock.x] == GameTypes.Tile.ROCK, "entrance backing rock is protected")
	assert(entrance_sim.gold == gold_before_support_dig, "protecting entrance backing rock is free")
	raid.raid_active = true
	assert(not commands.commit(sim, profile, GameTypes.Tool.STORE, Vector2i(5, 6)))
	raid.raid_active = false
	sim.gold = 0
	var vault_preview: Dictionary = commands.preview(sim, profile, GameTypes.Tool.STORE, Vector2i(5, 6))
	assert(vault_preview.valid and vault_preview.cost == 0, "Vault placement is free even without gold")
	assert(commands.commit(sim, profile, GameTypes.Tool.STORE, Vector2i(5, 6)))
	assert(sim.gold == 0 and sim.grid[6][5] == GameTypes.Tile.VAULT)
	assert(not commands.commit(sim, profile, GameTypes.Tool.STORE, Vector2i(5, 6)), "Existing vault is unchanged")
	assert(not commands.preview(sim, profile, GameTypes.Tool.STORE, Vector2i(3, 6)).valid, "Free vaults still require excavated ground")
	assert(not commands.preview(sim, profile, GameTypes.Tool.STORE, Vector2i(6, 6)).valid, "Core remains protected")
	assert(not commands.preview(sim, profile, GameTypes.Tool.DIG, Vector2i(-1, 0)).valid)
	sim.raid = null
	raid.sim = null
	print("OK: preview isolation, validation, costs, locks and raid guard")
	quit()
