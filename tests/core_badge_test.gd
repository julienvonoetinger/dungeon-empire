extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	for hp in [100, 75, 1, 0, 100]:
		game.core_hp = hp
		ui._sync_core_badge()
		assert(is_equal_approx(ui.core_badge.ratio, hp / 100.0))
		assert(ui.core_badge.amount == hp)
	assert(ui.core_badge.size == Vector2(42, 42))
	assert(ui.core_badge.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(ui.core_badge.get_child_count() == 0)
	game._new_map()
	ui._sync_core_badge()
	assert(not ui.core_badge.visible)
	game.queue_free()
	await process_frame
	print("OK: core health ring, damage, healing, zero health and unplaced core")
	quit()
