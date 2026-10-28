extends SceneTree

const Session = preload("res://scripts/game/game_session.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)

func run() -> void:
	var game = Session.new()
	check("persistence_enabled" in game, "session supports explicit no-save mode")
	check(game.has_method("advance_simulation"), "session exposes shared simulation tick")
	if not failures.is_empty():
		game.free()
		finish()
		return
	check(game.persistence_enabled, "normal game still persists by default")
	game.persistence_enabled = false
	game.save_path = "res://artifacts/probes/never-written.save"
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	game.restart(true)
	check(game.sim.gold == 245, "prepared map uses real costs")
	check(game.get_child_count() == 0, "no UI or renderer loaded")
	game.start_raid()
	check(game.raid.raid_active, "no-save session can start raid")
	game.advance_simulation(.05)
	check(is_equal_approx(game.raid.elapsed_seconds, .05), "shared tick advances raid")
	game.set_paused(true)
	game.advance_simulation(.05)
	check(is_equal_approx(game.raid.elapsed_seconds, .05), "pause freezes simulation")
	check(not FileAccess.file_exists(game.save_path), "no-save commands never write a save")
	game.sim.gold -= 10
	game._save()
	var stored := 0
	for amount in game.sim.vault_gold.values(): stored += amount
	check(stored == game.sim.gold, "no-save mode preserves normal save-time balance reconciliation")
	game.free()
	test_persistence_isolation()
	check(ResourceLoader.exists("res://scripts/testing/game_probes.gd"), "read-only game probes exist")
	if ResourceLoader.exists("res://scripts/testing/game_probes.gd"):
		test_probes()
	finish()

func test_probes() -> void:
	var probes = load("res://scripts/testing/game_probes.gd")
	check(probes != null and probes.can_instantiate(), "probe script compiles")
	if probes == null or not probes.can_instantiate(): return
	var game = Session.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.restart(true)
	var before := var_to_bytes([game.sim.grid, game.sim.vault_gold, game.sim.door_hp, game.raid.hero])
	var state: Dictionary = probes.snapshot(game)
	check(state["door:5:8"].status == "locked", "door probe exposes lock status")
	check(state["trap:6:8"].charges == 3, "trap probe exposes charges")
	check(state.economy.gold == 245, "economy probe exposes treasury")
	check(probes.violations(game).is_empty(), "valid prepared map passes invariants")
	check(before == var_to_bytes([game.sim.grid, game.sim.vault_gold, game.sim.door_hp, game.raid.hero]), "queries do not mutate state")
	game.sim.trap_charges[Vector2i(6,8)] = -1
	check(has_code(probes.violations(game), "trap.charges"), "negative trap charges detected")
	game.sim.trap_charges[Vector2i(6,8)] = 3
	game.sim.door_opened[Vector2i(5,8)] = true
	check(has_code(probes.violations(game), "door.open_hp"), "inconsistent open door detected")
	game.sim.door_hp[Vector2i(5,8)] = 0
	check(probes.snapshot(game)["door:5:8"].status == "open", "open door differs from broken")
	game.sim.door_opened.erase(Vector2i(5,8))
	check(probes.snapshot(game)["door:5:8"].status == "broken", "broken door stays observable")
	game.sim.door_hp[Vector2i(0,0)] = 60
	check(has_code(probes.violations(game), "entity.orphan"), "orphan entity detected")
	game.sim.door_hp.erase(Vector2i(0,0))
	game.start_raid()
	game.raid.hero.pos = Vector2i(0,0)
	check(has_code(probes.violations(game), "hero.blocked"), "hero in solid rock detected")
	game.free()
	check(ResourceLoader.exists("res://scripts/testing/scenario_runner.gd"), "scenario runner exists")
	if ResourceLoader.exists("res://scripts/testing/scenario_runner.gd"):
		test_scenarios()

func test_scenarios() -> void:
	var script = load("res://scripts/testing/scenario_runner.gd")
	check(script != null and script.can_instantiate(), "scenario runner compiles")
	if script == null or not script.can_instantiate(): return
	var runner = script.new()
	var scenario := {"name":"raid regression", "initial":"prepared", "seed":42, "steps":[
		{"action":"assert","probe":"economy","field":"gold","op":"eq","value":245},
		{"action":"start_raid"},
		{"action":"build","tool":"DIG","cell":[4,7],"expect":"rejected"},
		{"action":"wait","probe":"raid","field":"active","op":"eq","value":false,"timeout":180},
		{"action":"assert","probe":"session","field":"result_open","op":"eq","value":true},
		{"action":"continue"},
		{"action":"assert","probe":"session","field":"editable","op":"eq","value":true}]}
	var report: Dictionary = runner.run(scenario,root)
	check(report.ok, "real raid completes and build is rejected during raid: " + JSON.stringify(report.failures))
	check(report.ticks > 0, "scenario advanced actual game time")
	check(report == runner.run(scenario,root), "same seed/scenario reproduces full report")
	var bad := scenario.duplicate(true)
	bad.steps = [{"action":"assert","probe":"economy","field":"gold","op":"eq","value":999}]
	var failed: Dictionary = runner.run(bad,root)
	check(not failed.ok and failed.failures[0].probe == "economy", "assertion exposes precise probe failure")
	bad.steps = [{"action":"wait","probe":"raid","field":"active","op":"eq","value":true,"timeout":.1}]
	check(not runner.run(bad,root).ok, "bounded wait fails on timeout")
	bad.steps = [{"action":"advance","seconds":-1}]
	check(not runner.validate(bad).get("ok",false), "negative duration rejected")
	bad.steps = [{"action":"build","tool":"TYPO","cell":[0,0]}]
	check(not runner.validate(bad).get("ok",false), "unknown tools rejected before execution")
	bad.steps = [{"action":"build","tool":"DIG","cell":[.5,0]}]
	check(not runner.validate(bad).get("ok",false), "fractional cells rejected")
	bad.steps = [{"action":"advance","seconds":.01}]
	check(not runner.validate(bad).get("ok",false), "duration must match fixed tick")
	bad.steps = [{"action":"assert","probe":"door:5:8","field":"typo","op":"ne","value":0}]
	check(not runner.run(bad,root).ok, "missing fields never silently satisfy assertions")
	check(root.get_child_count() == 0, "runner cleans up session without UI nodes")
	check(test_invalid_inputs(runner), "malformed-input checks all completed without runtime errors")

func test_invalid_inputs(runner) -> bool:
	var base := {"name":"input validation","steps":[{"action":"checkpoint","label":"initial"}]}
	for value in [true,{},[],"1",null,2,1.5]:
		var data := base.duplicate(true)
		data.version = value
		check(not runner.validate(data).get("ok",false), "reject invalid version " + str(value))
	for field in ["seed","initial","name","steps"]:
		var data := base.duplicate(true)
		data[field] = {}
		check(not runner.validate(data).get("ok",false), "reject malformed " + field)
	for item in [
		{"action":"advance","seconds":3599.99},
		{"action":"advance","seconds":true},
		{"action":"advance","seconds":{}},
		{"action":"build","tool":"DIG","cell":[16,0]},
		{"action":"build","tool":"DIG","cell":[true,0]},
		{"action":"assert","probe":"door:99:1","op":"exists","value":false},
		{"action":"assert","probe":"typo","op":"exists","value":false},
		{"action":"assert","probe":"hero","op":"typo","value":false},
		{"action":"pause","value":"false"},
		{"action":"checkpoint","label":"x","unexpected":true}]:
		var data := base.duplicate(true)
		data.steps = [item]
		check(not runner.validate(data).get("ok",false), "reject malformed step " + JSON.stringify(item))
	return true

func test_persistence_isolation() -> void:
	# A known, corrupt artifact file must not be read or replaced in no-save mode.
	var path := "res://artifacts/probes/sentinel.save"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("probe isolation sentinel")
	file.close()
	var before := FileAccess.get_sha256(path)
	var isolated = Session.new()
	isolated.persistence_enabled = false
	isolated.save_path = path
	root.add_child(isolated)
	isolated.set_process(false)
	check(not isolated.save_blocked, "no-save initialization does not read existing save")
	isolated.restart(true)
	isolated.start_raid()
	for _i in 100: isolated.advance_simulation(.05)
	check(FileAccess.get_sha256(path) == before, "existing save untouched by no-save simulation")
	check(not FileAccess.file_exists(path+".bak") and not FileAccess.file_exists(path+".tmp"), "no-save simulation creates no backup/temporary save")
	isolated.free()
	# Normal persistence remains exercised, only against an artifact test slot.
	var normal = Session.new()
	normal.save_path = "res://artifacts/probes/normal-test.save"
	root.add_child(normal)
	normal.set_process(false)
	normal.restart(true)
	check(FileAccess.file_exists(normal.save_path), "normal game persistence still writes")
	normal.free()
	var restored = Session.new()
	restored.save_path = "res://artifacts/probes/normal-test.save"
	root.add_child(restored)
	restored.set_process(false)
	check(restored.sim.gold == 245 and restored.sim._has_core(), "normal game persistence still reads")
	restored.free()

func has_code(items: Array, code: String) -> bool:
	for item in items:
		if item.code == code: return true
	return false

func finish() -> void:
	print(JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
