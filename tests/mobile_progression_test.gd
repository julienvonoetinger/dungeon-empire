extends SceneTree

func _initialize() -> void:
	var path := "res://scripts/game/core_progression.gd"
	if not ResourceLoader.exists(path):
		printerr("FAIL: Core progression is missing")
		quit(1)
		return
	var progress = load(path).new()
	assert(not progress.allows(GameTypes.Tool.TRAP_SNARE))
	var result := {"raid_id": 1, "core_hp": 100, "killed": 1, "carried_out": 0, "traps_spent": 9, "core_lost": 0}
	var reward: Dictionary = progress.claim(result)
	assert(reward.xp == 25 and reward.gold == 0)
	assert(progress.level() == 1 and not progress.allows(GameTypes.Tool.TRAP_SNARE))
	assert(progress.claim(result).is_empty())
	assert(progress.xp == 25)
	result.raid_id = 2
	result.killed = 2
	progress.claim(result)
	assert(progress.xp == 75 and progress.level() == 2 and progress.allows(GameTypes.Tool.TRAP_SNARE))
	result.raid_id = 3
	result.killed = 0
	reward = progress.claim(result)
	assert(reward.xp == 0 and progress.xp == 75, "Intact Core, protected gold and triggered traps award no passive XP")
	assert(progress.claim(result).is_empty(), "Zero-reward raids are recorded too")
	result.raid_id = 4
	result.core_hp = 0
	result.killed = 0
	result.carried_out = 20
	result.traps_spent = 0
	result.core_lost = 100
	reward = progress.claim(result)
	assert(reward.xp == 0 and reward.gold == 0)
	var restored = load(path).new()
	assert(restored.restore(progress.snapshot()))
	assert(restored.xp == progress.xp and restored.claim(result).is_empty())
	assert(not restored.restore({"xp": -1, "last_raid_id": 0}))
	assert(restored.restore({"xp": 2075, "last_raid_id": 10}), "Existing XP remains valid")
	assert(restored.xp == 2075 and restored.level() == 4)
	result.raid_id = 5
	result.killed = 3
	reward = progress.claim(result)
	assert(reward.xp == 75 and progress.level() == 3 and progress.allows(GameTypes.Tool.TRAP_VOID))
	print("OK: kill-only XP, levels, locks, defeat, persistence and duplicate protection")
	quit()
