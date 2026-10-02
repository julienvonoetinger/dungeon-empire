extends SceneTree

const PROBES := preload("res://tests/probes/node_probes.gd")

class ForcedRoute:
	extends RaidDirector
	var destination := Vector2i(2, 1)
	func _choose_next_step(_h: Dictionary) -> Vector2i:
		return destination

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.set_process(false)
	game.dungeon.set_process(false)
	var raid := ForcedRoute.new()
	raid.sim = game.sim
	game.raid = raid
	game.sim.raid = raid
	var start := Vector2i(1, 1)
	var target := Vector2i(2, 1)
	for kind in ["thief", "ranger", "paladin", "mage"]:
		for tile in [GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE, GameTypes.Tile.VOID]:
			game.sim.new_map()
			game.grid[start.y][start.x] = GameTypes.Tile.ENTRANCE
			game.grid[target.y][target.x] = tile
			game.trap_charges[target] = game._trap_max_charges(tile)
			raid._start_raid()
			raid.hero.merge({"kind": kind, "hp": 200, "max_hp": 200, "flee_ratio": 0.0, "patience": 1000}, true)
			game.dungeon._hero_cell = Vector2i(-1, -1)
			game.dungeon._sync_hero(game)
			var visual := PROBES.child(game.dungeon, "HeroVisual") as Node3D
			assert(visual != null)
			var charges: int = game.trap_charges[target]
			raid._update_hero(0.01)
			game.dungeon._sync_hero(game)
			assert(game.trap_charges[target] == charges and raid.hero.hp == 200)
			assert(not raid.hero.has("trap_sprung_at"))
			for step in 48:
				raid._update_hero(0.01)
				game.dungeon._sync_hero(game)
				var distance := Vector2(visual.position.x - 2.5, visual.position.z - 1.5).length()
				if step < 47:
					assert(game.trap_charges[target] == charges, "no charge spent before arrival")
					assert(not raid.hero.has("trap_sprung_at"))
				else:
					assert(game.trap_charges[target] == charges - 1)
					# Void starts its absorption orbit only after reaching the tile.
					assert(distance < (0.23 if tile == GameTypes.Tile.VOID else 0.001))
					print("PROBE ", kind, " tile=", tile, " trigger=0.48s visual_distance=", distance)
			if tile == GameTypes.Tile.SNARE:
				assert(is_equal_approx(raid.hero.move_cd, GameTypes.SNARE_HOLD_TIME))
				var turns: int = raid.hero.turns
				for step in 29:
					raid._update_hero(0.1)
					assert(raid.hero.pos == target and raid.hero.turns == turns)
				assert(game.trap_charges[target] == charges - 1, "holding must not retrigger")
				raid._update_hero(0.11)
				assert(raid.hero.turns > turns, "snare releases after three seconds")
	game.queue_free()
	await process_frame
	print("OK: arrival probes for all 12 hero/trap combinations and 3-second snare")
	quit()
