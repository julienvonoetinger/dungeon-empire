extends SceneTree

const Starter = preload("res://scripts/mobile/mobile_starter.gd")
const Save = preload("res://scripts/mobile/mobile_save.gd")
const Progress = preload("res://scripts/game/core_progression.gd")
var failures := 0
var kinds := {}

func check(condition: bool, text: String) -> void:
	if not condition:
		failures += 1
		push_error(text)

func _initialize() -> void:
	ProjectSettings.set_setting("testing/vulpin_only", false)
	var sim := DungeonSim.new()
	var raid := RaidDirector.new()
	var progress := Progress.new()
	for index in 20:
		seed(1000 + index)
		Starter.populate(sim, raid)
		raid.raid_index = progress.last_raid_id
		var preparation := Save.capture(sim, raid, progress)
		check(Save._valid(preparation), "Preparation serializes")
		raid._start_raid()
		kinds[raid.hero.kind] = true
		var turns := 0
		while raid.raid_active and turns < 5000:
			raid._update_hero(0.5)
			turns += 1
		check(not raid.raid_active, "Raid terminates without user input")
		check(not raid.last_result.is_empty(), "Real simulation emits result snapshot")
		var reward := progress.claim(raid.last_result)
		check(not reward.is_empty(), "Next real raid awards once")
		sim.gold += int(reward.get("gold", 0))
		sim._spill_overflow_at(sim._core_origin())
		var completed := Save.capture(sim, raid, progress)
		check(Save._valid(completed), "Completed real raid state serializes including loot and corpses")
		check(Save.apply(completed, sim, raid, progress), "Completed real raid state restores")
		check(not raid.raid_active and raid.hero.is_empty(), "Restore never resumes incomplete hero simulation")
		check(progress.claim(completed.merged({"raid_id": completed.raid_index})).is_empty(), "Restored profile refuses repeat receipt")
	check(kinds.size() == 4, "Deterministic suite covers all four hero classes")
	sim.raid = null
	raid.sim = null
	print("Mobile end-to-end: 20 complete raids, ", kinds.keys(), ", ", failures, " failures")
	quit(1 if failures else 0)
