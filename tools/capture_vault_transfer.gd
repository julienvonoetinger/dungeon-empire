extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	assert(ui.save_api.apply(ui.save_api.read_save("res://artifacts/chest-user-repro.save"), game.sim, game.raid, ui.profile))
	ui.modal.hide()
	ui.paused = true
	ui._cancel()
	game.cam_zoom = 3.5
	ui._center(Vector2i(7, 1))
	game.gold = 120
	game.sim.vault_gold.clear()
	game._sync_world()
	ui._sync_vault_badges()
	ui.paused = false
	ui.vault_transfer.open(Vector2i(5, 0))
	ui.vault_transfer._choose_destination()
	ui.vault_transfer.quantity.value = 40
	for dimensions in [Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = dimensions
		for frame in 8:
			await process_frame
		var bounds: Rect2 = ui.vault_transfer.panel.get_global_rect()
		assert(root.get_texture().get_image().save_png("res://artifacts/vault-transfer-%d.png" % dimensions.x) == OK)
		print("Panel ", bounds, " UI ", ui.size)
		assert(Rect2(Vector2.ZERO, ui.size).encloses(bounds), "Transfer panel fits viewport")
	print("OK: transfer dialog captured at desktop and mobile landscape sizes")
	quit()
