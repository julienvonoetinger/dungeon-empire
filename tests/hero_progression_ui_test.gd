extends SceneTree

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
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.raid._start_raid()
	game.hero.name = "Neris de la confrerie des serruriers du Nord 12345"
	game.hero.level = 100
	game.dungeon.sync(game)
	ui._sync_hero_badge()
	check(ui.hero_badge.name_label.text == game.hero.name and ui.hero_badge.level_label.text == "100", "personal name and level remain visible")
	check(ui.hero_badge.level_label.position.x + ui.hero_badge.level_label.size.x <= ui.hero_badge.size.x, "level fits compact badge")
	game.raid.raid_active = false
	for viewport_size in [Vector2i(1280, 720), Vector2i(720, 1280)]:
		root.size = viewport_size
		await process_frame
		ui._layout()
		ui._raid_finished({"raid_id": 10000 + viewport_size.y, "killed": 0, "escaped": 1,
			"hero_name": "Neris de la confrerie des serruriers du Nord 12345, Vulpin Thief (Greedy)",
			"hero_xp_gained": 55, "hero_xp_total": 55, "hero_level_before": 1, "hero_level_after": 2,
			"hero_xp_breakdown": {"survival": 10, "gold": 30, "locks": 15, "obstacles": 0, "core": 0, "discovery": 0}})
		for frame in 4:
			await process_frame
		check(not ui.modal_body.text.contains("55 XP") and not ui.modal_body.text.contains("Neris"), "hero XP stays internal")
		check(not ui.modal_body.text.contains("1 -> 2"), "hero level gains are not announced")
		check(not ui.modal_body.text.contains("Serrures") and not ui.modal_body.text.contains("Survie"), "hero XP breakdown is hidden")
		check(ui.modal_body.text.contains("XP") and ui.modal_body.text.contains("Cœur niveau"), "player Core rewards remain visible")
		var button: Rect2 = ui.modal_continue.get_global_rect()
		check(Rect2(Vector2.ZERO, ui.size).encloses(button), "continue button fits viewport")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/hero-progression-%d.png" % viewport_size.x)
	ui._raid_finished({"raid_id": 20000, "killed": 1, "hero_xp_gained": 0})
	check(not ui.modal_body.text.contains("Neris") and not ui.modal_body.text.contains("1 -> 2"), "death does not retain survivor progression")
	game.queue_free()
	await process_frame
	print("Hero progression UI failures: ", failures)
	quit(1 if failures else 0)
