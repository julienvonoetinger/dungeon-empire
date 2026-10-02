extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var badge = preload("res://scripts/mobile/vault_badge.gd").new()
	badge.set_amount(75, 150)
	assert(badge.amount == 75 and is_equal_approx(badge.ratio, 0.5))
	badge.set_amount(0, 150)
	assert(badge.ratio == 0.0)
	badge.set_amount(150, 150)
	assert(badge.ratio == 1.0)
	assert(badge.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	badge.free()
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.gold = 75
	game._sync_world()
	ui._sync_vault_badges()
	assert(ui.vault_badges.size() == 2)
	assert(ui.vault_badges[Vector2i(2, 3)].amount == 75)
	assert(is_equal_approx(ui.vault_badges[Vector2i(2, 3)].ratio, 0.5))
	game.gold = 0
	ui._sync_vault_badges()
	assert(ui.vault_badges[Vector2i(2, 3)].ratio == 0)
	game._new_map()
	ui._sync_vault_badges()
	assert(ui.vault_badges.is_empty(), "restart removes old vault labels")
	game.queue_free()
	await process_frame
	print("OK: vault amount and remaining-stock ring")
	quit()
