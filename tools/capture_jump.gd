extends SceneTree

const PROBES := preload("res://tests/probes/node_probes.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.mobile_ui._cancel()
	game.mobile_ui._start_raid()
	game.mobile_ui.paused = true
	game.dungeon.set_mobile_walls_visible(false)
	game.cam_zoom = 3.0
	var start := Vector2i(10, 4)
	var trap := Vector2i(11, 4)
	var landing := Vector2i(12, 4)
	game.grid[start.y][start.x] = GameTypes.Tile.FLOOR
	game.grid[trap.y][trap.x] = GameTypes.Tile.SPIKE
	game.grid[landing.y][landing.x] = GameTypes.Tile.FLOOR
	game.trap_charges[trap] = 3
	game.mobile_ui._center(trap)
	for kind in ["thief", "ranger"]:
		game.hero.erase("jumping_trap")
		game.hero.kind = kind
		game.hero.pos = start
		game.hero.known = {trap: GameTypes.Tile.SPIKE}
		game._sync_world()
		game.grid[landing.y][landing.x] = GameTypes.Tile.DOOR
		game.door_hp[landing] = 100
		assert(not game.raid._try_trap_jump(start, trap), "Jump must not land inside a closed door")
		game.grid[landing.y][landing.x] = GameTypes.Tile.FLOOR
		game.door_hp.erase(landing)
		assert(game.raid._try_trap_jump(start, trap))
		for frame in 5:
			var progress := frame / 4.0
			game.hero.jump_t = GameTypes.TRAP_JUMP_TIME * (1.0 - progress)
			game._sync_world()
			var model: Node3D = game.dungeon._vulpin if kind == "thief" else game.dungeon._batrafian
			var player := PROBES.first_animation_player(PROBES.child(model, "JumpTrap"))
			var clip := player.get_animation_list()[0]
			var animation := player.get_animation(clip)
			player.play(clip)
			player.seek(animation.length * progress, true)
			player.pause()
			for i in 3:
				await process_frame
			var position: Vector3 = game.dungeon._hero.position
			assert(absf(position.x - (start.x + 0.5 + 2.0 * progress)) < 0.001)
			assert(absf(position.z - (start.y + 0.5)) < 0.001)
			assert(root.get_texture().get_image().save_png("res://artifacts/jump-%s-%d.png" % [kind, frame]) == OK)
			print(kind, " phase=", progress, " grid_render=", position)
	game.queue_free()
	await process_frame
	print("OK: two heroes cross exactly one trap at synchronized jump phases")
	quit()
