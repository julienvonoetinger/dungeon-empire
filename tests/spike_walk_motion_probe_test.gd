extends SceneTree

const Probes := preload("res://tests/probes/node_probes.gd")
class StraightRoute:
	extends RaidDirector
	var direction := Vector2i.RIGHT
	func _choose_next_step(h: Dictionary) -> Vector2i:
		return h.pos + direction

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.dungeon.set_process(false)
	game.mobile_ui.paused = true
	var raid := StraightRoute.new()
	raid.sim = game.sim
	game.raid = raid
	game.sim.raid = raid
	var cases := 0
	var worst_stationary_time := 0.0
	for fps in [30, 60, 120]:
		for direction in GameTypes.DIRS:
			for state in ["armed", "sprung", "spent"]:
				for kind in ["thief", "paladin", "mage", "ranger"]:
					game.sim.new_map()
					raid.reset_for_new_map()
					game.dungeon._sync_hero(game)
					raid.direction = direction
					var start := Vector2i(7, 7)
					var trap: Vector2i = start + direction
					for step in 5:
						var cell: Vector2i = start + direction * step
						game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
					game.grid[start.y][start.x] = GameTypes.Tile.ENTRANCE
					game.grid[trap.y][trap.x] = GameTypes.Tile.SPIKE
					game.trap_charges[trap] = 0 if state == "spent" else 3
					raid._start_raid()
					raid.hero.merge({"kind": kind, "hp": 200, "max_hp": 200, "patience": 1000, "flee_ratio": 0.0}, true)
					if state == "sprung":
						raid.hero.triggered_traps[trap] = true
					game.dungeon._sync_hero(game)
					var visual := Probes.child(game.dungeon, "HeroVisual") as Node3D
					var previous := visual.position
					var stalled := 0
					var max_stalled := 0
					var reached_after := false
					var walking_continuously := true
					var max_step := 0.0
					var dt: float = 1.0 / fps
					for frame in fps * 2:
						raid._update_hero(dt)
						game.dungeon._sync_hero(game)
						game.dungeon._advance_hero_visual(dt)
						max_step = maxf(max_step, visual.position.distance_to(previous))
						if kind == "thief":
							walking_continuously = walking_continuously and (Probes.child(game.dungeon._vulpin, "Walking") as Node3D).visible
						var traveled := Vector2(visual.position.x - (start.x + 0.5), visual.position.z - (start.y + 0.5)).dot(Vector2(direction))
						if traveled > 0.9 and traveled < 1.25:
							stalled = stalled + 1 if visual.position.distance_to(previous) < 0.00001 else 0
							max_stalled = maxi(max_stalled, stalled)
						previous = visual.position
						if traveled > 1.5:
							reached_after = true
							break
					var label := "%s %s %s %dfps" % [kind, state, direction, fps]
					check(reached_after and max_stalled <= 1, "%s: stopped %d frames (%.3fs)" % [label, max_stalled, max_stalled * dt])
					check(max_step <= dt / GameTypes.TURN_TIME + 0.002, label + ": no position jump")
					check(walking_continuously, label + ": walking pose remains active")
					worst_stationary_time = maxf(worst_stationary_time, max_stalled * dt)
					var damage := (20 if kind == "paladin" else 30) if state == "armed" else 0
					check(raid.hero.hp == 200 - damage, label + ": expected damage")
					check(game.trap_charges[trap] == (2 if state == "armed" else (3 if state == "sprung" else 0)), label + ": expected charges")
					cases += 1
	game.queue_free()
	await process_frame
	print("Spike walk probe: %d cases, %d failures" % [cases, failures])
	print("Longest stationary sample: %.4fs" % worst_stationary_time)
	quit(1 if failures else 0)
