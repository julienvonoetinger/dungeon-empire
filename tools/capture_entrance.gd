extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game._sync_world()
	game.mobile_ui.paused = true
	game.mobile_ui.modal.hide()
	game.mobile_ui._cancel()
	game.cam_zoom = 2.8
	var entrance: Vector2i = game.sim._find_tile(GameTypes.Tile.ENTRANCE)
	assert(entrance == Vector2i(2, 10))
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		game.mobile_ui._center(entrance)
		for shown in [true, false]:
			game.dungeon.set_mobile_walls_visible(shown)
			for i in 12:
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/entrance-%s-%d.png" % ["shown" if shown else "hidden", yaw]) == OK)
	game.cam_yaw = 45
	game.mobile_ui.paused = false
	game.mobile_ui._start_raid()
	assert(game.raid_active and game.hero.pos == entrance)
	game.mobile_ui.paused = true
	game.mobile_ui._center(entrance)
	root.size = Vector2i(960, 540)
	for i in 12:
		await process_frame
	assert(is_equal_approx(game.dungeon._mobile_hero_ground(entrance, game), game.dungeon.FLOOR_H))
	assert(root.get_texture().get_image().save_png("res://artifacts/entrance-hero-small.png") == OK)
	game.hero.pos = entrance + game.sim._entrance_mouth(entrance)
	for i in 12:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/entrance-hero-exit.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: wall entrance four angles, both wall states, hero grounded at entrance")
	quit()
