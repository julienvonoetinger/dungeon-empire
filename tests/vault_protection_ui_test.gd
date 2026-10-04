extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._place_core(Vector2i(6, 6))
	game.queue_redraw()
	var ui = game.mobile_ui
	ui.paused = false
	ui._cancel()
	ui._category(1)
	assert(ui.buttons.has(GameTypes.Tool.STORE_LOCKED), "Chest menu lacks locked chest")
	assert(ui.buttons.has(GameTypes.Tool.STORE_MAGIC), "Chest menu lacks magic chest")
	var cells := [Vector2i(5, 6), Vector2i(5, 7), Vector2i(5, 8)]
	game.gold = 320
	for tier in 3:
		assert(game.sim.build_vault(cells[tier], tier))
	game.sim.vault_gold = {cells[0]: 80, cells[1]: 70, cells[2]: 50}
	game.dungeon.set_mobile_walls_visible(false)
	game.dungeon.sync(game)
	ui._center_core()
	ui._refresh()
	ui._sync_vault_badges()
	var dialog = ui.vault_transfer
	dialog.open(cells[0])
	assert(dialog.visible and not dialog.upgrade_locked.disabled and not dialog.upgrade_magic.disabled)
	dialog._protect(1)
	assert(game.sim.vault_locks[cells[0]] == 1 and dialog.visible)
	assert(not dialog.upgrade_locked.visible and dialog.upgrade_magic.visible)
	assert(game.sim._storage_state().vaults[cells[1]] == 70, "Upgrade does not redistribute untouched chest")
	game.sim.vault_opened[cells[0]] = true
	dialog.close()
	dialog.open(cells[0])
	assert(dialog.repair.visible and not dialog.repair.disabled)
	dialog._repair()
	assert(game.sim.vault_protected(cells[0]) and not dialog.repair.visible)
	dialog.close()
	ui.profile.testing_unlock_defenses = false
	ui.profile.xp = 0
	dialog.open(cells[0])
	assert(dialog.upgrade_magic.disabled, "Upgrade respects magic level unlock")
	dialog.close()
	ui.profile.testing_unlock_defenses = true
	ui._refresh()
	game.dungeon.sync(game)
	# Scene sprites must change on opening, without moving the grounding anchor.
	var locked_sprite: Sprite3D = _sprite(game.dungeon, "chest-locked-v1.png")
	var sealed_sprite: Sprite3D = _sprite(game.dungeon, "chest-sealed-v1.png")
	assert(locked_sprite != null and sealed_sprite != null, "Intact protections use closed chest assets")
	var anchor := sealed_sprite.global_position
	game.sim.vault_opened[cells[2]] = true
	game.dungeon.sync(game)
	assert(_sprite(game.dungeon, "chest-sealed-v1.png") == null)
	assert(_sprite(game.dungeon, "chest-sealed-open-full-v1.png") != null, "Opened magic chest retains its inactive seal and visible stock")
	game.sim.vault_opened[cells[1]] = true
	game.dungeon.sync(game)
	assert(_sprite(game.dungeon, "chest-locked-open-full-v1.png") != null, "Opened locked chest retains its unfastened padlock")
	var original_balances: Dictionary = game.sim.vault_gold.duplicate(true)
	var original_gold: int = game.gold
	game.gold = 0
	game.sim.vault_gold = {}
	game.dungeon.sync(game)
	assert(_sprite(game.dungeon, "chest-locked-open-empty-v1.png") != null)
	assert(_sprite(game.dungeon, "chest-sealed-open-empty-v1.png") != null, "Empty variants never keep interior gold")
	game.gold = original_gold
	game.sim.vault_gold = original_balances
	game.sim.vault_opened.erase(cells[1])
	game.dungeon.sync(game)
	var open_at_anchor := false
	for node in game.dungeon.find_children("MobileProp", "Sprite3D", true, false):
		if node.global_position.is_equal_approx(anchor):
			open_at_anchor = true
	assert(open_at_anchor, "Opening must preserve the chest position")
	game.raid_active = true
	game.hero = {"kind": "thief", "pos": cells[1], "hp": 68, "max_hp": 68, "fleeing": false, "facing": Vector2i.DOWN, "lockpicking": true, "lockpick_pos": cells[1]}
	game.dungeon._sync_hero(game)
	var hero: Node3D = game.dungeon.get("_hero")
	assert(hero.position.z < cells[1].y + 0.5 - 0.1, "Lockpicking stands beside the chest, not inside it")
	game.raid_active = false
	game.hero = {}
	game.sim.vault_opened.erase(cells[2])
	game.sim.vault_locks.erase(cells[0])
	game.dungeon.sync(game)
	ui._sync_vault_badges()
	if "--capture" in OS.get_cmdline_user_args():
		ui.queue_redraw()
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/vault-protection-menu.png")
		for state in ["full", "empty"]:
			game.sim.vault_opened[cells[1]] = true
			game.sim.vault_opened[cells[2]] = true
			if state == "empty":
				game.gold = 0
				game.sim.vault_gold = {}
			game.dungeon.sync(game)
			ui._sync_vault_badges()
			ui._refresh()
			for frame in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/vault-open-%s.png" % state)
		game.gold = original_gold
		game.sim.vault_gold = original_balances
		game.sim.vault_opened.clear()
		game.dungeon.sync(game)
		ui._sync_vault_badges()
		dialog.open(cells[0])
		for frame in 2:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/vault-protection-dialog.png")
	dialog.close()
	root.size = Vector2i(720, 400)
	for frame in 3:
		await process_frame
	dialog.open(cells[0])
	dialog._choose_destination()
	for frame in 3:
		await process_frame
	assert(dialog.panel.get_global_rect().position.y >= 0 and dialog.panel.get_global_rect().end.y <= ui.size.y, "Chest management fits a short landscape screen")
	game.queue_free()
	await process_frame
	print("OK: chest protection menu, upgrades, relocking, level gates and closed/open visuals")
	quit()

func _sprite(world: Node, filename: String) -> Sprite3D:
	for node in world.find_children("MobileProp", "Sprite3D", true, false):
		if node.texture == world.get("_mobile_chest_textures").get("res://assets/mobile/" + filename):
			return node
	return null
