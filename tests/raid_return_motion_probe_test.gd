extends SceneTree

const Probes = preload("res://tests/probes/node_probes.gd")
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
	game.mobile_ui.paused = true
	game.dungeon.set_process(false)
	ProjectSettings.set_setting("testing/vulpin_only", true)
	for direction in GameTypes.DIRS:
		for tile in [GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE]:
			game.sim.new_map()
			game.raid.reset_for_new_map()
			game.dungeon._sync_hero(game)
			var entrance := Vector2i(7, 7)
			var trap: Vector2i = entrance + direction * 2
			var vault: Vector2i = entrance + direction * 4
			for step in 5:
				var cell: Vector2i = entrance + direction * step
				game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
			game.grid[entrance.y][entrance.x] = GameTypes.Tile.ENTRANCE
			game.grid[trap.y][trap.x] = tile
			var initial_charges := 1 if direction.x < 0 else 3
			game.trap_charges[trap] = initial_charges
			game.grid[vault.y][vault.x] = GameTypes.Tile.VAULT
			game.sim.vault_gold[vault] = 40
			game.gold = 40
			game.dungeon.sync(game)
			game.raid._start_raid()
			game.hero.merge({"steal_capacity": 40, "hp": 200, "max_hp": 200, "patience": 1000, "flee_ratio": 0.0}, true)
			game.dungeon._sync_hero(game)
			var visual := Probes.child(game.dungeon, "HeroVisual") as Node3D
			var previous := visual.position
			var maximum_step := 0.0
			var returning := false
			var crossing_exit := false
			var stayed_sprung := true
			for frame in 2400:
				if not game.raid.raid_active:
					break
				game.raid._update_hero(1.0 / 60.0)
				game.dungeon._sync_hero(game)
				game.dungeon._advance_hero_visual(1.0 / 60.0)
				if not visual.visible:
					break
				maximum_step = maxf(maximum_step, visual.position.distance_to(previous))
				previous = visual.position
				if game.hero.get("fleeing", false):
					returning = true
					stayed_sprung = stayed_sprung and game.dungeon._trap_sprung(trap, game, false)
					check(not game.hero.get("portaling", false), "return never enters portal animation")
					var run_pose := Probes.child(game.dungeon._vulpin, "Running") as Node3D
					check(run_pose.visible, "return uses running pose")
				if game.hero.get("exiting", false):
					crossing_exit = true
					check(game.hero.pos == entrance, "exit animation only at the entrance")
			check(returning and crossing_exit and stayed_sprung, "full visual return, exit and persistent trap state")
			check(maximum_step < 0.08, "no snap at collection, return or exit: %f" % maximum_step)
			check(not game.raid.raid_active and game.raid.last_result.get("escaped", 0) == 1, "physical departure completes")
			check(game.trap_charges[trap] == initial_charges - 1, "outward and return journeys spend exactly one charge")
			print("Return probe ", direction, " trap=", tile, " max frame displacement=", maximum_step)
	game.queue_free()
	await process_frame
	print("Return motion failures: ", failures)
	quit(1 if failures else 0)
