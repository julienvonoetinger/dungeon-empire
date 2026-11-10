extends SceneTree
## Exercise the Doors toolbar and the real viewport without player saves.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const OUT := "res://artifacts/build-strip/"
const Catalog = preload("res://scripts/game/ui/hud_catalog.gd")
const TOOLS := [GameTypes.Tool.BUILD_DOOR, GameTypes.Tool.BUILD_REINFORCED_DOOR, GameTypes.Tool.BUILD_MAGIC_DOOR]
const TILES := [GameTypes.Tile.DOOR, GameTypes.Tile.REINFORCED_DOOR, GameTypes.Tile.MAGIC_DOOR]
var game: IsometricGameSession
var hud
var menu
var doors: Button
var traps: Button
var chests: Button
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 6: await process_frame

func press(point: Vector2, down: bool, touch := false) -> void:
	var event: InputEvent
	if touch:
		event = InputEventScreenTouch.new()
	else:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
	event.position = point * hud.scale.x
	event.pressed = down
	root.push_input(event, true)

func tap(point: Vector2, touch := false) -> void:
	press(point, true, touch)
	press(point, false, touch)
	await settle()

func open_menu() -> void:
	await tap(doors.get_global_rect().get_center())
	check(menu.visible and game.catalog_open, "Doors opens the picker and suspends preparation")

func tap_site(cell: Vector2i, touch: bool) -> void:
	var view = game.get_node("PlayArea/World/Dungeon")
	var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
	camera.position = view.grid_to_local(Vector2(cell) + Vector2(.5, .5))
	camera.force_update_scroll()
	await settle()
	# A real mouse following a touch must outlast the synthetic-mouse guard.
	if not touch: await create_timer(.55).timeout
	for block in hud.dig_targets.blocks:
		if block.cell != cell: continue
		var centre: Vector2 = block.preview.get_global_transform_with_canvas().origin / hud.scale.x
		for offset in [Vector2.ZERO, Vector2.LEFT * 3, Vector2.RIGHT * 3]:
			var point := centre + Vector2(offset)
			if hud.dig_targets.hit_cell(point) == cell:
				await tap(point, touch)
				return
	check(false, "The floating marker has a tappable door pixel")

func snapshot(filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if menu.visible:
		var pixels: Vector2 = Vector2(frame.get_size()) / hud.root.size
		var shelf := Rect2i((menu.shelf.position * pixels).round(), (menu.shelf.size * pixels).round())
		var bar := Rect2i((hud.footer.position * pixels).round(), (hud.footer.size * pixels).round())
		check(solid_row(frame, shelf.position.x, shelf.end.x, shelf.position.y), "Model row has a continuous upper edge at " + filename)
		check(solid_row(frame, bar.position.x, bar.end.x, bar.position.y), "Toolbar has a full-width upper edge at " + filename)
		for y in [bar.position.y - 1, bar.position.y + 1]:
			check(not solid_row(frame, shelf.position.x, shelf.end.x, y), "Only one stroke at the join at " + filename)
	frame.save_png(OUT + filename + ".png")

func solid_row(frame: Image, left: int, right: int, y: int) -> bool:
	var first := frame.get_pixel(left, y)
	for x in range(left + 1, right):
		if frame.get_pixel(x, y) != first: return false
	return true

func check_choice_buttons() -> void:
	check(is_equal_approx(menu.shelf.end.y, hud.footer.position.y), "Shelf touches the toolbar")
	check(absf(menu.shelf.get_center().x - hud._safe.get_center().x) <= 1, "Shelf stays centered")
	for i in menu.choices.size():
		var card: Rect2 = menu.cards[i]
		check(card.size.y >= 48 and card.size.x >= 48, "Each model has a finger-sized target")
		check(menu._choice_at(card.position + Vector2.ONE) == i and menu._choice_at(card.end - Vector2.ONE) == i, "Card corners select the same model")
		var price: String = str(menu.choices[i][2]).trim_suffix(" gold")
		check(menu.price_badge(price).size.x + 38 < card.size.x, "Price and icon fit inside the card")
		if i > 0:
			var previous: Rect2 = menu.cards[i - 1]
			check(is_equal_approx(previous.end.x, card.position.x) and is_equal_approx(previous.position.y, card.position.y), "Models share a single horizontal row")
	check(menu._choice_at(menu.shelf.position - Vector2.ONE) == menu.OUTSIDE, "Outside the shelf cannot choose a model")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game = GAME.instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	hud = game.get_node("HUD")
	menu = hud.build_menu
	doors = hud.build_buttons[Catalog.DOORS]
	traps = hud.build_buttons[Catalog.TRAPS]
	chests = hud.build_buttons[Catalog.CHESTS]
	hud._welcome = false
	game.restart(true)
	game.notice = ""
	game.cancel_selection()
	for child in hud.root.get_children():
		if child.has_meta("transient_feedback"): child.queue_free()
	await settle()
	# A window losing focus during startup can pause the fixture.
	game.set_paused(false)
	check(doors.get_index() == hud.dig_button.get_index() + 1, "Doors is immediately to the right of Dig")
	check(hud.utilities.get_children() == [hud.dig_button, doors, traps, chests], "Only Dig, Doors, Traps and Chests appear, in order")
	check(not doors.visible and not traps.visible and chests.get_meta("words").text == "Gold bag", "Level one offers bags and no defense families")
	game.progression.grant_tutorial_level(2)
	game.changed.emit(false)
	await settle()
	check(not traps.visible and doors.visible, "The carpenter teaches only the standard door")
	await tap(doors.get_global_rect().get_center())
	check(game.tool == GameTypes.Tool.BUILD_DOOR and not menu.visible, "Click selects the standard door directly")
	await tap(doors.get_global_rect().get_center())
	check(game.tool == GameTypes.Tool.NONE, "A second click stops placement")
	game.progression.grant_tutorial_level(3)
	game.changed.emit(false)
	await settle()
	check(traps.get_meta("mark").texture == menu.TOOL_ICONS[GameTypes.Tool.TRAP_SPIKE], "Only the spike trap is taught at level three")
	await tap(traps.get_global_rect().get_center(), true)
	check(game.tool == GameTypes.Tool.TRAP_SPIKE and not menu.visible, "Touch selects the spike trap directly")
	await tap(traps.get_global_rect().get_center())
	var gold := game.sim.gold
	game.sim.gold = 5
	game.changed.emit(false)
	await tap(doors.get_global_rect().get_center())
	check(hud.pose_bar.visible and hud.pose_label.text.contains("35") and hud.pose_label.text.contains("5 / 40") and not doors.button_pressed, "A poor level-three player sees why a door cannot be placed")
	await tap(traps.get_global_rect().get_center())
	check(hud.pose_bar.visible and hud.pose_label.text.contains("30") and hud.pose_label.text.contains("5 / 35") and game.tool == GameTypes.Tool.NONE, "Spike rejection shows the exact shortfall")
	game.sim.gold = 0
	game.changed.emit(false)
	await tap(chests.get_global_rect().get_center())
	var cell_for_bag := Vector2i(4,8)
	check(game.tool == GameTypes.Tool.GOLD_BAG and not menu.visible, "Empty treasury can select a bag directly")
	await tap_site(cell_for_bag, false)
	check(game.sim.floor_gold.get(cell_for_bag) == 0 and game.sim.gold == 0 and game.sim.grid[8][4] == GameTypes.Tile.FLOOR, "Putting a bag on the map neither costs nor grants gold")
	check(not game.check_action(cell_for_bag, GameTypes.Tool.GOLD_BAG).valid, "Bags cannot stack")
	game.undo_build()
	game.cancel_selection()
	game.sim.gold = gold
	game.progression.grant_tutorial_level(4)
	game.changed.emit(false)
	check(Catalog.unlocked_items(Catalog.DOORS, game.progression).size() == 1 and Catalog.unlocked_items(Catalog.TRAPS, game.progression).size() == 1 and Catalog.unlocked_items(Catalog.CHESTS, game.progression).size() == 1, "Level four still only offers the taught models")
	# Exercise the picker and the retained advanced art in the isolated playtest only.
	game.progression.testing_unlock_defenses = true
	game.changed.emit(false)
	await tap(hud.dig_button.get_global_rect().get_center())
	await open_menu()
	check(game.tool == GameTypes.Tool.NONE and not hud.dig_button.button_pressed, "Opening Doors exits digging")
	var timer := game.raid.raid_timer
	game.advance_simulation(.1)
	check(game.raid.raid_timer == timer, "The raid countdown waits during selection")
	check(menu.choices.map(func(item): return item[0]) == TOOLS, "Playtest exposes all three door models")
	for extent in [Vector2i(960,540), Vector2i(320,568), Vector2i(568,299)]:
		root.size = extent
		await settle()
		check(menu.visible and menu.has_focus(), "Resizing preserves the picker at " + str(extent))
		check(hud._safe.encloses(hud.utilities.get_global_rect()), "Toolbar fits " + str(extent))
		check_choice_buttons()
		check(hud.footer.position.x == 0 and hud.footer.get_rect().end.is_equal_approx(hud.root.size), "Stone footer spans the bottom edge")
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			check(doors.get_theme_stylebox(state) is StyleBoxEmpty, "No inner frame around the family tab in " + state)
		check(doors.button_pressed, "Open family highlights its tab")
		check(hud.blocks_pointer(Vector2(1, hud.footer.position.y + 1) * hud.scale.x), "Footer margins intercept map taps")
		for i in TOOLS.size():
			var bounds: Rect2 = menu.cards[i]
			check(hud._safe.encloses(bounds) and not bounds.intersects(hud.utilities.get_global_rect()) and not bounds.intersects(hud.header.get_global_rect()), "Door button fits between header and toolbar at " + str(extent))
			check(menu._choice_at(menu.choice_point(i)) == i, "Each option has its own hit area at " + str(extent))
		await snapshot("%dx%d" % [extent.x, extent.y])
	await tap(doors.get_global_rect().get_center(), true)
	check(not menu.visible and game.tool == GameTypes.Tool.NONE and game.sim.gold == gold, "A second touch on Doors closes without buying")
	await open_menu()
	await tap(hud.dig_button.get_global_rect().get_center(), true)
	check(not menu.visible and game.tool == GameTypes.Tool.DIG and hud.dig_button.button_pressed, "A single touch switches to Dig")
	await open_menu()
	var view = game.get_node("PlayArea/World/Dungeon")
	await tap(traps.get_global_rect().get_center())
	check(menu.visible and menu.category == Catalog.TRAPS and menu.choices.map(func(item): return item[0]) == [GameTypes.Tool.TRAP_SPIKE, GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID], "A single click switches to the three unlocked traps")
	await snapshot("traps-landscape")
	root.size = Vector2i(960,540)
	await settle()
	await snapshot("atelier-paysage")
	root.size = Vector2i(320,568)
	await settle()
	await snapshot("atelier-portrait")
	root.size = Vector2i(568,299)
	await settle()
	await tap(chests.get_global_rect().get_center(), true)
	check(menu.visible and menu.category == Catalog.CHESTS and menu.choices.map(func(item): return item[0]) == [GameTypes.Tool.STORE, GameTypes.Tool.GOLD_BAG, GameTypes.Tool.STORE_LOCKED, GameTypes.Tool.STORE_MAGIC], "One touch switches directly from traps to chests")
	await snapshot("chests-landscape")
	root.size = Vector2i(320,568)
	await settle()
	check_choice_buttons()
	await snapshot("chests-portrait")
	await tap(hud.header.eye_button.get_global_rect().get_center())
	check(not menu.visible and game.paused and not game.catalog_open, "The master's eye opens pause on the first click")
	if game.paused: hud.handle_back()
	await open_menu()
	await tap(Vector2(15,150))
	check(not menu.visible and game.selected.x < 0 and game.sim.gold == gold, "Outside tap is consumed")
	await open_menu()
	hud.handle_back()
	check(not menu.visible and not game.paused, "Back dismisses without pausing")
	root.size = Vector2i(960,540)
	await settle()
	for i in TOOLS.size():
		await open_menu()
		await tap(menu.choice_point(i), i == 1)
		check(not menu.visible and game.tool == TOOLS[i] and game.sim.gold == gold, "Choosing only arms door " + str(i))
		check(doors.button_pressed, "The armed door lights the toolbar")
		if i == 0:
			check(hud.pose_bar.visible and is_equal_approx(hud.pose_bar.get_rect().end.y, hud.footer.position.y), "Placement instructions join the same stone strip")
			check(hud.stop_button.get_theme_stylebox("normal") is StyleBoxEmpty, "The Stop action has no nested frame")
			await snapshot("atelier-pose")
		var cell := Vector2i(4,8)
		check(cell in view._valid_cells and Vector2i(6,8) not in view._valid_cells, "Markers include free corridor and exclude spike trap")
		await tap_site(cell, i == 1)
		check(game.sim.grid[cell.y][cell.x] == TILES[i] and game.sim.gold == gold - GameTypes.fixed_tool_cost(TOOLS[i]), "Placement builds and charges exactly once for " + str(TOOLS[i]))
		game.undo_build()
		check(game.sim.gold == gold and game.sim.grid[cell.y][cell.x] == GameTypes.Tile.FLOOR, "Undo restores the placement fixture")
		game.cancel_selection()
	for group in [Catalog.TRAPS, Catalog.CHESTS]:
		await tap(hud.build_buttons[group].get_global_rect().get_center())
		await tap(menu.choice_point(0), true)
		var expected := GameTypes.Tool.TRAP_SPIKE if group == Catalog.TRAPS else GameTypes.Tool.STORE
		check(not menu.visible and game.tool == expected and game.sim.gold == gold, "Choosing a trap or chest only arms placement")
		var cell := Vector2i(4,8)
		if group == Catalog.TRAPS: await tap_site(cell, true)
		else: hud.world_tapped(cell)
		check(game.sim.grid[cell.y][cell.x] == (GameTypes.Tile.SPIKE if group == Catalog.TRAPS else GameTypes.Tile.VAULT), "The chosen trap or chest builds on free floor")
		game.undo_build()
		game.cancel_selection()
	var vault := Vector2i(7,7)
	game.sim.vault_locks[vault] = 1
	game.sim.gold = GameTypes.VAULT_PROTECTION_COSTS[2] - GameTypes.VAULT_PROTECTION_COSTS[1]
	game.changed.emit(true)
	await tap(chests.get_global_rect().get_center())
	await tap(menu.choice_point(3))
	check(game.tool == GameTypes.Tool.STORE_MAGIC and not menu.visible, "An affordable upgrade can be chosen with less than the full new chest price")
	hud.world_tapped(vault)
	game.confirm_action()
	check(game.sim.vault_locks.get(vault) == 2 and game.sim.gold == 0, "Upgrading charges only the extra protection")
	game.cancel_selection()
	game.sim.gold = GameTypes.COST_DOOR
	await open_menu()
	await tap(menu.choice_point(2))
	check(menu.visible and hud.hint.visible and hud.hint.text.contains("40 / 80") and game.tool == GameTypes.Tool.NONE and game.sim.gold == GameTypes.COST_DOOR, "Unaffordable model explains its price and leaves the shelf open")
	press(menu.choice_point(0), true)
	press(menu.choice_point(1), false)
	await settle()
	check(menu.visible and game.tool == GameTypes.Tool.NONE, "Dragging between door buttons cannot select")
	press(menu.choice_point(0), true, true)
	root.size = Vector2i(568,320)
	await settle()
	press(menu.choice_point(0), false, true)
	check(menu.visible and game.tool == GameTypes.Tool.NONE, "Rotation cancels a pending finger press")
	game.set_paused(true)
	check(not menu.visible and not game.catalog_open, "Pause closes the picker")
	game.set_paused(false)
	await settle()
	await open_menu()
	game.restart(true)
	check(not menu.visible and not game.catalog_open, "Restart clears popup state")
	game.cancel_selection()
	game.start_raid()
	check(not doors.visible and not menu.visible, "Raid hides the door tools")
	game.queue_free()
	await process_frame
	print("Build toolbar: %d checks, %d failures" % [checks, failures])
	quit(int(failures != 0))
