extends SceneTree

const Save = preload("res://scripts/mobile/mobile_save.gd")
const Roster = preload("res://scripts/game/hero_roster.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	ProjectSettings.set_setting("testing/vulpin_only", true)
	var sim := DungeonSim.new()
	sim.new_map()
	sim.grid[1][1] = GameTypes.Tile.ENTRANCE
	var raid := RaidDirector.new()
	raid.sim = sim
	var progress := CoreProgression.new()
	raid._start_raid()
	var id: int = raid.hero.id
	raid.roster.profiles[id].xp = 150
	raid.roster.profiles[id].discovered[Vector2i(1, 1)] = true
	var saved: Dictionary = Save.capture(sim, raid, progress)
	if not saved.has("hero_roster"):
		check(false, "Save must include the hero roster")
		quit(1)
		return
	check(Save.apply(saved, sim, raid, progress), "roster-bearing save accepted")
	check(raid.roster.profiles[id].xp == 150 and raid.roster.previous_id == id, "XP and last visitor restored")
	check(not raid.raid_active and raid.hero.is_empty(), "reload preparation, not transient actions")
	for value in [-1, "150", null]:
		var bad: Dictionary = saved.duplicate(true)
		bad.hero_roster.profiles[id].xp = value
		var before: Dictionary = Save.capture(sim, raid, progress)
		check(not Save.apply(bad, sim, raid, progress), "reject invalid profile XP")
		check(before == Save.capture(sim, raid, progress), "invalid roster never mutates simulation")
	for pair in [["steal_capacity", 1], ["patience", 185], ["fear_weight", -0.75], ["greed", 0.1], ["trap_weight", 2.15]]:
		var bad: Dictionary = saved.duplicate(true)
		bad.hero_roster.profiles[id].stats[pair[0]] = pair[1]
		var before: Dictionary = Save.capture(sim, raid, progress)
		check(not Save.apply(bad, sim, raid, progress), "reject class-incompatible %s" % pair[0])
		check(before == Save.capture(sim, raid, progress), "class-incompatible stats reject atomically")
	var path := "user://hero_roster_test_%d.save" % OS.get_process_id()
	check(Save.write_save(path, saved), "roster writes to isolated save")
	check(Save.read_save(path) == saved, "disk round trip")
	DirAccess.remove_absolute(path)
	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("hero_roster")
	check(Save.apply(legacy, sim, raid, progress) and raid.roster.profiles.is_empty(), "legacy save starts empty roster")
	check(Save.apply(saved, sim, raid, progress), "restore before restart")
	# Completed deaths survive a disk snapshot; previous_id may point at the dead hero.
	raid.roster.profiles.erase(id)
	var dead_save: Dictionary = Save.capture(sim, raid, progress)
	check(Save.apply(dead_save, sim, raid, progress) and not raid.roster.profiles.has(id), "dead individual does not resurrect on reload")
	check(raid.roster.previous_id == id, "previous visitor can be a dead ID")
	raid.reset_for_new_map()
	check(raid.roster.profiles.is_empty() and raid.roster.previous_id == 0, "new dungeon resets visitors")
	# Real recruitment rolls across every class must all remain saveable.
	ProjectSettings.set_setting("testing/vulpin_only", false)
	for n in 800:
		seed(n)
		raid.roster.reset()
		raid._start_raid()
		check(Roster.valid_snapshot(raid.roster.snapshot()), "valid rolled profile seed %d" % n)
	print("Hero roster save failures: ", failures)
	quit(1 if failures else 0)
