extends SceneTree

func _init() -> void:
	var original = ProjectSettings.get_setting("testing/vulpin_only", false)
	var raid := RaidDirector.new()
	var sim := DungeonSim.new()
	raid.sim = sim
	sim.new_map()
	sim.grid[3][3] = GameTypes.Tile.ENTRANCE
	sim.grid[3][4] = GameTypes.Tile.FLOOR
	ProjectSettings.set_setting("testing/vulpin_only", true)
	raid.mage_pressure = 100
	for index in 100:
		raid._start_raid()
		assert(raid.hero.kind == "thief", "Only Vulpin may spawn in test mode")
		assert(raid.hero.objective == "vault")
	assert(raid.mage_pressure == 100, "Test override preserves mage pressure")
	ProjectSettings.set_setting("testing/vulpin_only", false)
	var kinds := {}
	seed(42)
	for index in 500:
		kinds[raid._random_hero_template().kind] = true
	assert(kinds.size() == 4, "Disabling test mode restores all heroes")
	ProjectSettings.set_setting("testing/vulpin_only", original)
	raid.sim = null
	print("OK: 100 Vulpin raids, mage-pressure guard and normal roster restored")
	quit()
