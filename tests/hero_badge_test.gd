extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(ResourceLoader.exists("res://scripts/mobile/hero_badge.gd"), "hero portrait health badge must exist")
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.raid._start_raid()
	assert(game.hero.level == 1, "baseline hero level is independent of raid number")
	game.hero.pos = Vector2i(10, 5)
	game.hero.name = "Vulpin Thief"
	game.hero.level = 7
	game.hero.max_hp = 100
	game.dungeon.sync(game)
	ui._center(game.hero.pos)
	for kind in ["thief", "paladin", "ranger", "mage"]:
		game.hero.kind = kind
		for hp in [100, 62, 1, 0, 100]:
			game.hero.hp = hp
			ui._sync_hero_badge()
			assert(is_equal_approx(ui.hero_badge.ratio, hp / 100.0))
			assert(ui.hero_badge.icon == ui.portraits[kind])
	assert(ui.hero_badge.name_label.text == "Vulpin Thief")
	assert(ui.hero_badge.level_label.text == "7")
	assert(ui.hero_badge.size.x < 220, "short hero name must not retain a wide fixed tab")
	var compact_width: float = ui.hero_badge.size.x
	game.hero.name = "Li"
	ui._sync_hero_badge()
	assert(ui.hero_badge.size.x < compact_width, "tab width follows text length")
	game.hero.hp = 12
	ui._sync_hero_badge()
	var stable_width: float = ui.hero_badge.size.x
	game.hero.hp = 100
	ui._sync_hero_badge()
	assert(ui.hero_badge.size.x == stable_width, "health changes do not resize the tab")
	game.hero.name = "Vulpin Thief"
	ui._sync_hero_badge()
	assert(ui.hero_badge.size.x == compact_width and ui.hero_badge.size.y == 42, "portrait diameter remains unchanged")
	assert(ui.hero_badge.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var anchor: Vector2 = game.dungeon.hero_screen_anchor(0.7)
	var expected: Vector2 = anchor * ui.size / Vector2(game.dungeon.camera.get_viewport().size) - Vector2(21, 50)
	assert(ui.hero_badge.position.distance_to(expected) < 0.1, "portrait follows rendered hero anchor")
	game.hero.kind = "ranger"
	game.hero.name = "Batrafian Ranger"
	game.hero.hp = 62
	game.dungeon.sync(game)
	ui._sync_hero_badge()
	if "--capture" in OS.get_cmdline_user_args():
		for frame in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/hero-badge.png")
	game.hero.pos = Vector2i(12, 5)
	game.hero.jumping_trap = true
	game.hero.jump_from = Vector2i(10, 5)
	game.hero.facing = Vector2i.RIGHT
	var previous := Vector2.ZERO
	for progress in [0.0, 0.25, 0.5, 0.75, 1.0]:
		game.hero.jump_t = GameTypes.TRAP_JUMP_TIME * (1.0 - progress)
		game.dungeon.sync(game)
		ui._sync_hero_badge()
		var projected: Vector2 = game.dungeon.hero_screen_anchor(0.7) * ui.size / Vector2(game.dungeon.camera.get_viewport().size)
		assert(ui.hero_badge.position.distance_to(projected - Vector2(21, 50)) < 0.1)
		if progress > 0:
			assert(ui.hero_badge.position.distance_to(previous) > 1.0, "badge follows interpolated jump, not destination tile")
		previous = ui.hero_badge.position
		if progress == 0.5 and "--capture" in OS.get_cmdline_user_args():
			for frame in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/hero-badge-jump.png")
	game.hero.erase("jumping_trap")
	game.hero.erase("jump_t")
	game.hero.kind = "paladin"
	game.hero.name = "Lithide Paladin"
	for viewport_size in [Vector2i(1280, 720), Vector2i(720, 960)]:
		root.size = viewport_size
		for frame in 3:
			await process_frame
		ui._center(game.hero.pos)
		game.dungeon.sync(game)
		ui._sync_hero_badge()
		assert(ui.hero_badge.visible, "hero badge remains visible in landscape and portrait")
		assert(ui.hero_badge.name_label.get_rect().end.x < ui.hero_badge.level_label.position.x, "name and level never overlap")
		for badge in ui.trap_badges.values():
			assert(not badge.visible or not badge.get_rect().intersects(ui.hero_badge.get_rect()), "trap badges never cover hero name")
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/hero-badge-%dx%d.png" % [viewport_size.x, viewport_size.y])
	game.raid_active = false
	ui._sync_hero_badge()
	assert(not ui.hero_badge.visible)
	game.queue_free()
	await process_frame
	print("OK: hero portrait, health ring, name, actual level and raid visibility")
	quit()
