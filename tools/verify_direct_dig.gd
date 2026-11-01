extends SceneTree
## Actual viewport gestures and transactions; no player-save access.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const OUT = "res://artifacts/direct-dig/"
var game
var hud
var view
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle() -> void:
	for i in 6: await process_frame

func mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT; event.position = point; event.pressed = down
	root.push_input(event, true)

func touch(point: Vector2, down: bool, index := 0, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point; event.pressed = down; event.index = index; event.canceled = canceled
	root.push_input(event, true)

func target_point(cell: Vector2i) -> Vector2:
	var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
	camera.position = view.grid_to_local(Vector2(cell)+Vector2(.5,.5))
	camera.force_update_scroll()
	return view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(cell)+Vector2(.5,.5))

func fresh() -> void:
	hud._close_radial(false); hud._close_catalog()
	game.restart(true); game.notice = ""; game.cancel_selection()
	for child in hud.root.get_children():
		if child.has_meta("transient_feedback"): child.queue_free()
	await settle()

func candidates() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in TYPES.ROWS:
		for x in TYPES.COLS:
			var cell := Vector2i(x,y)
			if game.sim.dig_failure_reason(cell).is_empty(): cells.append(cell)
	return cells

func visible_cells() -> Array:
	if view.get("dig_guides_visible") != true: return []
	var cells = view.get("dig_cells")
	return cells if cells is Array else []

func capture(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280,720)
	game = GAME.instantiate(); game.persistence_enabled = false
	root.add_child(game); game.set_process(false)
	await settle()
	hud = game.get_node("HUD"); hud._welcome = false
	view = game.get_node("PlayArea/World/Dungeon")
	await fresh()
	var cells := candidates()
	check(not cells.is_empty(), "Fixture contains diggable frontier")
	check(visible_cells() == cells, "Every legal frontier cell is highlighted, without invalid rock")
	for card in hud.catalog.cards:
		check(card.id != TYPES.Tool.DIG, "Dig is absent from the catalog")
	hud.world_tapped(Vector2i(7,8))
	for family in 4:
		hud.radial._choose_family(family)
		for choice in hud.radial.choices:
			check(choice[0] != TYPES.Tool.DIG, "Dig is absent from radial families")
	check(visible_cells().is_empty(), "Radial hides direct-dig hints")
	hud._close_radial()
	check(visible_cells() == cells, "Closing radial restores frontier")
	await capture("landscape")
	# Real tap, exact price, no persistent tool, and normal Undo.
	var cell: Vector2i = cells[0]
	var gold: int = game.sim.gold
	var point := target_point(cell)
	await settle()
	mouse(point,true); await process_frame; mouse(point,false); await settle()
	check(game.sim.grid[cell.y][cell.x] == TYPES.Tile.FLOOR and game.sim.gold == gold-TYPES.COST_DIG, "Mouse tap digs once at the advertised price")
	check(game.tool == TYPES.Tool.NONE and not hud.radial.visible and game.selected.x < 0, "Direct digging leaves no tool, selection or menu armed")
	check(visible_cells() == candidates(), "Expansion refreshes highlights after the actual transaction")
	game.undo_build(); await settle()
	check(game.sim.grid[cell.y][cell.x] == TYPES.Tile.ROCK and game.sim.gold == gold, "Dig uses the existing undo transaction")
	check(visible_cells() == cells, "Undo restores the original frontier")
	# Drag out and back must not dig even when released on the same cell.
	point = target_point(cell); await settle()
	mouse(point,true); await process_frame
	for offset in [Vector2(70,0),Vector2.ZERO]:
		var motion := InputEventMouseMotion.new()
		motion.position = point+offset; motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion,true); await process_frame
	mouse(point,false); await settle()
	check(game.sim.gold == gold and game.sim.grid[cell.y][cell.x] == TYPES.Tile.ROCK, "Out-and-back panning never digs")
	for extent in [Vector2i(844,390),Vector2i(390,844),Vector2i(320,568)]:
		await fresh(); root.size = extent; await settle()
		cell = candidates()[0]; gold = game.sim.gold
		game.get_node("Input").center_core()
		game.get_node("PlayArea/World/Camera2D").force_update_scroll(); await settle()
		await capture("%dx%d" % [extent.x,extent.y])
		point = target_point(cell); await settle()
		touch(point,true); await process_frame; touch(point,false); await settle()
		check(game.sim.grid[cell.y][cell.x] == TYPES.Tile.FLOOR and game.sim.gold == gold-TYPES.COST_DIG, "Native touch digs exactly once at "+str(extent))
		check(not hud.radial.visible and game.tool == TYPES.Tool.NONE, "Touch needs no menu at "+str(extent))
	await fresh(); cell = candidates()[0]; gold = game.sim.gold
	point = target_point(cell); await settle()
	touch(point,true); await process_frame; touch(point,false,0,true); await settle()
	check(game.sim.gold == gold, "Canceled touch cannot dig")
	touch(point,true); touch(point+Vector2(40,0),true,1); await process_frame
	touch(point,false); touch(point+Vector2(40,0),false,1); await settle()
	check(game.sim.gold == gold, "Multitouch cannot dig")
	touch(point,true); await process_frame
	root.size = Vector2i(844,390); await settle(); touch(point,false); await settle()
	check(game.sim.gold == gold, "Rotation cancels a pending dig")
	# Modes and protected/isolated rock must not advertise or perform digging.
	hud._open_catalog(); check(visible_cells().is_empty(), "Catalog hides frontier")
	hud.world_tapped(cell)
	check(game.sim.gold == gold and not hud.catalog.visible, "First world tap only dismisses catalog")
	check(visible_cells() == candidates(), "Closing catalog restores frontier without a structural edit")
	game.choose_tool(TYPES.Tool.TRAP_SPIKE)
	check(visible_cells().is_empty(), "Armed construction hides dig hints")
	hud.world_tapped(cell); check(game.sim.gold == gold and game.tool == TYPES.Tool.TRAP_SPIKE, "Armed trap cannot silently dig")
	game.cancel_selection()
	game.sim.gold = TYPES.COST_DIG-1; game.changed.emit(false)
	check(visible_cells().is_empty(), "Unaffordable tiles are not offered")
	hud.world_tapped(cell)
	check(game.sim.gold == TYPES.COST_DIG-1 and game.notice.contains("gold"), "Poor dig reports actual rejection without opening radial")
	await fresh(); gold = game.sim.gold
	for y in TYPES.ROWS:
		for x in TYPES.COLS:
			var p := Vector2i(x,y)
			if game.sim.grid[y][x] != TYPES.Tile.ROCK or game.sim.dig_failure_reason(p).is_empty(): continue
			hud.world_tapped(p)
			check(game.sim.grid[y][x] == TYPES.Tile.ROCK and game.sim.gold == gold and not hud.radial.visible, "Invalid rock neither digs nor opens a build menu: "+str(p))
	game.set_paused(true)
	check(visible_cells().is_empty(), "Pause hides hints")
	hud.world_tapped(cell); check(game.sim.gold == gold, "Pause cannot dig")
	game.set_paused(false); game.start_raid()
	check(game.raid.raid_active and visible_cells().is_empty(), "Raid hides all dig hints")
	hud.world_tapped(cell); check(game.sim.gold == gold, "Raid cannot dig")
	# Removing Dig from menus must retain intentional structure removal, even
	# after Undo history is gone. The first action only requests confirmation.
	await fresh()
	for occupied in [Vector2i(5,8),Vector2i(6,8),Vector2i(9,9)]:
		game.cancel_selection(); hud.world_tapped(occupied)
		var tile: int = game.sim.grid[occupied.y][occupied.x]
		gold = game.sim.gold
		var remove = hud.selection.get("remove")
		check(remove is Button and remove.visible, "Occupied structure offers contextual Remove: "+str(occupied))
		if not remove is Button: continue
		remove.pressed.emit()
		check(hud.selection.confirm.visible and game.sim.grid[occupied.y][occupied.x] == tile and game.sim.gold == gold, "Remove waits for explicit confirmation")
		if occupied == Vector2i(5,8): await capture("remove-confirmation")
		hud.world_tapped(candidates()[0])
		check(game.sim.gold == gold and game.tool == TYPES.Tool.NONE and game.sim.grid[occupied.y][occupied.x] == tile, "Outside tap cancels pending removal without digging or arming a tool")
		game.cancel_selection(); hud.world_tapped(occupied); remove.pressed.emit()
		hud.handle_back()
		check(game.sim.grid[occupied.y][occupied.x] == tile and game.tool == TYPES.Tool.NONE, "Cancel Remove preserves the object and clears the tool")
		hud.world_tapped(occupied); remove.pressed.emit(); hud.selection.confirm.pressed.emit()
		check(game.sim.grid[occupied.y][occupied.x] == TYPES.Tile.FLOOR and game.sim.gold == gold, "Confirmed removal keeps the original free clearing rule")
		check(game.tool == TYPES.Tool.NONE and game.selected.x < 0, "Removal does not leave demolition or digging armed")
		game.undo_build()
		check(game.sim.grid[occupied.y][occupied.x] == tile, "Undo restores the removed structure")
	for protected in [Vector2i(3,8),Vector2i(8,8)]:
		game.cancel_selection(); hud.world_tapped(protected)
		var remove = hud.selection.get("remove")
		check(remove is Button and not remove.visible, "Core and entrance cannot be removed")
	await fresh(); root.size = Vector2i(1280,720); await settle()
	game.get_node("Input").center_core()
	game.get_node("PlayArea/World/Camera2D").force_update_scroll(); await settle()
	var door_point: Vector2 = view.grid_to_local(Vector2(5.5,8.5),.55)
	var behind: Vector2i = view.pick_cell(door_point)
	check(game.sim.dig_failure_reason(behind).is_empty(), "Door art overlaps diggable rock in ground projection")
	point = view.get_global_transform_with_canvas()*door_point; gold = game.sim.gold
	touch(point,true); await process_frame; touch(point,false); await settle()
	check(game.sim.gold == gold and game.sim.grid[behind.y][behind.x] == TYPES.Tile.ROCK, "Tapping visible door art never excavates the rock behind it")
	root.size = Vector2i(320,568); await settle()
	game.get_node("Input").center_core()
	game.get_node("PlayArea/World/Camera2D").force_update_scroll(); await settle()
	var badge_points: Array[Vector2] = []
	for item in view._markers:
		var badge: Control = item.node.badge
		if not is_instance_valid(badge) or not badge.is_visible_in_tree(): continue
		for offset in [Vector2.ZERO, Vector2(16,0),Vector2(-16,0),Vector2(0,-16),Vector2(0,16)]:
			var local_point: Vector2 = view.to_local(badge.get_global_transform()*(badge.size*.5+offset))
			behind = view.pick_cell(local_point)
			if not game.sim.dig_failure_reason(behind).is_empty(): continue
			point = badge.get_global_transform_with_canvas()*(badge.size*.5+offset)
			if not hud.blocks_pointer(point): badge_points.append(point)
	for badge_point in badge_points:
		point = badge_point
		touch(point,true); await process_frame; touch(point,false); await settle()
		check(game.sim.gold == gold, "Tapping a status badge cannot dig through it")
	check(not badge_points.is_empty(), "Badge fixture covers a legal frontier cell")
	game.restart(false); hud._welcome = false; game.changed.emit(true)
	check(visible_cells().is_empty(), "No dig hints before placing the Core")
	var report := {"checks":checks,"failures":failures}
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Direct dig: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	game.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
