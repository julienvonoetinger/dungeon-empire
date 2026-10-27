extends SceneTree
## Native viewport-rotation checks. No player saves or Android sensor simulation.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
var failures: Array[String] = []
var checks := 0
var records: Array = []
var out := "res://artifacts/mobile-rotation-after/"

func _initialize() -> void:
	if "--before" in OS.get_cmdline_user_args(): out = "res://artifacts/mobile-rotation-before/"
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle() -> void:
	for i in 8: await process_frame

func capture(hud: CanvasLayer, state: String) -> void:
	await settle()
	var panels: Array[Control] = [hud.header, hud.utilities, hud.speeds, hud.pose_bar, hud.catalog, hud.selection, hud.radial, hud.modal]
	for panel in panels:
		if panel.is_visible_in_tree():
			check(hud._safe.grow(1).encloses(panel.get_global_rect()), "%s %s: visible %s rect=%s outside safe=%s" % [root.size, state, panel.name, panel.get_global_rect(), hud._safe])
	for tab in hud.catalog.tab_buttons:
		if hud.catalog.visible: check(hud.catalog.get_global_rect().encloses(tab.get_global_rect()), "Catalogue family clipped: " + tab.text)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "%02d-%dx%d-%s.png" % [records.size(), root.size.x, root.size.y, state])
	records.append({"size":str(root.size), "state":state,"mode":hud.mode,"safe":str(hud._safe),"zoom":str(hud.session.get_node("Input").camera.zoom)})

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	check(ProjectSettings.get_setting("display/window/handheld/orientation", 0) == DisplayServer.SCREEN_SENSOR, "Project must enable automatic portrait and landscape")
	var game = GAME.instantiate()
	game.save_path = out + "never-created.save"
	root.add_child(game); game.set_process(false)
	await settle()
	var hud = game.get_node("HUD")
	var input = game.get_node("Input")
	hud._welcome = false
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x] = TYPES.Tile.FLOOR
	game.sim.grid[7][7] = TYPES.Tile.CORE
	game.sim.grid[7][9] = TYPES.Tile.ENTRANCE
	game.sim.grid[5][5] = TYPES.Tile.VAULT; game.sim.vault_gold[Vector2i(5,5)] = 75
	game.sim.gold = 225; game.raid.raid_timer = 18; game.notice = ""
	game.changed.emit(true); await settle()
	input.center_core(); input.camera.position += Vector2(72,24)
	var centre: Vector2 = input.camera.position
	var baseline := hash([game.sim.grid, game.sim.gold, game.sim.core_hp, game.sim.vault_gold])
	var identity: int = game.get_instance_id()
	for extent in [Vector2i(844,390),Vector2i(390,844),Vector2i(844,390),Vector2i(320,568),Vector2i(568,320)]:
		root.size = extent; await settle()
		check(game.get_instance_id() == identity, "Rotation must not recreate the session")
		check(input.camera.position.is_equal_approx(centre), "Rotation must retain camera centre")
		check(hud.mode == ("portrait" if extent.y > extent.x else "landscape"), "HUD orientation must follow viewport")
		await capture(hud, "idle")
		for family in 4:
			hud._open_catalog(family); await capture(hud, "catalogue-%d" % family); hud._close_catalog()
		game.choose_tool(TYPES.Tool.TRAP_SPIKE); await capture(hud, "placing"); game.cancel_selection()
		game.select_cell(Vector2i(5,5)); await capture(hud, "selection"); game.cancel_selection()
		hud.world_tapped(Vector2i(6,6)); await capture(hud, "radial"); hud.handle_back()
		# Opening radial may centre its target; keep the user's new centre next time.
		centre = input.camera.position
		game.set_paused(true); await capture(hud, "pause"); game.set_paused(false)
		game.raid.raid_active = true; game.changed.emit(false); await capture(hud, "raid")
		game.raid.raid_active = false; game.changed.emit(false)
		check(hash([game.sim.grid, game.sim.gold, game.sim.core_hp, game.sim.vault_gold]) == baseline, "Rotation/navigation cannot change dungeon resources")
	# A stationary touch begun before rotation must not place on release afterward.
	root.size = Vector2i(844,390); await settle()
	game.choose_tool(TYPES.Tool.TRAP_SPIKE)
	input._touches = {0:true}; input._begin(0, Vector2(250,180))
	root.size = Vector2i(390,844); await settle()
	check(input._pointer == -2 and input._touches.is_empty(), "Rotation must cancel an old world touch")
	check(game.tool == TYPES.Tool.TRAP_SPIKE, "Rotation must preserve the armed tool")
	game.cancel_selection()
	hud._open_catalog(2)
	var card: Button = hud.catalog.cards.filter(func(item): return item.id == TYPES.Tool.TRAP_SPIKE)[0].button
	input._palette_button = card; input._palette_dragged = true
	root.size = Vector2i(844,390); await settle()
	check(input._palette_button == null, "Rotation must cancel a catalogue drag")
	check(hud.catalog.visible and hud.catalog.category == 2, "Rotation must keep the open catalogue family")
	hud._close_catalog(); hud.world_tapped(Vector2i(6,6)); hud.radial._down = true
	root.size = Vector2i(390,844); await settle()
	check(not hud.radial._down, "Rotation must cancel a pending radial press")
	check(hud.radial.visible, "Rotation must keep the radial open")
	await capture(hud, "rotated-radial")
	hud.handle_back()
	# Real viewport touch: release at the newly projected cell after rotation.
	root.size = Vector2i(844,390); await settle()
	game.choose_tool(TYPES.Tool.TRAP_SPIKE)
	var view: Node2D = game.get_node("PlayArea/World/Dungeon")
	var target := Vector2i(6,6)
	input.camera.position = view.grid_to_local(Vector2(target)+Vector2(.5,.5))
	input.camera.force_update_scroll(); await settle()
	var touch := InputEventScreenTouch.new()
	touch.index = 0; touch.pressed = true
	touch.position = view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(target)+Vector2(.5,.5))
	root.push_input(touch,true); await process_frame
	check(input._pointer == 0, "Viewport touch must reach the world before rotation")
	root.size = Vector2i(390,844); await settle()
	touch = touch.duplicate(); touch.pressed = false
	touch.position = view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(target)+Vector2(.5,.5))
	root.push_input(touch,true); await settle()
	check(hash([game.sim.grid, game.sim.gold, game.sim.core_hp, game.sim.vault_gold]) == baseline, "Post-rotation touch release cannot purchase")
	game.cancel_selection()
	touch = touch.duplicate(); touch.pressed = true; root.push_input(touch,true)
	touch = touch.duplicate(); touch.pressed = false; root.push_input(touch,true); await settle()
	check(hud.radial.visible and hud.radial.cell == target, "A fresh touch must work after rotation cancellation")
	hud.handle_back()
	# Ordinary Control capture must not survive a viewport rotation either.
	var clicks := [0]
	hud.catalog_button.pressed.connect(func(): clicks[0] += 1)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT; mouse.pressed = true
	mouse.position = hud.catalog_button.get_global_rect().get_center()*hud.scale.x
	root.push_input(mouse,true); await process_frame
	root.size = Vector2i(844,390); await settle()
	mouse = mouse.duplicate(); mouse.pressed = false
	mouse.position = hud.catalog_button.get_global_rect().get_center()*hud.scale.x
	root.push_input(mouse,true); await settle()
	check(clicks[0] == 0, "An ordinary button held through rotation must not activate on release")
	mouse = mouse.duplicate(); mouse.pressed = true; root.push_input(mouse,true)
	mouse = mouse.duplicate(); mouse.pressed = false; root.push_input(mouse,true); await settle()
	check(clicks[0] == 1 and hud.catalog.visible, "A fresh button click must work after rotation")
	hud._close_catalog()
	touch = InputEventScreenTouch.new(); touch.index = 0; touch.pressed = true
	touch.position = hud.catalog_button.get_global_rect().get_center()*hud.scale.x
	root.push_input(touch,true); await process_frame
	root.size = Vector2i(390,844); await settle()
	touch = touch.duplicate(); touch.pressed = false
	touch.position = hud.catalog_button.get_global_rect().get_center()*hud.scale.x
	root.push_input(touch,true); await settle()
	check(clicks[0] == 1, "A button touch held through rotation must not activate on release")
	touch = touch.duplicate(); touch.pressed = true; root.push_input(touch,true)
	touch = touch.duplicate(); touch.pressed = false; root.push_input(touch,true); await settle()
	check(clicks[0] == 2 and hud.catalog.visible, "A fresh button touch must work after rotation")
	hud._close_catalog()
	check(not FileAccess.file_exists(game.save_path), "Review must not write a save")
	FileAccess.open(out + "results.json", FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":records}, "\t"))
	game.queue_free(); await process_frame
	print("Mobile rotation: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
