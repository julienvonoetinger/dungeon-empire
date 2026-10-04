extends SceneTree

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
	game.gold = 0
	game.sim.vault_gold.clear()
	for index in 3:
		game.raid._start_raid()
		game.raid._hero_escapes()
		game.raid._update_hero(GameTypes.TURN_TIME + 0.01)
		assert(game.gold == 0, "Repeated escaped raids must never regenerate treasury gold")
		assert(not game.game_over and game._ready_for_raid(), "Zero gold still permits future raids")
		assert("Or disponible : 0" in ui.modal_body.text and "Or au sol : 0" in ui.modal_body.text)
		assert(not "+30 or" in ui.modal_body.text)
	game.raid._start_raid()
	game.hero.kind = "paladin"
	game.hero.carried_gold = 37
	game.raid._kill_hero()
	assert(game.gold == 0 and game.sim._unsecured_loot_total() == 37, "Only the actual carried loot is dropped")
	assert("Or au sol : 37" in ui.modal_body.text)
	ui.result_open = false
	ui.modal.hide()
	ui.selected = game.sim.loot_bags[0].pos
	ui._collect()
	assert(game.gold == 37 and game.sim._unsecured_loot_total() == 0, "A bankrupt dungeon can recover dropped gold")
	assert(ui.profile.xp > 0, "Core XP rewards remain")
	game.queue_free()
	await process_frame
	print("OK: no raid gold creation, zero-gold raids, real loot recovery and clear totals")
	quit()
