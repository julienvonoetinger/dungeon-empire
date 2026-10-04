extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var sim := DungeonSim.new()
	sim.new_map()
	sim.grid[1][1] = GameTypes.Tile.ENTRANCE
	var raid := RaidDirector.new()
	raid.sim = sim
	if raid.get("roster") == null:
		check(false, "RaidDirector must own the persistent roster")
		quit(1)
		return
	ProjectSettings.set_setting("testing/vulpin_only", true)
	raid._start_raid()
	var first: Dictionary = raid.hero.duplicate(true)
	var id: int = first.id
	check(first.level == 1, "recruits start at level one")
	raid.roster.profiles[id].xp = 150
	raid.hero.hp = 1
	raid.hero.lockpick_attempts = {Vector2i(2, 1): 5}
	raid.hero.lockpicking = true
	raid.hero.lockpick_success_chance = 0.0
	raid.raid_stats.escaped = 1
	raid._end_raid("test survivor")
	raid._start_raid()
	check(raid.hero.id != id, "only last visitor available means new recruit")
	var second_id: int = raid.hero.id
	var second: Dictionary = raid.roster.profiles[second_id].duplicate(true)
	var rng := RandomNumberGenerator.new()
	var returns := 0
	var recruits := 0
	for n in 200:
		rng.seed = n
		var selected: Dictionary = raid.roster.select_return(0, true, rng)
		if selected.is_empty():
			recruits += 1
		else:
			returns += 1
			check(selected.id == id and selected.kind == "thief", "return excludes previous identity")
	check(returns > 60 and recruits > 60, "both 50-percent branches exercised")
	raid.raid_stats.escaped = 1
	raid._end_raid("second survivor")
	# Restrict the roster to the first survivor and search deterministic global seeds.
	raid.roster.profiles.erase(second_id)
	var returned := false
	for n in 100:
		seed(n)
		raid.roster.previous_id = second_id
		raid._start_raid()
		if raid.hero.id == id:
			returned = true
			break
		raid.roster.profiles.erase(raid.hero.id)
	check(returned and raid.hero.level == 3 and raid.hero.name == first.name, "same identity returns with earned level")
	check(raid.hero.hp == first.max_hp and raid.hero.trait == first.trait, "return heals but retains personality")
	check(not raid.hero.has("lockpick_attempts") and not raid.hero.has("lockpicking") and not raid.hero.has("lockpick_success_chance"), "transient state is never retained")
	check(raid.hero.door_damage == first.door_damage and raid.hero.steal_capacity == first.steal_capacity, "base rolls remain stable")
	# A non-thief survivor cannot leak through the manual Vulpin-only filter.
	second.kind = "mage"
	raid.roster.profiles[second_id] = second
	raid.roster.previous_id = id
	for n in 20:
		rng.seed = n
		check(raid.roster.select_return(50, true, rng).is_empty(), "Vulpin-only filters existing profiles")
	raid.roster.previous_id = 0
	var mage_returns := 0
	var thief_returns := 0
	for n in 1000:
		rng.seed = n
		var selected: Dictionary = raid.roster.select_return(9, false, rng)
		if not selected.is_empty():
			if selected.kind == "mage":
				mage_returns += 1
			else:
				thief_returns += 1
	check(mage_returns > thief_returns * 4 and thief_returns > 0, "mage pressure weights return classes without removing other candidates")
	sim.grid[1][1] = GameTypes.Tile.FLOOR
	var before: Dictionary = raid.roster.snapshot()
	raid._start_raid()
	check(before == raid.roster.snapshot(), "no entrance means no identity mutation")
	print("Hero return failures: ", failures)
	quit(1 if failures else 0)
