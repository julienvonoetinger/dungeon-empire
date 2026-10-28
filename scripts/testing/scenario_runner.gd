extends RefCounted
## Synchronous, sequential runner. Never instantiate DungeonGame.tscn here.
const Session = preload("res://scripts/game/game_session.gd")
const Probes = preload("res://scripts/testing/game_probes.gd")
const Types = preload("res://scripts/game/game_types.gd")
const TICK := .05
const MAX_TICKS := 100000
const COMMANDS := {
	"build":["tool","cell","expect"], "start_raid":["expect"], "undo":["expect"],
	"continue":[], "pause":["value"], "advance":["seconds"],
	"assert":["probe","field","op","value"], "wait":["probe","field","op","value","timeout"],
	"checkpoint":["label"], "collect":["cell"], "absorb":["cell"],
	"transfer":["cell","destination","amount","expect"]}
const CONDITIONS := ["eq","ne","lt","lte","gt","gte","exists"]
var _game
var _report: Dictionary
var _step := -1

func validate(data: Variant) -> Dictionary:
	var errors: Array[String] = []
	if not data is Dictionary: return {"ok":false,"errors":["Scenario must be an object"]}
	for key in data:
		if key not in ["version","name","initial","seed","steps"]: errors.append("Unknown scenario field: " + str(key))
	if not _integer(data.get("version",1)) or int(data.get("version",1)) != 1: errors.append("Unsupported scenario version")
	if not data.get("name") is String or str(data.get("name","")).is_empty(): errors.append("name must be a nonempty string")
	if data.get("initial","prepared") not in ["empty","prepared"]: errors.append("initial must be empty or prepared")
	if not _integer(data.get("seed",1)) or absf(float(data.get("seed",1))) > 2147483647: errors.append("seed must be a signed 32-bit integer")
	if not data.get("steps") is Array: return {"ok":false,"errors":errors + ["steps must be an array"]}
	if data.steps.is_empty() or data.steps.size() > 512: errors.append("Use 1..512 steps")
	var ticks := 0
	var checkpoints := 0
	for i in data.steps.size():
		var item = data.steps[i]
		var prefix := "step %d: " % i
		if not item is Dictionary or not item.get("action") is String or not COMMANDS.has(item.action):
			errors.append(prefix + "Unknown/missing action")
			continue
		var action: String = item.action
		for key in item:
			if key != "action" and key not in COMMANDS[action]: errors.append(prefix + "Unknown field: " + str(key))
		if item.has("expect") and item.expect not in ["accepted","rejected"]: errors.append(prefix + "expect must be accepted or rejected")
		if action in ["build","collect","absorb","transfer"] and not _cell(item.get("cell")): errors.append(prefix + "cell must be two integer grid coordinates")
		if action == "build" and (not item.get("tool") is String or not Types.Tool.has(item.tool) or item.tool in ["NONE","RESET","ABSORB"]): errors.append(prefix + "Unknown/non-build tool")
		if action == "transfer":
			if not _cell(item.get("destination")): errors.append(prefix + "Invalid destination")
			if not _integer(item.get("amount")) or float(item.get("amount",0)) <= 0 or float(item.get("amount",0)) > 2147483647: errors.append(prefix + "Invalid transfer amount")
		if action == "pause" and not item.get("value") is bool: errors.append(prefix + "pause value must be boolean")
		if action in ["advance","wait"]:
			var value = item.get("seconds" if action == "advance" else "timeout")
			if not _number(value) or float(value) <= 0 or float(value) > 3600 or absf(float(value)/TICK-roundf(float(value)/TICK)) > .000001:
				errors.append(prefix + "Duration must be a positive multiple of 0.05, at most 3600 seconds")
			else: ticks += int(roundf(float(value)/TICK))
		if action in ["assert","wait"]:
			if not _probe_id(item.get("probe")): errors.append(prefix + "Unknown/malformed probe ID")
			if not item.get("field","") is String: errors.append(prefix + "field must be a string")
			if item.get("op") not in CONDITIONS or not item.has("value"): errors.append(prefix + "Invalid comparison or missing value")
			elif item.op == "exists" and not item.value is bool: errors.append(prefix + "exists value must be boolean")
			elif item.op in ["lt","lte","gt","gte"] and not _number(item.value): errors.append(prefix + "Ordered comparisons require a number")
		if action == "checkpoint":
			checkpoints += 1
			if not item.get("label") is String or str(item.get("label","")).is_empty(): errors.append(prefix + "checkpoint label required")
	if ticks > MAX_TICKS: errors.append("Scenario exceeds 100000 tick budget")
	if checkpoints > 16: errors.append("At most 16 explicit checkpoints")
	return {"ok":errors.is_empty(),"errors":errors}

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floorf(float(value))

static func _cell(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _integer(value[0]) and _integer(value[1]) and value[0] >= 0 and value[0] < Types.COLS and value[1] >= 0 and value[1] < Types.ROWS

static func _probe_id(value: Variant) -> bool:
	if not value is String: return false
	if value in ["session","core","economy","raid","hero","progression","loot"]: return true
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 3 or parts[0] not in ["cell","door","trap","vault"]: return false
	if not parts[1].is_valid_int() or not parts[2].is_valid_int(): return false
	var p := Vector2i(int(parts[1]),int(parts[2]))
	return _cell([p.x,p.y]) and value == Probes.cell_id(parts[0],p)

func run(data: Dictionary, parent: Node) -> Dictionary:
	_report = {"version":1, "name":data.get("name",""), "seed":data.get("seed",1),
		"engine":Engine.get_version_info().string, "tick_seconds":TICK,
		"settings":{"vulpin_only":bool(ProjectSettings.get_setting("testing/vulpin_only",false))},
		"scenario_hash":JSON.stringify(data,"",true).sha256_text(), "ticks":0,
		"ok":false, "status":"error", "failures":[], "steps":[], "events":[], "checkpoints":[]}
	var validation := validate(data)
	if not validation.get("ok",false):
		for error in validation.get("errors",["Validation did not complete"]): _report.failures.append({"code":"scenario.invalid","message":error,"step":-1,"tick":0})
		return _report.duplicate(true)
	# No graphical scene is loaded, so no other process consumes the seeded RNG.
	# Sequential replay is supported; parallel simulations need separate processes.
	seed(int(data.get("seed",1)))
	_game = Session.new()
	_game.persistence_enabled = false
	parent.add_child(_game)
	_game.set_process(false)
	_game.restart(data.get("initial","prepared") == "prepared")
	_game.raid.trap_activated.connect(_trap_event)
	_game.raid.raid_finished.connect(_raid_event)
	_step = -1
	if _observe(): _checkpoint("initial")
	for i in data.steps.size():
		if not _report.failures.is_empty(): break
		_step = i
		var item: Dictionary = data.steps[i]
		var entry := {"index":i,"action":item.action,"start_tick":_report.ticks}
		_execute(item)
		if _report.failures.is_empty(): _observe()
		entry["end_tick"] = _report.ticks
		entry["ok"] = _report.failures.is_empty()
		_report.steps.append(entry)
	# Bad geometry is already diagnosed; do not index an invalid grid for a report.
	var invalid := Probes.violations(_game)
	if not invalid.any(func(v): return v.code.begins_with("grid.")): _checkpoint("final")
	_report.ok = _report.failures.is_empty()
	_report.status = "passed" if _report.ok else "failed"
	_game.free() # Session._exit_tree breaks the simulation/director reference cycle.
	_game = null
	return _report.duplicate(true)

func _execute(item: Dictionary) -> void:
	match item.action:
		"build":
			var p := Vector2i(item.cell[0],item.cell[1])
			var tool: int = Types.Tool[item.tool]
			var response: Dictionary = _game.check_action(p,tool)
			if bool(response.valid):
				_game.choose_tool(tool)
				_game.select_cell(p)
				_game.confirm_action()
				_game.cancel_selection()
			_expect_command(item,bool(response.valid),str(response.reason))
		"start_raid":
			var previous: int = _game.raid.raid_index
			_game.start_raid()
			_expect_command(item,_game.raid.raid_index == previous+1,_game.notice)
		"undo":
			var accepted: bool = _game.can_undo()
			_game.undo_build()
			_expect_command(item,accepted,"No construction to undo or editing blocked")
		"continue":
			if not _game.result_open or _game.sim.game_over: _fail("command.rejected","session","No resumable raid result")
			else: _game.continue_preparation()
		"pause": _game.set_paused(item.value)
		"advance":
			for _i in int(roundf(float(item.seconds)/TICK)):
				if not _tick(): break
		"wait":
			var condition := _condition(item)
			for _i in int(roundf(float(item.timeout)/TICK)):
				if condition.ok or condition.has("error"): break
				if not _tick(): return
				condition = _condition(item)
			if not condition.ok: _fail("wait.timeout" if not condition.has("error") else "assert.invalid",item.probe,condition.get("error","Condition not reached before timeout"),condition)
		"assert":
			var condition := _condition(item)
			if not condition.ok: _fail("assert.failed",item.probe,condition.get("error","Unexpected probe value"),condition)
		"checkpoint": _checkpoint(item.label)
		"collect", "absorb", "transfer":
			if not _game.can_edit():
				if item.action == "transfer": _expect_command(item,false,"Editing blocked")
				else: _fail("command.rejected","session","Editing blocked")
				return
			_game.select_cell(Vector2i(item.cell[0],item.cell[1]))
			if item.action == "collect": _game.collect_selected()
			elif item.action == "absorb": _game.absorb_selected()
			else:
				var previous: Dictionary = _game.sim.vault_gold.duplicate()
				_game.transfer_selected(Vector2i(item.destination[0],item.destination[1]),int(item.amount))
				_expect_command(item,previous != _game.sim.vault_gold,_game.notice)
			_game.cancel_selection()

func _expect_command(item: Dictionary, accepted: bool, reason: String) -> void:
	var expected: bool = item.get("expect","accepted") == "accepted"
	if accepted != expected:
		_fail("command.outcome","session",reason,{"expected":expected,"actual":accepted})

func _tick() -> bool:
	_game.advance_simulation(TICK)
	_report.ticks += 1
	return _observe()

func _observe() -> bool:
	for failure in Probes.violations(_game): _fail(failure.code,failure.probe,failure.message)
	return _report.failures.is_empty()

func _condition(item: Dictionary) -> Dictionary:
	var state := Probes.snapshot(_game)
	var found := state.has(item.probe)
	var actual: Variant = state.get(item.probe)
	var field: String = item.get("field","")
	if not field.is_empty():
		for key in field.split("."):
			if not actual is Dictionary or not actual.has(key):
				found = false
				actual = null
				break
			actual = actual[key]
	var result := {"ok":false,"field":field,"op":item.op,"expected":item.value,"actual":actual}
	if item.op == "exists":
		result.actual = found
		result.ok = found == item.value
	elif not found: result["error"] = "Probe or field does not exist"
	elif item.op in ["eq","ne"]:
		# JSON parses numbers as floats; do not coerce strings or booleans.
		var compatible := typeof(actual) == typeof(item.value) or (_number(actual) and _number(item.value))
		result.ok = compatible and (actual == item.value if item.op == "eq" else actual != item.value)
	elif not _number(actual): result["error"] = "Ordered comparison requires a numeric probe"
	else:
		match item.op:
			"lt": result.ok = actual < item.value
			"lte": result.ok = actual <= item.value
			"gt": result.ok = actual > item.value
			"gte": result.ok = actual >= item.value
	return result

func _checkpoint(label: String) -> void:
	_report.checkpoints.append({"label":label,"tick":_report.ticks,"probes":Probes.snapshot(_game)})

func _fail(code: String, probe: String, message: String, details: Dictionary = {}) -> void:
	var failure := {"code":code,"probe":probe,"message":message,"step":_step,"tick":_report.ticks}
	failure.merge(details)
	_report.failures.append(failure)

func _trap_event(cell: Vector2i, tile: int) -> void:
	_report.events.append({"tick":_report.ticks+1,"event":"trap_activated","probe":Probes.cell_id("trap",cell),"tile":Types.Tile.keys()[tile]})

func _raid_event(result: Dictionary) -> void:
	_report.events.append({"tick":_report.ticks+1,"event":"raid_finished","result":Probes.json_value(result)})
