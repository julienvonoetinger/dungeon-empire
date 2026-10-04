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
		for locked in [false, true]:
			game.sim.new_map()
			game.raid.reset_for_new_map()
			game.dungeon._sync_hero(game)
			var entrance := Vector2i(7, 7)
			var vault: Vector2i = entrance + direction * 2
			for step in 3:
				var cell: Vector2i = entrance + direction * step
				game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
			game.grid[entrance.y][entrance.x] = GameTypes.Tile.ENTRANCE
			game.grid[vault.y][vault.x] = GameTypes.Tile.VAULT
			game.sim.vault_gold[vault] = 40
			game.gold = 40
			if locked:
				game.sim.vault_locks[vault] = 1
			game.dungeon.sync(game)
			game.raid._start_raid()
			game.hero.steal_capacity = 40
			game.hero.lockpick_success_chance = 1.0
			game.hero.known[vault] = GameTypes.Tile.VAULT
			# Real first-frame order: simulation can step before renderer sees the spawn.
			game.raid._update_hero(1.0 / 60.0)
			game.dungeon._sync_hero(game)
			var visual := Probes.child(game.dungeon, "HeroVisual") as Node3D
			var start: Vector3 = game.dungeon.cell_center(entrance, visual.position.y)
			check(visual.position.distance_to(start) < 0.06, "first rendered frame starts at entrance, not adjacent tile")
			var previous := visual.position
			var maximum_step := 0.0
			var collected := false
			for frame in 600:
				game.raid._update_hero(1.0 / 60.0)
				game.dungeon._sync_hero(game)
				game.dungeon._advance_hero_visual(1.0 / 60.0)
				maximum_step = maxf(maximum_step, visual.position.distance_to(previous))
				previous = visual.position
				if game.hero.get("collecting_gold", false):
					collected = true
					var target: Vector3 = game.dungeon.cell_center(vault, visual.position.y) - Vector3(direction.x, 0, direction.y) * game.dungeon.VAULT_COLLECT_OFFSET
					check(visual.position.distance_to(target) < 0.02, "arrival ends at collection anchor")
					var collect_model := Probes.child(game.dungeon._vulpin, "Collect")
					check(collect_model != null and collect_model.visible, "collection pose is visible after arrival")
					break
			check(collected, "route reaches collection")
			check(maximum_step < 0.08, "no snap during approach/action: step=%f direction=%s locked=%s" % [maximum_step, direction, locked])
			print("Arrival probe: ", direction, " locked=", locked, " max step=", maximum_step)
	game.queue_free()
	await process_frame
	print("Hero arrival motion failures: ", failures)
	quit(1 if failures else 0)
