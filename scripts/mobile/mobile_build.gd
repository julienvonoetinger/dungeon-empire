class_name MobileBuild
extends RefCounted

const FIELDS := ["grid", "gold", "core_hp", "door_hp", "door_opened", "trap_charges", "loot_bags", "corpses", "game_over"]

func preview(sim: DungeonSim, profile, tool: int, cell: Vector2i) -> Dictionary:
	if sim.game_over or (sim.raid != null and sim.raid.raid_active):
		return {"valid": false, "cost": 0, "reason": "Construction unavailable"}
	if not sim._inside(cell) or not profile.allows(tool):
		return {"valid": false, "cost": 0, "reason": "Requires Core level %d" % profile.required_level(tool)}
	var copy := DungeonSim.new()
	for field in FIELDS:
		var value = sim.get(field)
		copy.set(field, value.duplicate(true) if value is Array or value is Dictionary else value)
	_apply(copy, tool, cell)
	var changed := false
	for field in FIELDS:
		if copy.get(field) != sim.get(field):
			changed = true
	return {"valid": changed, "cost": maxi(0, sim.gold - copy.gold), "reason": copy.message}

func commit(sim: DungeonSim, profile, tool: int, cell: Vector2i) -> bool:
	var check := preview(sim, profile, tool, cell)
	if not check.valid:
		sim.message = check.reason
		return false
	_apply(sim, tool, cell)
	return true

func _apply(sim: DungeonSim, tool: int, cell: Vector2i) -> void:
	if not sim._has_core():
		sim._place_core(cell)
		return
	if tool == GameTypes.Tool.REPAIR:
		sim._repair_structures()
		return
	if tool == GameTypes.Tool.ABSORB:
		for corpse in sim.corpses:
			if corpse.pos == cell:
				sim.corpses.erase(corpse)
				sim.core_hp = mini(GameTypes.CORE_MAX, sim.core_hp + 2)
				return
		return
	# Selecting a structure must never silently dig the target rock.
	if sim.grid[cell.y][cell.x] == GameTypes.Tile.ROCK and tool != GameTypes.Tool.DIG:
		sim.message = "Excavate this tile first"
		return
	sim.selected_tool = tool
	sim._build_at(cell)
