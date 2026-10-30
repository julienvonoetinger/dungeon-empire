extends SceneTree
## Isolated presentation inventory. No player-save reads/writes or raid simulation.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/interface-review/catalogue-direct/"
var output := OUT
var resource_spacing := false
var design_pass := false
var second_pass := false
var observations: Array = []
func _initialize() -> void:
	resource_spacing=OS.get_cmdline_user_args().has("--resource-spacing") or OS.get_cmdline_user_args().has("--block-spacing")
	if resource_spacing: output="res://docs/reference/interface-review/resource-spacing/"
	if OS.get_cmdline_user_args().has("--block-spacing"): output="res://docs/reference/interface-review/block-spacing/"
	design_pass=OS.get_cmdline_user_args().has("--design-pass") or OS.get_cmdline_user_args().has("--design-pass-2")
	if design_pass: output="res://docs/reference/interface-review/design-pass/"
	second_pass=OS.get_cmdline_user_args().has("--design-pass-2")
	if second_pass: output="res://docs/reference/interface-review/design-pass-2/"
	call_deferred("_capture")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(output+"captures")
	var game := GAME.instantiate()
	game.save_path=output+"never-created.save"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var hud=game.get_node("HUD")
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[7][7]=TYPES.Tile.CORE
	for p in [Vector2i(5,5),Vector2i(9,5),Vector2i(9,9)]:
		game.sim.grid[p.y][p.x]=TYPES.Tile.VAULT
		game.sim.vault_gold[p]=0 if p==Vector2i(5,5) else 75 if p==Vector2i(9,5) else 150
	game.sim.gold=225
	game.sim.grid[5][7]=TYPES.Tile.SPIKE; game.sim.trap_charges[Vector2i(7,5)]=2
	game.sim.grid[9][7]=TYPES.Tile.SNARE; game.sim.trap_charges[Vector2i(7,9)]=0
	game.sim.grid[7][9]=TYPES.Tile.ENTRANCE
	game.raid.raid_timer=74
	game.notice="Building"; game.save_error=""; game.save_blocked=false; hud._welcome=false
	game.changed.emit(true)
	game.get_node("Input").center_core()
	var extents := [Vector2i(844,390),Vector2i(740,360),Vector2i(1280,720),Vector2i(390,844),Vector2i(320,568)]
	if design_pass: extents.insert(2,Vector2i(667,375))
	if second_pass: extents=[Vector2i(844,390),Vector2i(740,360),Vector2i(667,375),Vector2i(390,844),Vector2i(320,568),Vector2i(1280,720)]
	for extent in extents:
		root.size=extent
		var states := ["tools","menu"] if resource_spacing else ["tools","tools-scrolled","observe","catalog","doors","treasures","terrain","placing","selection","transfer-loot","menu","raid","result-paused","reset","defeat-paused","save-blocked-paused"]
		if design_pass: states=["tools","tools-scrolled","placing","notice","catalog","doors","selection","transfer-loot","menu","observe","raid","welcome"]
		# scale-before: identical layout and size, previous 0.75 world zoom only.
		if second_pass: states=["tools","scale-before","catalog","doors","placing","placing-long","notice","selection","transfer-loot","menu","observe","raid","welcome"]
		for state in states:
			game.notice=("Not enough gold (35 required)." if second_pass else "Not enough gold to build this.") if state=="notice" else "Building"
			hud._welcome=state=="welcome"
			if state=="welcome": game.sim.grid[7][7]=TYPES.Tile.FLOOR
			elif game.sim.grid[7][7]!=TYPES.Tile.CORE: game.sim.grid[7][7]=TYPES.Tile.CORE; game.changed.emit(true)
			game.selected=Vector2i(9,9) if state in ["selection","transfer-loot"] else Vector2i(-1,-1)
			game.sim.loot_bags=[{"pos":Vector2i(9,9),"gold":10}] if state=="transfer-loot" else []
			game.sim.corpses=[{"pos":Vector2i(9,9)}] if state=="transfer-loot" else []
			game.tool=TYPES.Tool.TRAP_SPIKE if state in ["placing","notice"] else TYPES.Tool.BUILD_MAGIC_DOOR if state=="placing-long" else TYPES.Tool.NONE
			game.paused=state=="menu" or state.ends_with("paused") or state=="reset"
			game.raid.raid_active=state=="raid"
			game.result_open=state=="result-paused" or state=="defeat-paused"
			game.sim.game_over=state=="defeat-paused"
			game.save_blocked=state=="save-blocked-paused"
			game.save_error="The save could not be read. The file has been kept." if game.save_blocked else ""
			game.confirmation_open=state=="reset"
			hud._reset_pending=state=="reset"
			hud._observe=state=="observe"
			hud._catalog_open=state in ["catalog","doors","treasures","terrain"]
			hud.catalog._choose_category(1 if state=="doors" else 3 if state=="treasures" else 0 if state=="terrain" else 2)
			hud.tools_scroll.scroll_vertical=0
			hud.selection._transfer_open=false
			hud._refresh(false)
			if state=="transfer-loot":
				hud.selection._transfer_open=true
				hud.selection._amount=25
				hud.selection.refresh()
			await _settle()
			if state=="tools-scrolled":
				hud.tools_scroll.scroll_vertical=10000
				await _settle()
			var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
			if state=="scale-before":
				camera.zoom=Vector2.ONE*.75
				await _settle()
			var items: Array=[]
			_describe(hud.root,items)
			observations.append({"size":[extent.x,extent.y],"state":state,"mode":hud.get("mode"),"camera_zoom":camera.zoom.x,"world":str(hud._world_rect),"controls":items,"terrain_rebuilds":game.get_node("PlayArea/World/Terrain").rebuild_count})
			await _image("%d-%s" % [extent.x,state])
			if state=="scale-before": game.get_node("Input")._apply_presentation()
	root.size=Vector2i(1280,720)
	game.paused=false; game.selected=Vector2i(-1,-1); hud._observe=true; hud._catalog_open=false
	game.raid.raid_active=false; game.result_open=false; game.sim.game_over=false; game.save_blocked=false; game.save_error=""; game.confirmation_open=false; hud._reset_pending=false
	for x in range(10,13): game.sim.grid[7][x]=TYPES.Tile.FLOOR
	for y in range(6,9):
		for x in range(13,16): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.changed.emit(true)
	await _settle()
	await _image("extended")
	var file:=FileAccess.open(output+"presentation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t")); file.close()
	game.queue_free(); await process_frame
	print("Forge presentation captured: ",observations.size()," states, plus extension. No player commands or saves.")
	quit()

func _settle() -> void:
	for frame in 8: await process_frame

func _image(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"captures/"+title+".png")

func _describe(node: Node, items: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Control:
		var entry := {"type":node.get_class(),"path":str(node.get_path()),"rect":str(node.get_global_rect()),"minimum":str(node.get_combined_minimum_size()),"text":node.text if node is Button or node is Label else ""}
		# Ellipsis is not a size overflow: measure the full single-line text.
		if node is Label and node.autowrap_mode==TextServer.AUTOWRAP_OFF and not node.text.is_empty():
			var font: Font=node.get_theme_font("font")
			var width := 0.0
			for line in node.text.split("\n"): width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size")).x)
			entry["clipped"]=width>node.size.x+.5
		elif node is Label and node.max_lines_visible>0 and not node.text.is_empty():
			entry["clipped"]=node.get_line_count()>node.max_lines_visible
		items.append(entry)
	for child in node.get_children(): _describe(child,items)
