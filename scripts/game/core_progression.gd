class_name CoreProgression
extends RefCounted

const THRESHOLDS := [0, 60, 150, 280]
const REQUIRED_LEVEL := {
	GameTypes.Tool.BUILD_DOOR: 2,
	GameTypes.Tool.TRAP_SPIKE: 3,
	GameTypes.Tool.TRAP_SNARE: 2,
	GameTypes.Tool.BUILD_REINFORCED_DOOR: 2,
	GameTypes.Tool.TRAP_VOID: 3,
	GameTypes.Tool.BUILD_MAGIC_DOOR: 4,
	GameTypes.Tool.STORE_MAGIC: 4,
}
var xp := 0
var invocation_xp := 0
var last_raid_id := 0
# The tutorial checkpoint persists this flag through GameplaySave.
var awaiting_miner := false
# Runtime-only playtest override; never persisted in progression saves.
var testing_unlock_defenses := false

func level() -> int:
	if awaiting_miner: return 0
	var value := 1
	for threshold in THRESHOLDS.slice(1):
		if xp - invocation_xp >= threshold:
			value += 1
	return value

func allows(tool: int) -> bool:
	return not awaiting_miner and tool >= 0 and tool < GameTypes.Tool.size() and (testing_unlock_defenses or level() >= required_level(tool))

func required_level(tool: int) -> int:
	return int(REQUIRED_LEVEL.get(tool, 1))

func next_threshold() -> int:
	return invocation_xp + (THRESHOLDS[level()] if level() < THRESHOLDS.size() else THRESHOLDS[-1])

func grant_tutorial_level(new_level: int) -> void:
	xp = maxi(xp, invocation_xp + THRESHOLDS[new_level-1])

func claim(result: Dictionary) -> Dictionary:
	var id := int(result.get("raid_id", 0))
	if id <= last_raid_id:
		return {}
	var before := level()
	var earned := maxi(0, int(result.get("killed", 0))) * 25
	xp += earned
	last_raid_id = id
	return {"xp": earned, "gold": 0, "before_level": before, "level": level()}

func snapshot() -> Dictionary:
	var data := {"xp": xp, "last_raid_id": last_raid_id}
	if invocation_xp > 0: data["invocation_xp"] = invocation_xp
	return data

func restore(data: Dictionary) -> bool:
	if not data.get("xp") is int or not data.get("last_raid_id") is int:
		return false
	if data.xp < 0 or data.last_raid_id < 0:
		return false
	var baseline: Variant = data.get("invocation_xp",0)
	if not baseline is int or baseline < 0 or baseline > data.xp: return false
	xp = data.xp
	invocation_xp = baseline
	last_raid_id = data.last_raid_id
	return true
