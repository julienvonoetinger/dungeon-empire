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
func center() -> void:
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(7.5,8.5))-Vector2(0,90)
	camera.force_update_scroll()
func visible_blocks() -> int:
	var result:=0
	for block in hud.dig_targets.blocks:
		if block.is_visible_in_tree(): result+=1
	return result
func cube_signature(controller: Control) -> Dictionary:
	var result: Dictionary={}
	for block in controller.blocks: result[block.cell]=[block.support.min,block.support.max,block.icon.resource_path]
	return result
func clickable(face_index: int) -> Dictionary:
	for block in hud.dig_targets.blocks:
		var local:=Vector2.ZERO
		for p in block.faces[face_index]: local+=p*.25
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
	root.add_child(game); game.set_process(false); await settle()
	hud=game.get_node("HUD"); view=game.get_node("PlayArea/World/Dungeon"); terrain=game.get_node("PlayArea/World/Terrain")
	check(game.sim._core_origin()==Vector2i(8,8) and not hud.shade.visible and visible_blocks()>0,"Cold start opens the centred Core chamber for excavation")
	check(is_equal_approx(terrain.cut_margin,1.35),"Main scene uses the approved terrain placement reference")
	check(hud.dig_targets.get("blocks") is Array,"Main HUD uses excavation cubes, without preview replacement")
	hud._welcome=false; game.restart(true); game.notice=""; game.cancel_selection(); await settle()
	check(terrain.geometry.has("projection_setback"),"Main terrain protects the projected cube silhouette")
	if not failures.is_empty(): await finish(); return
	check(hud.dig_targets.blocks.size()==view.dig_cells.size() and not view.dig_cells.is_empty(),"Main scene creates one cube per legal dig cell")
	check(hud.hint.text.contains("block"),"Preparation hint describes the visible blocks")
	var approved=PREVIEW.instantiate(); root.add_child(approved); await settle()
	check(terrain.geometry==approved.game.get_node("PlayArea/World/Terrain").geometry,"Production terrain is identical to the approved preview")
	check(cube_signature(hud.dig_targets)==cube_signature(approved.targets),"Production cubes preserve preview size, position, height and icon")
	approved.queue_free(); await settle()
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844),Vector2i(480,320),Vector2i(320,480)]:
		root.size=size; await settle(); center(); await settle()
		check(visible_blocks()==view.dig_cells.size(),"All affordable cubes appear in "+str(size))
		check(not clickable(0).is_empty(),"A top can be tapped in "+str(size))
		check(not clickable(1).is_empty() or not clickable(2).is_empty(),"A side can be tapped in "+str(size))
		check(hud._safe.encloses(hud.hint.get_global_rect()),"Preparation hint stays inside the safe area in %s: %s within %s" % [size,hud.hint.get_global_rect(),hud._safe])
		check(not hud.hint.get_global_rect().intersects(hud.utilities.get_global_rect()),"Preparation hint does not overlap utility buttons in "+str(size))
		await capture("preparation-%dx%d" % [size.x,size.y])
	root.size=Vector2i(1280,720); await settle(); center(); await settle()
	var original: Dictionary=terrain.geometry.duplicate(true)
	for face_index in [0,1]:
		var target:=clickable(face_index)
		check(not target.is_empty(),"Native touch target exists on face "+str(face_index))
		if target.is_empty(): continue
		var gold: int=game.sim.gold
		touch(target.point,true); await process_frame; touch(target.point,false); await settle()
		check(game.sim.grid[target.cell.y][target.cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"Main-scene touch buys one dig on face "+str(face_index))
		check(game.tool==game.Types.Tool.NONE and game.selected.x<0 and not hud.radial.visible,"Direct dig does not arm a tool or menu")
		check(terrain.geometry!=original,"Actual production excavation updates the rock cut")
		game.undo_build(); await settle()
		check(game.sim.gold==gold and terrain.geometry==original,"Main-scene Undo restores the approved terrain")
	var target:=clickable(0)
	if not target.is_empty():
		var gold: int=game.sim.gold; var camera=game.get_node("PlayArea/World/Camera2D")
		var camera_before: Vector2=camera.position
		touch(target.point,true); await process_frame
		var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=target.point+Vector2(80,0)
		root.push_input(drag,true); await process_frame; touch(drag.position,false); await settle()
		check(game.sim.gold==gold and camera.position!=camera_before,"Dragging from a cube pans without purchasing")
		center(); await settle(); target=clickable(0)
		touch(target.point,true); await process_frame; touch(target.point,false,true); await settle()
		check(game.sim.gold==gold and hud.dig_targets.pressed_cell.x<0,"Canceled touch clears the pressed cube and spends nothing")
		touch(target.point,true); await process_frame
		root.size=Vector2i(390,844); await settle(); touch(target.point,false); await settle()
		check(game.sim.gold==gold and hud.dig_targets.pressed_cell.x<0,"Rotation cancels a held cube without purchasing")
	root.size=Vector2i(1280,720); await settle(); center(); await settle()
	game.set_paused(true); await settle()
	check(visible_blocks()==0,"Pause hides excavation actions")
	game.set_paused(false); await settle()
	check(visible_blocks()>0,"Resume restores excavation actions")
	hud._open_catalog(); await settle()
	check(visible_blocks()==0,"Catalog hides excavation actions")
	hud._choose_tool(game.Types.Tool.TRAP_SPIKE); await settle()
	check(visible_blocks()==0 and view._floor_guide.visible and not view._valid_cells.is_empty(),"Armed construction retains valid-placement guides without dig cubes")
	hud._stop_placing(); await settle()
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
	for child in view._world.get_children():
		if child.get_script()==hud.dig_targets.Block: actual_count+=1
	check(actual_count==hud.dig_targets.blocks.size(),"Renderer rebuilds leave no duplicate cube nodes")
	check(not game.persistence_enabled,"Integration fixture never reads or writes player saves")
	await finish()
