extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.gold = 100
	game.sim.vault_gold.clear()
	ui.paused = false
	ui.modal.hide()
	ui._cancel()
	game._sync_world()
	ui._sync_vault_badges()
	var cells: Array = game._storage_state().vaults.keys()
	var dialog = ui.vault_transfer
	ui.vault_badges[cells[0]].get_child(0).pressed.emit()
	assert(dialog.visible and ui.paused)
	dialog.choose.pressed.emit()
	assert(dialog.options.visible and dialog.quantity.max_value == 100)
	dialog.quantity.value = 30
	dialog.submit.pressed.emit()
	assert(not dialog.visible and not ui.paused)
	assert(game.gold == 100)
	assert(ui.vault_badges[cells[0]].amount == 70)
	assert(ui.vault_badges[cells[1]].amount == 30)
	dialog.open(cells[0])
	dialog._choose_destination()
	dialog._transfer_all()
	assert(ui.vault_badges[cells[0]].amount == 0)
	assert(ui.vault_badges[cells[1]].amount == 100)
	dialog.open(cells[0])
	assert(dialog.choose.disabled)
	dialog.close()
	dialog.open(cells[1])
	dialog.close()
	assert(game._storage_state().vaults[cells[1]] == 100, "Cancel preserves amounts")
	game.raid_active = true
	dialog.open(cells[1])
	assert(not dialog.visible)
	game.raid_active = false
	dialog.open(cells[1])
	ui._pause_menu()
	assert(not dialog.visible and ui.modal.visible and ui.paused)
	game.queue_free()
	await process_frame
	print("OK: vault dialog, partial/all transfers, live badges, empty and raid guards, cancel and focus loss")
	quit()
