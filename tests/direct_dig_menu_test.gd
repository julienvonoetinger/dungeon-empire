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
	var ui = game.mobile_ui
	ui.paused = false
	ui._cancel()
	ui._layout()
	ui._refresh()
	assert(ui.category_buttons[0].tooltip_text == "Portes")
	assert(ui.category_buttons[1].tooltip_text == "Coffres")
	assert(ui.category_buttons[2].tooltip_text == "Pièges")
	assert(ui._dig_enabled(), "digging is available without opening a menu")
	game.dungeon.set_mobile_walls_visible(false)
	game.dungeon.sync(game)
	ui._center_core()
	ui._update_dig_hover()
	assert(Vector2i(4, 6) in ui.diggable_cells and Vector2i(0, 0) not in ui.diggable_cells)
	var hint = ui.get("dig_hint")
	assert(hint != null, "dig hover has a compact price hint")
	assert(not hint.visible, "idle cells have no repeated price labels")
	ui._dig_pointer = _point(game, Vector2i(4, 6))
	ui._dig_pointer_over_ui = false
	ui._update_dig_hover()
	assert(hint.visible and hint.mouse_filter == Control.MOUSE_FILTER_IGNORE, "hover hint does not steal digging clicks")
	var corners := PackedVector2Array([Vector2.ZERO, Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	var lines: PackedVector2Array = ui._dig_corner_lines(corners)
	assert(lines.size() == 16, "four corners use eight short strokes, not a full outline")
	for i in range(0, lines.size(), 2):
		assert(is_equal_approx(lines[i].distance_to(lines[i + 1]), 18.0))
	ui._dig_pointer_over_ui = true
	ui._update_dig_hover()
	assert(not hint.visible, "no price hint over UI")
	var before: int = game.gold
	ui._tap(_point(game, Vector2i(4, 6)))
	assert(game.grid[6][4] == GameTypes.Tile.FLOOR and game.gold == before - 5)
	assert(ui.selected.x < 0 and not ui.actions.visible, "digging never opens confirmation")
	for index in 3:
		ui._category(index)
		var expected: Array = [[GameTypes.Tool.BUILD_DOOR, GameTypes.Tool.BUILD_MAGIC_DOOR, GameTypes.Tool.BUILD_ENTRANCE], [GameTypes.Tool.STORE, GameTypes.Tool.STORE_LOCKED, GameTypes.Tool.STORE_MAGIC], [GameTypes.Tool.TRAP_SPIKE, GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID]][index]
		for id in ui.buttons:
			assert(ui.buttons[id].button.visible == (id in expected), "category exposes only its own tools")
		ui._choose_tool(expected[0])
		assert(not ui._dig_enabled(), "placement suspends digging")
		ui._update_dig_hover()
		assert(ui.diggable_cells.is_empty())
		ui._toggle_tray()
		assert(ui._dig_enabled() and ui.tool == GameTypes.Tool.NONE, "back cancels placement and restores digging")
	game.sim.grid[6][5] = GameTypes.Tile.VAULT
	game.dungeon.sync(game)
	ui._tap(_point(game, Vector2i(5, 6)))
	assert(ui.vault_transfer.visible and not ui._dig_enabled(), "chest interaction wins over default digging")
	ui.vault_transfer.close()
	game.corpses.append({"pos": Vector2i(4, 6), "name": "Test", "fear": 18.0})
	ui._tap(_point(game, Vector2i(4, 6)))
	assert(ui.tool == GameTypes.Tool.ABSORB and ui.actions.visible, "corpse absorption stays accessible without Core menu")
	ui._confirm()
	assert(game.corpses.is_empty() and ui._dig_enabled(), "absorption returns to direct digging")
	game.loot_bags.append({"pos": Vector2i(4, 6), "gold": 10, "taken": false})
	game.gold = 100
	ui._tap(_point(game, Vector2i(4, 6)))
	assert(ui.actions.visible and ui.collect.visible and not ui.collect.disabled)
	ui._collect()
	assert(game.gold == 110 and game.loot_bags.is_empty(), "ground loot remains collectible without Core menu")
	ui._cancel()
	game.gold = 0
	ui._update_dig_hover()
	assert(ui.diggable_cells.is_empty(), "unaffordable cells are not offered")
	game.gold = 100
	game.sim.grid[6][4] = GameTypes.Tile.ENTRANCE
	ui._update_dig_hover()
	assert(Vector2i(3, 6) not in ui.diggable_cells, "entrance support is never offered")
	game.raid_active = true
	ui._update_dig_hover()
	assert(ui.diggable_cells.is_empty() and not ui._dig_enabled())
	game.raid_active = false
	if "--capture" in OS.get_cmdline_user_args():
		ui._update_dig_hover()
		game.dungeon.sync(game)
		ui._refresh()
		for frame in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/direct-dig-menu.png")
		ui._dig_pointer = _point(game, Vector2i(9, 6))
		ui._dig_pointer_over_ui = false
		ui._update_dig_hover()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/gold-dig-hover.png")
		for index in 3:
			ui._category(index)
			ui._choose_tool(ui.CATEGORIES[index][0])
			ui._update_dig_hover()
			for frame in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/direct-dig-category-%d.png" % index)
			ui._toggle_tray()
	game.queue_free()
	await process_frame
	print("OK: three construction menus, direct digging, highlights, costs and guards")
	quit()

func _point(game, cell: Vector2i) -> Vector2:
	var center: Vector2 = game._cell_pos(cell)
	for y in range(-64, 65, 4):
		for x in range(-64, 65, 4):
			var point := center + Vector2(x, y)
			if game._screen_to_grid(point) == cell:
				return point
	assert(false, "cell must be pickable")
	return center
