class_name IsometricGameSession
extends Node

## Rules restored from v1.0.0; this controller owns phases and player commands.
signal changed(structure: bool)
signal frame_updated
## Optional presentation feedback; no consumer is required by simulations.
signal presentation_event(kind: String)
const Types = preload("res://scripts/game/game_types.gd")
const Save = preload("res://scripts/game/gameplay_save.gd")
const SAVE_PATH := "user://isometric_run_v1.save"
var save_path := SAVE_PATH
## Set before entering the tree for isolated simulations; no disk reads or writes.
var persistence_enabled := true
const FIELDS := ["grid", "gold", "vault_gold", "vault_locks", "vault_opened", "core_hp", "door_hp", "door_opened", "trap_charges", "loot_bags", "corpses", "game_over"]
var sim := DungeonSim.new()
var raid := RaidDirector.new()
var progression := CoreProgression.new()
var paused := false
var confirmation_open := false
var catalog_open := false
var result_open := false
var tool: int = Types.Tool.NONE
var selected := Vector2i(-1, -1)
var preview: Dictionary = {}
var notice := ""
var save_error := ""
var save_blocked := false
var last_reward: Dictionary = {}
var raid_speed := 1
var _visual_state := 0
var _build_history: Array[Dictionary] = []

func _ready() -> void:
	# Explicit manual-review slot; never touches the player's current dungeon.
	if persistence_enabled and OS.get_cmdline_user_args().has("--forge-review"):
		save_path = "user://forge_review_v1.save"
		get_window().title = "Forge · Review"
	elif persistence_enabled and OS.get_cmdline_user_args().has("--review-session"):
		save_path = "user://isometric_review_v1.save"
		get_window().title = "Dungeon Empire · Review"
	sim.raid = raid
	raid.sim = sim
	raid.solid_core = true
	raid.raid_finished.connect(_raid_finished)
	sim.new_map()
	var data := Save.read_save(save_path) if persistence_enabled else {}
	if not data.is_empty() and Save.apply(data, sim, raid, progression):
		notice = "Dungeon restored. Preparation resumes."
	elif persistence_enabled and (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak")):
		save_blocked = true
		save_error = "The save could not be read. It has been kept. Start a new dungeon to play again."
	else:
		notice = "Place the Core, or try the demo dungeon."
	_visual_state = _structure_hash()
	changed.emit(true)

func phase() -> String:
	if sim.game_over: return "Defeat"
	if result_open: return "Results"
	if raid.raid_active: return "Raid"
	if not sim._has_core(): return "Core placement"
	return "Preparation"

func can_edit() -> bool:
	return not paused and not confirmation_open and not result_open and not raid.raid_active and not sim.game_over and not save_blocked

func ready_for_raid() -> bool:
	return sim._has_required_storage() and not sim.game_over and not save_blocked

func _process(delta: float) -> void:
	advance_simulation(delta)

## Shared by normal frame processing and fixed-step, UI-free scenario runners.
func advance_simulation(delta: float) -> void:
	if not paused and not confirmation_open and not result_open and not save_blocked and not sim.game_over:
		if raid.raid_active:
			# Fixed substeps preserve the existing step/timer bounds at 2x.
			for step in clampi(raid_speed,1,2):
				if raid.raid_active and not result_open: raid._update_hero(minf(delta, .1))
			var next := _structure_hash()
			if next != _visual_state:
				_visual_state = next
				changed.emit(true)
		elif ready_for_raid() and not catalog_open and tool == Types.Tool.NONE and selected.x < 0:
			raid.raid_timer = maxf(0, raid.raid_timer - minf(delta, .1))
			if raid.raid_timer <= 0: start_raid()
	frame_updated.emit()

func _structure_hash() -> int:
	var intact: Array = []
	for p in sim.door_hp:
		intact.append([p, sim._door_intact(p)])
	var protected_vaults: Array = []
	for p in sim._vault_positions():
		protected_vaults.append([p, sim.vault_protected(p)])
	return hash([sim.grid, intact, protected_vaults])

func choose_tool(value: int) -> void:
	if not can_edit(): return
	tool = value
	selected = Vector2i(-1, -1)
	preview = {}
	if progression.allows(value) and Types.fixed_tool_cost(value)>sim.gold: presentation_event.emit("fauche")
	changed.emit(false)

func select_cell(cell: Vector2i) -> void:
	if not can_edit() or not sim._inside(cell): return
	selected = cell
	preview = {}
	if not sim._has_core() or tool != Types.Tool.NONE:
		preview = check_action(cell)
	changed.emit(false)

func activate_cell(cell: Vector2i) -> void:
	if not can_edit() or not sim._inside(cell): return
	if tool == Types.Tool.NONE or not sim._has_core():
		select_cell(cell)
		return
	var action := check_action(cell)
	if not action.get("valid",false):
		notice = str(action.get("reason","Cannot place here."))
		report_rejected_action(cell)
		changed.emit(false)
		return
	selected = cell
	preview = action
	var tile: int = sim.grid[cell.y][cell.x]
	# Replacing/removing an existing object remains an explicit decision.
	if tile not in [Types.Tile.ROCK,Types.Tile.FLOOR] and tool != Types.Tool.REPAIR:
		changed.emit(false)
		return
	confirm_action()

func can_undo() -> bool:
	return can_edit() and not _build_history.is_empty()

func _build_snapshot() -> Dictionary:
	var state := {"knowledge":raid.kingdom_knowledge.duplicate(true),"timer":raid.raid_timer}
	for field in FIELDS:
		var value = sim.get(field)
		state[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	return state

func undo_build() -> void:
	if not can_undo(): return
	var state: Dictionary = _build_history.pop_back()
	for field in FIELDS: sim.set(field,state[field])
	raid.kingdom_knowledge = state.knowledge
	raid.raid_timer = state.timer
	notice = "Last build undone."
	_after_edit()

func cancel_selection() -> void:
	selected = Vector2i(-1, -1)
	tool = Types.Tool.NONE
	preview = {}
	changed.emit(false)

func check_action(cell: Vector2i, requested_tool: int = -1) -> Dictionary:
	if not can_edit() or not sim._inside(cell): return {"valid": false, "reason": "Action unavailable", "cost": 0}
	var action_tool := tool if requested_tool < 0 else requested_tool
	if sim._has_core() and not progression.allows(action_tool):
		return {"valid": false, "reason": "Core level %d required" % progression.required_level(action_tool), "cost": 0}
	var copy := DungeonSim.new()
	for field in FIELDS:
		var value = sim.get(field)
		copy.set(field, value.duplicate(true) if value is Array or value is Dictionary else value)
	_apply(copy, cell, action_tool)
	var modified := false
	for field in FIELDS:
		if copy.get(field) != sim.get(field): modified = true
	return {"valid": modified, "cost": maxi(0, sim.gold - copy.gold), "reason": copy.message}

func _apply(target: DungeonSim, cell: Vector2i, requested_tool: int = -1) -> void:
	var action_tool := tool if requested_tool < 0 else requested_tool
	if not target._has_core():
		target._place_core(cell)
		return
	if action_tool == Types.Tool.REPAIR:
		if target._is_door_tile(target.grid[cell.y][cell.x]): target.repair_door(cell)
		elif target._is_trap_tile(target.grid[cell.y][cell.x]): target.repair_trap(cell)
		else: target.repair_vault(cell)
		return
	if target.grid[cell.y][cell.x] == Types.Tile.ROCK and action_tool != Types.Tool.DIG:
		target.message = "Dig this tile before building."
		return
	target.selected_tool = action_tool
	target._build_at(cell)

func report_rejected_action(cell:Vector2i,requested_tool:int=-1) -> void:
	# An explicit failed attempt only. Try the same command on an isolated,
	# funded copy; this distinguishes money from geometry, level or full health.
	var action_tool:=tool if requested_tool<0 else requested_tool
	if not can_edit() or not sim._inside(cell) or not progression.allows(action_tool): return
	var copy:=DungeonSim.new()
	for field in FIELDS:
		var value=sim.get(field)
		copy.set(field,value.duplicate(true) if value is Array or value is Dictionary else value)
	copy.gold=1000000
	_apply(copy,cell,action_tool)
	if 1000000-copy.gold>sim.gold: presentation_event.emit("fauche")

func confirm_action() -> void:
	if selected.x < 0 or not can_edit(): return
	preview = check_action(selected)
	if not preview.valid:
		notice = str(preview.reason)
		report_rejected_action(selected)
		changed.emit(false)
		return
	if sim._has_core():
		_build_history.append(_build_snapshot())
		if _build_history.size() > 32: _build_history.pop_front()
	_apply(sim, selected)
	sim._storage_state()
	notice = "Action complete."
	presentation_event.emit("placed")
	_after_edit()

func _after_edit() -> void:
	selected = Vector2i(-1, -1)
	preview = {}
	_visual_state = _structure_hash()
	_save()
	changed.emit(true)

func collect_selected() -> void:
	if not can_edit() or selected.x < 0: return
	_build_history.clear()
	var total := 0
	for bag in sim.loot_bags:
		if bag.pos == selected:
			var amount := sim._deposit_gold(int(bag.gold))
			bag.gold -= amount
			total += amount
	sim.loot_bags = sim.loot_bags.filter(func(bag): return bag.gold > 0)
	notice = "%d gold collected (limited by chest capacity)." % total
	_after_edit()

func absorb_selected() -> void:
	if not can_edit() or selected.x < 0: return
	_build_history.clear()
	for corpse in sim.corpses:
		if corpse.pos == selected:
			sim.corpses.erase(corpse)
			sim.core_hp = mini(Types.CORE_MAX, sim.core_hp + 2)
			raid.invalidate_kingdom_knowledge(selected)
			notice = "Corpse absorbed: +2 Core HP."
			_after_edit()
			return

func transfer_selected(destination: Vector2i, amount: int) -> void:
	if not can_edit() or selected.x < 0: return
	_build_history.clear()
	var moved := sim.transfer_gold(selected, destination, amount)
	notice = "%d gold transferred." % moved
	_save()
	changed.emit(false)

func start_raid() -> void:
	if not can_edit() or not ready_for_raid(): return
	if not _save():
		notice = "Save the prepared dungeon before starting the raid."
		changed.emit(false)
		return
	_build_history.clear()
	cancel_selection()
	raid._start_raid()
	notice = "The hero explores on their own. Watch the raid."
	changed.emit(true)

func _raid_finished(_result: Dictionary) -> void:
	last_reward = progression.claim(raid.last_result)
	result_open = true
	selected = Vector2i(-1, -1)
	tool = Types.Tool.NONE
	notice = "Raid complete. Review the results."
	_save()
	changed.emit(true)

func continue_preparation() -> void:
	if sim.game_over: return
	result_open = false
	paused = false
	raid.raid_timer = Types.RAID_DELAY
	notice = "Repair your defenses and prepare for the next raid."
	changed.emit(false)

func set_paused(value: bool) -> void:
	if confirmation_open and not value: return
	paused = value
	changed.emit(false)

func restart(prepared: bool) -> void:
	# Called only after an explicit confirmation in the HUD.
	_build_history.clear()
	sim.new_map()
	raid.reset_for_new_map()
	progression.last_raid_id = 0
	result_open = false
	paused = false
	confirmation_open = false
	catalog_open = false
	save_blocked = false
	tool = Types.Tool.NONE
	selected = Vector2i(-1, -1)
	preview = {}
	if prepared:
		sim._place_core(Vector2i(8, 8))
		for x in range(3, 7): sim.grid[8][x] = Types.Tile.FLOOR
		sim._place_entrance(Vector2i(3, 8))
		for p in [Vector2i(7, 7), Vector2i(9, 7), Vector2i(9, 9)]: sim.build_vault(p, 0)
		sim._place(Vector2i(5, 8), Types.Tile.DOOR, Types.COST_DOOR)
		sim._place(Vector2i(6, 8), Types.Tile.SPIKE, Types.COST_SPIKE)
		sim._storage_state()
		notice = "Demo dungeon: 245 gold, a door and a spike trap. Start the raid."
		# Inspection keeps the preparation countdown stopped for the first look.
		selected = Vector2i(8, 8)
	else:
		notice = "Choose a tile to anchor the Core."
	_visual_state = _structure_hash()
	_save()
	presentation_event.emit("reset")
	changed.emit(true)

func _save() -> bool:
	if save_blocked: return false
	# Capture reconciles assigned vault balances in normal play. Keep that rule
	# even when the simulation has no persistence; only disk I/O is bypassed.
	var data := Save.capture(sim, raid, progression)
	if not persistence_enabled: return true
	var ok := Save.write_save(save_path, data)
	save_error = "" if ok else "Could not save: your previous save has been kept."
	return ok

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready(): set_paused(true)

func _exit_tree() -> void:
	# RefCounted simulation/director intentionally reference each other in play.
	sim.raid = null
	raid.sim = null
