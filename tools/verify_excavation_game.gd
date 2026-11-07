extends SceneTree
## Exercise the actual main scene, without replacing scripts or accessing saves.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const PREVIEW=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/excavation-game/"
var game
var hud
var view
var terrain
var checks:=0
var failures: Array[String]=[]
func touch(point: Vector2, down: bool, canceled:=false) -> void:
	var event:=InputEventScreenTouch.new(); event.index=0; event.position=point; event.pressed=down; event.canceled=canceled
	root.push_input(event,true)

func mouse_button(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event,true)

func drag_to(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event,true)
func center() -> void:
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(7.5,8.5))-Vector2(0,90)
	camera.force_update_scroll()
func visible_blocks() -> int:
	var result:=0
	for block in hud.dig_targets.blocks:
		if block.is_visible_in_tree(): result+=1
	return result
func marker_signature(controller: Control) -> Dictionary:
	var result: Dictionary={}
	for block in controller.blocks: result[block.cell]=[block.support.min,block.support.max,block.preview.texture.resource_path]
	return result
func visible_build_cells(icon: Texture2D, pressed_only := false) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for block in hud.dig_targets.blocks:
		if block.is_visible_in_tree() and block.preview.texture == icon and (not pressed_only or block.pressed):
			cells.append(block.cell)
	return cells

func clickable(raised: bool, tile: int = -1) -> Dictionary:
	for block in hud.dig_targets.blocks:
		if tile >= 0 and game.sim.grid[block.cell.y][block.cell.x] != tile: continue
		var local: Vector2 = block.preview.position if raised else block.top_center
		var screen: Vector2=view.get_global_transform_with_canvas()*local
		if root.get_visible_rect().has_point(screen) and not hud.blocks_pointer(screen) and hud.dig_targets.hit_cell(screen/hud.scale.x)==block.cell:
			return {"point":screen,"cell":block.cell}
	return {}

func capture(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func finish() -> void:
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Excavation game: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	game.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	game=GAME.instantiate(); game.persistence_enabled=false
	game.progression.xp = 150 # A later interaction arms the spike tool.
	root.add_child(game); game.set_process(false); await settle()
	hud=game.get_node("HUD"); view=game.get_node("PlayArea/World/Dungeon"); terrain=game.get_node("PlayArea/World/Terrain")
	check(game.sim._core_origin()==Vector2i(8,8) and not hud.shade.visible and visible_blocks()>0,"Cold start opens the centred Core chamber for excavation")
	check(is_equal_approx(terrain.cut_margin,1.35),"Main scene uses the approved terrain placement reference")
	check(hud.dig_targets.get("blocks") is Array,"Main HUD uses excavation cubes, without preview replacement")
	hud._welcome=false; game.restart(true); game.notice=""; game.cancel_selection(); await settle()
	check(terrain.geometry.has("projection_setback"),"Main terrain protects the projected cube silhouette")
	if not failures.is_empty(): await finish(); return
	check(hud.dig_targets.blocks.size()==view.dig_cells.size() and not view.dig_cells.is_empty(),"Main scene creates one cube per legal dig cell")
	check(hud.hint.text.contains("pickaxe"),"Preparation hint describes the floating picks")
	var approved=PREVIEW.instantiate(); root.add_child(approved); await settle()
	check(terrain.geometry==approved.game.get_node("PlayArea/World/Terrain").geometry,"Production terrain is identical to the approved preview")
	check(marker_signature(hud.dig_targets)==marker_signature(approved.targets),"Production markers preserve preview size, position, height and icon")
	approved.queue_free(); await settle()
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844),Vector2i(480,320),Vector2i(320,480)]:
		root.size=size; await settle(); center(); await settle()
		check(visible_blocks()==view.dig_cells.size(),"All affordable cubes appear in "+str(size))
		check(not clickable(false).is_empty(),"A landing ring can be tapped in "+str(size))
		check(not clickable(true).is_empty(),"A floating pick can be tapped in "+str(size))
		check(hud._safe.encloses(hud.hint.get_global_rect()),"Preparation hint stays inside the safe area in %s: %s within %s" % [size,hud.hint.get_global_rect(),hud._safe])
		check(not hud.hint.get_global_rect().intersects(hud.utilities.get_global_rect()),"Preparation hint does not overlap utility buttons in "+str(size))
		await capture("preparation-%dx%d" % [size.x,size.y])
	root.size=Vector2i(1280,720); await settle(); center(); await settle()
	var original: Dictionary=terrain.geometry.duplicate(true)
	for raised in [false,true]:
		var target:=clickable(raised)
		check(not target.is_empty(),"Native touch target exists on the pick" if raised else "Native touch target exists on the ring")
		if target.is_empty(): continue
		var gold: int=game.sim.gold
		touch(target.point,true); await process_frame; touch(target.point,false); await settle()
		check(game.sim.grid[target.cell.y][target.cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"Main-scene touch buys exactly one excavation")
		check(game.tool==game.Types.Tool.NONE and game.selected.x<0 and not hud.radial.visible,"Direct dig does not arm a tool or menu")
		check(terrain.geometry!=original,"Actual production excavation updates the rock cut")
		game.undo_build(); await settle()
		check(game.sim.gold==gold and terrain.geometry==original,"Main-scene Undo restores the approved terrain")
	var target:=clickable(true)
	check(not target.is_empty(),"A floating pick accepts native touch in free play")
	if not target.is_empty():
		var gold: int=game.sim.gold; var camera=game.get_node("PlayArea/World/Camera2D")
		var camera_before: Vector2=camera.position
		touch(target.point,true); await process_frame
		var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=target.point+Vector2(80,0)
		root.push_input(drag,true); await process_frame; touch(drag.position,false); await settle()
		check(game.sim.gold==gold and camera.position!=camera_before,"Dragging from a floating pick pans without purchasing")
		center(); await settle(); target=clickable(true)
		touch(target.point,true); await process_frame; touch(target.point,false,true); await settle()
		check(game.sim.gold==gold and hud.dig_targets.pressed_cell.x<0,"Canceled touch clears the pressed pick and spends nothing")
		touch(target.point,true); await process_frame
		root.size=Vector2i(390,844); await settle(); touch(target.point,false); await settle()
		check(game.sim.gold==gold and hud.dig_targets.pressed_cell.x<0,"Rotation cancels a held cube without purchasing")
	root.size=Vector2i(1280,720); await settle(); center(); await settle()
	game.set_paused(true); await settle()
	check(visible_blocks()==0,"Pause hides excavation actions")
	game.set_paused(false); await settle()
	check(visible_blocks()>0,"Resume restores excavation actions")
	# A north/south branch beside the original east/west corridor.
	var branch := Vector2i(8,6)
	game.dig_cell(branch); await settle()
	hud._open_catalog(); await settle()
	check(visible_blocks()==0,"Catalog hides excavation actions")
	var previous_xp: int = game.progression.xp
	game.progression.xp = 280
	var buildings := {
		GameTypes.Tool.BUILD_DOOR: GameTypes.Tile.DOOR,
		GameTypes.Tool.BUILD_REINFORCED_DOOR: GameTypes.Tile.REINFORCED_DOOR,
		GameTypes.Tool.BUILD_MAGIC_DOOR: GameTypes.Tile.MAGIC_DOOR,
		GameTypes.Tool.TRAP_SPIKE: GameTypes.Tile.SPIKE,
		GameTypes.Tool.TRAP_SNARE: GameTypes.Tile.SNARE,
		GameTypes.Tool.TRAP_VOID: GameTypes.Tile.VOID,
	}
	for tool: int in buildings:
		var legal: Array[Vector2i] = []
		for y in GameTypes.ROWS:
			for x in GameTypes.COLS:
				var cell := Vector2i(x,y)
				if game.check_action(cell,tool).valid: legal.append(cell)
		var icon: Texture2D = hud.UI.build_site_icon(tool)
		var card: Dictionary = hud.catalog.cards.filter(func(item): return item.id == tool)[0]
		hud._open_catalog(card.category); await settle()
		card.button.grab_focus()
		await settle()
		var start: Vector2 = card.button.get_global_transform_with_canvas() * (card.button.size*.5)
		mouse_button(start,true); await process_frame
		drag_to(Vector2.ZERO); await settle()
		check(legal.size() > 1 and visible_build_cells(icon) == legal and visible_build_cells(icon,true).is_empty(), "Dragging outside a legal cell still lights every legal position for tool %d" % tool)
		var hovered := Vector2i(-1,-1)
		for cell in legal:
			var at: Vector2 = game.get_node("PlayArea").position + view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(cell)+Vector2(.5,.5))
			var pointer: Vector2 = at + Vector2.DOWN*52.*hud.scale.x
			if hud.blocks_pointer(pointer) or hud.blocks_pointer(at): continue
			hovered = cell
			drag_to(pointer); await settle()
			break
		check(hovered.x >= 0 and visible_build_cells(icon) == legal and visible_build_cells(icon,true) == [hovered], "All drag targets remain lit with one active position")
		var spike := Vector2i(6,8)
		var spike_screen: Vector2 = game.get_node("PlayArea").position + view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(spike)+Vector2(.5,.5))
		if tool == GameTypes.Tool.BUILD_DOOR:
			var before_drop: int = game.sim.gold
			var pointer: Vector2 = spike_screen + Vector2.DOWN*52.*hud.scale.x
			drag_to(pointer); await settle()
			check(view._placement_cell == spike and not view._placement_valid and spike not in visible_build_cells(icon), "Dragging a door over spikes gives no valid placement marker")
			mouse_button(pointer,false); await settle()
			check(game.selected.x < 0 and game.sim.gold == before_drop and game.sim.grid[spike.y][spike.x] == GameTypes.Tile.SPIKE, "Dropping a door onto spikes rejects the purchase")
		else:
			drag_to(start); await process_frame
			mouse_button(start,false); await settle()
			check(visible_blocks() == 0, "Canceling a catalog drag clears the placement highlights")
		hud._choose_tool(tool); await settle()
		check(visible_build_cells(icon) == legal, "All legal placements, including replacements, light up when arming tool %d" % tool)
		var facing_by_cell := {}
		for block in hud.dig_targets.blocks:
			facing_by_cell[block.cell] = block.preview.flip_h
		check(facing_by_cell.get(Vector2i(4,8)) == game.sim._is_door_tile(buildings[tool]) and facing_by_cell.get(branch) == false, "The floating icon spans the corridor on both axes for tool %d" % tool)
		if game.sim._is_door_tile(buildings[tool]):
			check(spike not in facing_by_cell, "A door never highlights the occupied spike tile")
			touch(spike_screen,true); await process_frame; touch(spike_screen,false); await settle()
			check(game.selected.x < 0 and game.notice.to_lower().contains("trap"), "Tapping spikes refuses a door before opening a replacement confirmation")
			hud._choose_tool(tool); await settle()
		if tool == GameTypes.Tool.BUILD_DOOR: await capture("door-preview-both-axes")
		if tool == GameTypes.Tool.TRAP_SNARE:
			var replacement := clickable(true,GameTypes.Tile.SPIKE)
			check(not replacement.is_empty(), "An existing spike offers a selectable snare replacement")
			if not replacement.is_empty():
				var before: int = game.sim.gold
				touch(replacement.point,true); await process_frame; touch(replacement.point,false); await settle()
				check(game.selected == replacement.cell and game.sim.gold == before and hud.selection.visible, "Choosing a replacement waits for confirmation")
				game.confirm_action(); await settle()
				check(game.sim.grid[replacement.cell.y][replacement.cell.x] == GameTypes.Tile.SNARE and game.sim.gold == before-GameTypes.COST_SNARE, "Confirming pays for the replacement once")
				game.undo_build(); await settle()
		var site := clickable(true,GameTypes.Tile.FLOOR)
		check(not site.is_empty(), "A raised construction preview accepts touch for tool %d" % tool)
		if site.is_empty(): continue
		var gold: int = game.sim.gold
		touch(site.point,true); await process_frame; touch(site.point,false,true); await settle()
		check(game.sim.gold == gold and hud.dig_targets.pressed_cell.x < 0, "Canceling a construction touch spends nothing")
		touch(site.point,true); await process_frame; touch(site.point,false); await settle()
		check(game.sim.grid[site.cell.y][site.cell.x] == buildings[tool] and game.sim.gold == gold-GameTypes.fixed_tool_cost(tool), "Touching the preview builds the selected object exactly once")
		if game.sim._is_trap_tile(buildings[tool]):
			for door in [GameTypes.Tool.BUILD_DOOR, GameTypes.Tool.BUILD_REINFORCED_DOOR, GameTypes.Tool.BUILD_MAGIC_DOOR]:
				var action: Dictionary = game.check_action(site.cell,door)
				check(not action.valid and action.cost == 0 and action.reason.to_lower().contains("trap"), "Door %d refuses trap %d" % [door,buildings[tool]])
			game.sim.trap_charges[site.cell] = 0
			check(not game.check_action(site.cell,GameTypes.Tool.BUILD_DOOR).valid, "A spent trap still occupies its tile")
		game.undo_build(); await settle()
		check(game.sim.gold == gold, "Undo restores the placement cost")
	game.progression.xp = previous_xp
	hud._stop_placing(); await settle()
	game.undo_build(); await settle()
	hud.world_tapped(Vector2i(6,8)); await settle()
	check(hud.selection.visible and visible_blocks()==0,"Object selection hides excavation actions")
	game.cancel_selection(); await settle()
	hud._toggle_path(); await settle()
	check(view.access_visible and view._floor_guide.visible and hud.hint.text.contains("Paths"),"Paths overlay and its hint survive removal of old flat dig guides")
	hud._toggle_path(); await settle()
	var funded: int=game.sim.gold; var surface=terrain.get_node("RockTop")
	game.sim.gold=0; game.changed.emit(false); await settle()
	check(visible_blocks()==0 and terrain.get_node("RockTop")==surface and terrain.geometry==original,"No gold hides actions without rebuilding or filling the recess")
	game.sim.gold=funded; game.changed.emit(false); await settle()
	seed(241031); game.start_raid(); await settle()
	check(game.raid.raid_active and visible_blocks()==0,"An actual raid starts without excavation cubes")
	check(hud.hint.text.contains("Raid") and not hud.hint.text.contains("dig"),"Raid hint is not overwritten by the excavation controller")
	check(terrain.geometry==original,"Physical terrain survives the raid transition")
	view._update_markers()
	var raid_order: Array=view._world.get_children()
	hud.dig_targets._signature=0; hud.dig_targets.refresh()
	check(view._world.get_children()==raid_order,"Inactive excavation leaves the hero and masonry draw order intact")
	await capture("raid-1280x720")
	for step in 2400:
		if not game.raid.raid_active: break
		game.advance_simulation(.1)
		if step%10==0: await process_frame
	await settle()
	check(game.result_open and not game.raid.raid_active and visible_blocks()==0,"Real raid results retain a hidden excavation controller")
	game.continue_preparation(); await settle()
	check(not game.sim.game_over and game.can_edit(),"Raid can return to ordinary preparation")
	check(visible_blocks()==view.dig_cells.size(),"Preparation restores the affordable frontier after the raid")
	var actual_count:=0
	for child in view._floor_guide.get_children():
		if child.get_script()==hud.dig_targets.Block: actual_count+=1
	check(actual_count==hud.dig_targets.blocks.size(),"Renderer rebuilds leave no duplicate cube nodes")
	check(not game.persistence_enabled,"Integration fixture never reads or writes player saves")
	await finish()
