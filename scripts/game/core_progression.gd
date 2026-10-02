class_name CoreProgression
extends RefCounted

const THRESHOLDS := [0, 60, 150, 280]
const REQUIRED_LEVEL := {
	GameTypes.Tool.TRAP_SNARE: 2,
	GameTypes.Tool.TRAP_VOID: 3,
	GameTypes.Tool.BUILD_MAGIC_DOOR: 4,
}
var xp := 0
var last_raid_id := 0
# Runtime-only playtest override; never persisted in progression saves.
var testing_unlock_defenses := false

func level() -> int:
	var value := 1
	for threshold in THRESHOLDS.slice(1):
		if xp >= threshold:
			value += 1
	return value

func allows(tool: int) -> bool:
	return tool >= 0 and tool < GameTypes.Tool.size() and (testing_unlock_defenses or level() >= required_level(tool))

func required_level(tool: int) -> int:
	return int(REQUIRED_LEVEL.get(tool, 1))

func next_threshold() -> int:
	return THRESHOLDS[level()] if level() < THRESHOLDS.size() else THRESHOLDS[-1]

func claim(result: Dictionary) -> Dictionary:
	var id := int(result.get("raid_id", 0))
	if id <= last_raid_id:
		return {}
	var before := level()
	var survived := int(result.get("core_hp", 0)) > 0
	var killed := int(result.get("killed", 0)) > 0
	var protected_gold := int(result.get("carried_out", 0)) == 0
	var intact := int(result.get("core_lost", 0)) == 0
	var earned := (20 if survived else 0) + (25 if killed else 0)
	earned += (10 if protected_gold else 0) + (10 if intact else 0)
	earned += clampi(int(result.get("traps_spent", 0)), 0, 3) * 5
	var gold := (30 if survived else 0) + (25 if killed else 0) + (15 if protected_gold else 0)
	xp += earned
	last_raid_id = id
	return {"xp": earned, "gold": gold, "before_level": before, "level": level()}

func snapshot() -> Dictionary:
	return {"xp": xp, "last_raid_id": last_raid_id}

func restore(data: Dictionary) -> bool:
	if not data.get("xp") is int or not data.get("last_raid_id") is int:
		return false
	if data.xp < 0 or data.last_raid_id < 0:
		return false
	xp = data.xp
	last_raid_id = data.last_raid_id
	return true
