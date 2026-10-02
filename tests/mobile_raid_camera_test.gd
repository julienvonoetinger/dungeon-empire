extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for automatic in [false, true]:
		var game = load("res://Main.tscn").instantiate()
		game.persistence_enabled = false
		root.add_child(game)
		await process_frame
		game.set_process(false)
		preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
		var ui = game.mobile_ui
		ui._cancel()
		ui.paused = false
		ui.following = false
		game.cam_zoom = 1.8
		ui._center_core()
		var pan: Vector2 = game.cam_pan
		var yaw: float = game.cam_yaw
		if automatic:
			game.raid_timer = 0
			ui.tick(0.0)
		else:
			ui._start_raid()
		check(game.raid_active, "Fixture launches a raid")
		check(not ui.following, "Raid does not enable automatic follow")
		check(is_equal_approx(game.cam_zoom, 1.8), "Raid preserves player zoom")
		ui.paused = true
		for cell in [Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7)]:
			game.hero.pos = cell
			ui.tick(0.016)
			check(game.cam_pan.is_equal_approx(pan), "Hero cell changes do not move camera")
			check(is_equal_approx(game.cam_yaw, yaw), "Hero movement preserves camera rotation")
		ui._toggle_follow()
		check(ui.following, "Explicit follow remains available")
		ui._pan(Vector2(12, 0))
		check(not ui.following, "Manual pan cancels explicit follow")
		var manual_pan: Vector2 = game.cam_pan
		game.hero.pos = Vector2i(7, 7)
		ui.tick(0.016)
		check(game.cam_pan.is_equal_approx(manual_pan), "Camera stays where manually positioned")
		game.queue_free()
		await process_frame
	print("Raid camera: manual and timed entry, hero steps, explicit follow and manual pan; failures=", failures)
	quit(1 if failures else 0)
