extends SceneTree
## Uses its own never-existing slot; transactions write only to ignored artifacts.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var game = GAME.instantiate()
	game.save_path="res://artifacts/master-ui-never-player.save"
	root.add_child(game); game.set_process(false)
	await process_frame
	var hud=game.get_node("HUD")
	hud._welcome=false
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[7][7]=TYPES.Tile.CORE
	game.changed.emit(true)
	for i in 5: await process_frame
	check(game.get_node("PlayArea").size.is_equal_approx(root.get_visible_rect().size),"World must fill viewport without a permanent rail")
	check(hud.has_method("world_tapped"),"Unarmed cells must open contextual construction")
	if not failures.is_empty():
		game.queue_free(); await process_frame; quit(1); return
	check(hud.get("header")!=null,"Live master header missing")
	hud.world_tapped(Vector2i(6,6))
	check(hud.radial.visible,"Empty floor tap must open radial")
	var before: int=game.sim.gold
	hud._radial_tool(TYPES.Tool.TRAP_SPIKE)
	check(game.sim.grid[6][6]==TYPES.Tile.SPIKE,"Radial chooses and places on the targeted cell")
	check(game.sim.gold==before-35,"Exactly one trap price charged")
	check(game.tool==TYPES.Tool.TRAP_SPIKE,"Tool remains armed")
	hud.world_tapped(Vector2i(7,6))
	check(game.sim.gold==before-70,"Repeat placement charges once")
	hud.world_tapped(Vector2i(0,0))
	check(game.sim.gold==before-70 and game.tool==TYPES.Tool.TRAP_SPIKE,"Invalid tap preserves tool and gold")
	hud.handle_back()
	check(game.tool==TYPES.Tool.NONE,"Back exits armed mode")
	hud.world_tapped(Vector2i(8,6)); hud.handle_back()
	check(not hud.radial.visible and game.tool==TYPES.Tool.NONE,"Back closes radial without buying")
	game.set_paused(true); hud.world_tapped(Vector2i(8,6))
	check(not hud.radial.visible,"Pause blocks contextual construction")
	game.set_paused(false)
	hud._open_catalog(2)
	check(game.catalog_open,"Catalogue suspends preparation timer")
	hud._choose_tool(TYPES.Tool.DIG)
	check(not game.catalog_open and game.tool==TYPES.Tool.DIG,"Catalogue arms without purchase")
	check(game.sim.gold==before-70,"Catalogue navigation is free")
	hud._stop_placing()
	# An occupied cell opens its existing sheet; opening Pause does not discard it.
	hud.world_tapped(Vector2i(6,6))
	check(hud.selection.visible and not hud.radial.visible,"Occupied trap opens its sheet")
	hud._open_menu(); hud.handle_back()
	check(game.selected==Vector2i(6,6),"Pause must preserve pending object selection")
	game.cancel_selection()
	# Geometry stays on-screen at all four edges for short and narrow phones.
	for extent in [Vector2i(740,360),Vector2i(320,568),Vector2i(667,375),Vector2i(568,320),Vector2i(568,299)]:
		root.size=extent
		for i in 8: await process_frame
		for cell in [Vector2i(0,0),Vector2i(15,0),Vector2i(0,15),Vector2i(15,15)]:
			hud.world_tapped(cell)
			var rect: Rect2=hud.radial.get_global_rect()
			check(hud._safe.encloses(rect),"Radial clipped at "+str(extent)+" "+str(cell))
			check(rect.position.y>=hud.header.position.y+hud.header.size.y-1,"Radial overlaps status band")
			hud.handle_back()
	# A release after cancellation cannot activate the selected wedge.
	hud.world_tapped(Vector2i(8,6))
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=hud.radial.choice_point(0)
	hud.radial._gui_input(press); hud.cancel_pointer()
	var release:=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.position=hud.radial.choice_point(0)
	hud.radial._gui_input(release)
	check(game.sim.gold==before-70 and hud.radial.visible,"Canceled radial release cannot purchase")
	var touch_input=game.get_node("Input")
	touch_input._touches={0:true,1:true}
	hud.radial._gui_input(press); hud.radial._gui_input(release)
	check(game.sim.gold==before-70 and hud.radial.visible,"Two held fingers cannot rearm a canceled radial press")
	touch_input._touches.clear()
	hud.handle_back()
	# Inject the real mouse stream through the viewport: dragging pans without buying.
	var input=game.get_node("Input")
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	input.center_core(); camera.force_update_scroll(); game.choose_tool(TYPES.Tool.TRAP_SPIKE)
	var position_before:=camera.position
	var start:=root.get_visible_rect().size*.5
	press.position=start; root.push_input(press,true)
	await process_frame
	var motion:=InputEventMouseMotion.new(); motion.position=start+Vector2(80,0); motion.relative=Vector2(80,0); motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true); await process_frame
	release.position=motion.position; root.push_input(release,true); await process_frame
	check(camera.position!=position_before and game.sim.gold==before-70,"Drag must pan without purchase")
	check(game.tool==TYPES.Tool.TRAP_SPIKE,"Pan must preserve armed tool")
	game.cancel_selection()
	# Tap a real projected cell through the viewport, then a real radial wedge.
	var target:=Vector2i(8,8)
	var view: Node2D=game.get_node("PlayArea/World/Dungeon")
	camera.position=view.grid_to_local(Vector2(target)+Vector2(.5,.5)); camera.force_update_scroll()
	for i in 3: await process_frame
	var point: Vector2=view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(target)+Vector2(.5,.5))
	press.position=point; root.push_input(press,true); release.position=point; root.push_input(release,true)
	for i in 3: await process_frame
	check(hud.radial.visible and hud.radial.cell==target,"Projected cell tap opens the correct radial")
	check(game.sim.gold==before-70,"Opening release cannot buy a radial item")
	var wedge: Vector2=(hud.radial.position+hud.radial.choice_point(0))*hud.scale.x
	press.position=wedge; root.push_input(press,true); release.position=wedge; root.push_input(release,true)
	for i in 3: await process_frame
	check(game.sim.grid[8][8]==TYPES.Tile.SPIKE and game.sim.gold==before-105,"Real radial wedge click buys once")
	game.cancel_selection()
	# Pressing HUD buttons does not also select/dig a cell beneath them.
	var catalogue_point: Vector2=hud.catalog_button.get_global_rect().get_center()*hud.scale.x
	press.position=catalogue_point; root.push_input(press,true); release.position=catalogue_point; root.push_input(release,true)
	for i in 3: await process_frame
	check(hud.catalog.visible and game.selected.x<0 and game.sim.gold==before-105,"HUD click is shielded from the world")
	hud._close_catalog()
	# Failed disk writes must stay visible, even while armed or in the pause menu.
	var old_path: String=game.save_path
	game.save_path="res://artifacts/nonexistent-master-ui-directory/failure.save"
	game.choose_tool(TYPES.Tool.TRAP_SPIKE); game.activate_cell(Vector2i(8,7))
	check(not game.save_error.is_empty(),"Unwritable review path must exercise the save-failure branch")
	check(hud.pose_bar.visible and hud.pose_label.text.contains("save"),"Failed save must be visible after placement")
	hud._open_menu()
	check(hud.modal_text.text.contains("save"),"Pause must retain the save failure notice")
	game.save_path=old_path; game.save_error=""; hud.handle_back(); game.cancel_selection()
	# 2x advances the same simulation in two bounded steps, pause advances none.
	game.sim.grid[7][9]=TYPES.Tile.ENTRANCE
	for cell in [Vector2i(5,5),Vector2i(9,5),Vector2i(9,9)]:
		game.sim.grid[cell.y][cell.x]=TYPES.Tile.VAULT
	game.raid._start_raid(); game.raid_speed=2
	var elapsed: float=game.raid.elapsed_seconds
	game._process(.05)
	check(is_equal_approx(game.raid.elapsed_seconds-elapsed,.1),"2x advances two bounded simulation steps")
	hud._refresh_live()
	check(hud.hint.text=="Raid in progress · Drag to explore","Raid instructions must describe observation, not construction")
	hud._toggle_path()
	check(hud.hint.text.contains("Paths from the entrance"),"Access overlay retains its own explanation during a raid")
	hud._toggle_path()
	check(hud.hint.text.begins_with("Raid in progress"),"Closing access overlay restores the raid instruction")
	game.paused=true; elapsed=game.raid.elapsed_seconds; game._process(.05)
	check(game.raid.elapsed_seconds==elapsed,"Pause freezes speed controls' simulation")
	game.raid.raid_active=false; game.paused=false; hud._refresh_live()
	check(hud.hint.text.contains("build"),"Preparation restores the construction instruction after a raid")
	game.queue_free(); await process_frame
	print("Master mobile checks: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
