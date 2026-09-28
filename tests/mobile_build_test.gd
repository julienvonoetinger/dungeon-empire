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
	var preview: Dictionary = commands.preview(sim, profile, GameTypes.Tool.DIG, Vector2i(5, 6))
	assert(preview.valid and preview.cost == 5)
	assert(sim.gold == money and sim.grid[6][5] == GameTypes.Tile.ROCK)
	assert(commands.commit(sim, profile, GameTypes.Tool.DIG, Vector2i(5, 6)))
	assert(sim.gold == money - 5)
	assert(not commands.preview(sim, profile, GameTypes.Tool.TRAP_SNARE, Vector2i(5, 6)).valid)
	raid.raid_active = true
	assert(not commands.commit(sim, profile, GameTypes.Tool.STORE, Vector2i(5, 6)))
	raid.raid_active = false
	sim.gold = 0
	assert(not commands.commit(sim, profile, GameTypes.Tool.STORE, Vector2i(5, 6)))
	assert(not commands.preview(sim, profile, GameTypes.Tool.DIG, Vector2i(-1, 0)).valid)
	sim.raid = null
	raid.sim = null
	print("OK: preview isolation, validation, costs, locks and raid guard")
	quit()
