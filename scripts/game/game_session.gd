class_name IsometricGameSession
extends Node

## Rules restored from v1.0.0; this controller owns phases and player commands.
signal changed(structure: bool)
signal introduction_started
signal frame_updated
## Optional presentation feedback; no consumer is required by simulations.
signal presentation_event(kind: String)
const Types = preload("res://scripts/game/game_types.gd")
const Save = preload("res://scripts/game/gameplay_save.gd")
const SAVE_PATH := "user://isometric_run_v1.save"
static func launch_save_path() -> String:
	if OS.get_cmdline_user_args().has("--forge-review"): return "user://forge_review_v1.save"
	if OS.get_cmdline_user_args().has("--review-session"): return "user://isometric_review_v1.save"
	return SAVE_PATH

var save_path := launch_save_path()
## Set before entering the tree for isolated simulations; no disk reads or writes.
var persistence_enabled := true
const FIELDS := ["grid", "gold", "floor_gold", "vault_gold", "vault_locks", "vault_opened", "core_hp", "door_hp", "door_opened", "trap_charges", "loot_bags", "corpses", "game_over"]
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
## Presentation-only cutaway; the complete playable map is saved from the start.
var revealed_column := Types.COLS
var raid_speed := 1
var _visual_state := 0
var _build_history: Array[Dictionary] = []

func _ready() -> void:
	# Explicit manual-review slot; never touches the player's current dungeon.
	if persistence_enabled and OS.get_cmdline_user_args().has("--forge-review"):
		get_window().title = "Forge · Review"
	elif persistence_enabled and OS.get_cmdline_user_args().has("--review-session"):
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
		sim._place_core(Types.core_origin_cell())
		notice = sim.message
	_visual_state = _structure_hash()
	changed.emit(true)

func phase() -> String:
	if sim.game_over: return "Defeat"
	if result_open: return "Results"
	if raid.raid_active: return "Raid"
	if not sim._has_core(): return "Core placement"
	return "Preparation"

func can_edit() -> bool:
	return not progression.awaiting_miner and sim.lesson not in [Types.Lesson.MEET_CARPENTER,Types.Lesson.MEET_SCIENTIST,Types.Lesson.PRACTICE_RAID] and not paused and not confirmation_open and not result_open and not raid.raid_active and not sim.game_over and not save_blocked

func ready_for_raid() -> bool:
	return sim.lesson == Types.Lesson.FREE and sim._has_required_storage() and not sim.game_over and not save_blocked

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

## One-shot excavation from the world. Keep the usual validation, undo and
## save transaction, without arming a tool that could remove an occupied tile.
func dig_cell(cell: Vector2i) -> void:
	if not can_edit() or catalog_open or tool != Types.Tool.NONE or not sim._has_core(): return
	if not sim._inside(cell) or sim.grid[cell.y][cell.x] != Types.Tile.ROCK: return
	selected = cell
	confirm_action(Types.Tool.DIG)
	# A rejected direct tap must not leave a confirmation sheet on the rock.
	if selected.x >= 0:
		selected = Vector2i(-1,-1); preview = {}
		changed.emit(false)

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

## Door and trap sites, including objects that the selected tool can replace.
func available_build_sites(build_tool: int) -> Array[Vector2i]:
	var sites: Array[Vector2i] = []
	if not can_edit() or not sim._has_core() or not progression.allows(build_tool): return sites
	for y in Types.ROWS:
		for x in Types.COLS:
			if sim.grid[y][x] == Types.Tile.ROCK: continue
			var cell := Vector2i(x,y)
			if check_action(cell,build_tool).valid: sites.append(cell)
	return sites

func check_action(cell: Vector2i, requested_tool: int = -1) -> Dictionary:
	if not can_edit() or not sim._inside(cell): return {"valid": false, "reason": "Action unavailable", "cost": 0}
	var action_tool := tool if requested_tool < 0 else requested_tool
	match sim.lesson:
		Types.Lesson.ALCOVE:
			if action_tool != Types.Tool.DIG or sim.grid[cell.y][cell.x] != Types.Tile.ROCK:
				return {"valid":false, "reason":"Touchez une pioche pour creuser à cet endroit.", "cost":0}
		Types.Lesson.DOOR:
			if action_tool != Types.Tool.BUILD_DOOR or not sim.is_lesson_build_site(cell,Types.Tile.DOOR):
				return {"valid":false, "reason":"Choisissez un passage entre deux murs.", "cost":0}
		Types.Lesson.SPIKES:
			if action_tool != Types.Tool.TRAP_SPIKE or not sim.is_lesson_build_site(cell,Types.Tile.SPIKE):
				return {"valid":false, "reason":"Choisissez une case de sol libre.", "cost":0}
		Types.Lesson.CHEST:
			if cell != sim.lesson_alcove or action_tool != Types.Tool.STORE:
				return {"valid":false, "reason":"Installez le coffre dans l’alcôve.", "cost":0}
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
	# Coins displaced onto the ground are recoverable, not a construction cost.
	var spent := sim.gold - copy.gold - (copy._unsecured_loot_total() - sim._unsecured_loot_total())
	return {"valid": modified, "cost": maxi(0, spent), "reason": copy.message}

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
	var spent := 1000000 - copy.gold - (copy._unsecured_loot_total() - sim._unsecured_loot_total())
	if spent>sim.gold: presentation_event.emit("fauche")

func confirm_action(requested_tool: int = -1) -> void:
	if selected.x < 0 or not can_edit(): return
	preview = check_action(selected, requested_tool)
	if not preview.valid:
		notice = str(preview.reason)
		report_rejected_action(selected, requested_tool)
		changed.emit(false)
		return
	if sim._has_core() and sim.lesson == Types.Lesson.FREE:
		_build_history.append(_build_snapshot())
		if _build_history.size() > 32: _build_history.pop_front()
	var previous_rooms := sim.treasure_rooms().size()
	_apply(sim, selected, requested_tool)
	sim._storage_state()
	notice = "Treasure room discovered! +%d storage capacity." % Types.TREASURY_CAPACITY_BONUS if sim.treasure_rooms().size() > previous_rooms else "Action complete."
	var used := tool if requested_tool < 0 else requested_tool
	match sim.lesson:
		Types.Lesson.DOOR:
			if used == Types.Tool.BUILD_DOOR:
				# An older tutorial save may still put the door before the excavation.
				sim.lesson = Types.Lesson.ALCOVE if sim.grid[sim.lesson_alcove.y][sim.lesson_alcove.x] == Types.Tile.ROCK else Types.Lesson.MEET_SCIENTIST
		Types.Lesson.ALCOVE:
			if used == Types.Tool.DIG:
				sim.lesson_alcove = selected
				sim.lesson = Types.Lesson.MEET_CARPENTER
		Types.Lesson.SPIKES:
			if used == Types.Tool.TRAP_SPIKE: sim.lesson = Types.Lesson.CHEST
		Types.Lesson.CHEST:
			if selected == sim.lesson_alcove and used == Types.Tool.STORE:
				sim.lesson = Types.Lesson.PRACTICE_RAID
				notice = ""
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

func leave_tutorial() -> void:
	if progression.awaiting_miner or sim.lesson in [Types.Lesson.MEET_CARPENTER, Types.Lesson.MEET_SCIENTIST, Types.Lesson.PRACTICE_RAID]: return
	sim.lesson = Types.Lesson.FREE
	notice = ""
	_after_edit()

func accept_village_gift() -> void:
	if sim.lesson != Types.Lesson.INVOKER_OFFER or paused or confirmation_open or save_blocked: return
	sim.lesson = Types.Lesson.VILLAGE_GIFT
	_save()
	changed.emit(false)

func finish_practice_raid() -> void:
	if sim.lesson != Types.Lesson.PRACTICE_RAID or paused or confirmation_open or save_blocked: return
	sim.invoker_resident = true
	sim.lesson = Types.Lesson.FREE
	_save()
	changed.emit(false)

func place_village_bag(cell: Vector2i) -> void:
	if paused or confirmation_open or save_blocked or not sim.place_gift(cell): return
	_after_edit()

func learn_from_artisan(checkpoint: int) -> void:
	if sim.lesson != checkpoint: return
	match checkpoint:
		Types.Lesson.MEET_MINER:
			sim.lesson = Types.Lesson.ALCOVE
			progression.awaiting_miner = false
		Types.Lesson.MEET_CARPENTER:
			progression.grant_tutorial_level(2)
			# Older tutorials may already have built a door before digging.
			sim.lesson = Types.Lesson.MEET_SCIENTIST if sim._find_tile(Types.Tile.DOOR).x >= 0 else Types.Lesson.DOOR
		Types.Lesson.MEET_SCIENTIST:
			progression.grant_tutorial_level(3)
			sim.lesson = Types.Lesson.SPIKES
		_:
			return
	_save()
	changed.emit(false)

func restart(prepared: bool, introduction := false) -> void:
	# Called only after an explicit confirmation in the HUD.
	_build_history.clear()
	revealed_column = Types.COLS
	sim.new_map()
	raid.reset_for_new_map()
	progression.last_raid_id = 0
	progression.awaiting_miner = introduction
	result_open = false
	paused = false
	confirmation_open = false
	catalog_open = false
	save_blocked = false
	tool = Types.Tool.NONE
	selected = Vector2i(-1, -1)
	preview = {}
	sim._place_core(Types.core_origin_cell())
	if prepared or introduction:
		for x in range(Types.FIRST_STAIR.x, Types.core_origin_cell().x):
			sim.grid[Types.FIRST_STAIR.y][x] = Types.Tile.FLOOR
		sim._place_entrance(Types.FIRST_STAIR)
	if introduction:
		progression.invocation_xp = progression.xp
		sim.gold = 0
		sim.lesson = Types.Lesson.INVOKER_OFFER
	if prepared:
		for p in [Vector2i(7, 7), Vector2i(9, 7), Vector2i(9, 9)]: sim.build_vault(p, 0)
		sim._place(Vector2i(5, 8), Types.Tile.DOOR, Types.COST_DOOR)
		sim._place(Vector2i(6, 8), Types.Tile.SPIKE, Types.COST_SPIKE)
		sim._storage_state()
		notice = "Demo dungeon: 245 gold, a door and a spike trap. Start the raid."
		# Inspection keeps the preparation countdown stopped for the first look.
		selected = Vector2i(8, 8)
	else:
		notice = sim.message
	_visual_state = _structure_hash()
	_save()
	presentation_event.emit("reset")
	changed.emit(true)
	if introduction: introduction_started.emit()

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
