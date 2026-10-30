extends SceneTree
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const TYPES=preload("res://scripts/game/game_types.gd")
var output="res://artifacts/master-mobile-review/"
var records: Array=[]
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for frame in 8: await process_frame
func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(output+"captures")
	var game=GAME.instantiate(); game.persistence_enabled=false
	root.add_child(game); game.set_process(false); await process_frame
	var hud=game.get_node("HUD")
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[7][7]=TYPES.Tile.CORE
	for p in [Vector2i(5,5),Vector2i(9,5),Vector2i(9,9)]:
		game.sim.grid[p.y][p.x]=TYPES.Tile.VAULT; game.sim.vault_gold[p]=75
	game.sim.grid[7][9]=TYPES.Tile.ENTRANCE
	game.sim.grid[5][7]=TYPES.Tile.SPIKE; game.sim.trap_charges[Vector2i(7,5)]=2
	game.sim.gold=225; game.raid.raid_timer=24; game.notice="Building"; hud._welcome=false
	game.changed.emit(true)
	for extent in [Vector2i(844,390),Vector2i(740,360),Vector2i(667,375),Vector2i(568,320),Vector2i(390,844),Vector2i(320,568),Vector2i(1280,720)]:
		root.size=extent; await settle(); game.get_node("Input").center_core(); await settle()
		for state in ["idle","radial","radial-unlocked","catalog","catalog-unlocked","catalog-doors","catalog-terrain","catalog-treasures","placing","access","selection","transfer","menu","raid","result","welcome","reset","defeat","blocked"]:
			hud._close_radial(false); hud._catalog_open=false; hud._reset_pending=false
			game.selected=Vector2i(-1,-1); game.tool=TYPES.Tool.NONE; game.preview={}
			game.paused=false; game.result_open=false; game.sim.game_over=false; game.save_blocked=false; game.confirmation_open=false
			game.save_error=""
			game.raid.raid_active=false; game.notice="Building"; hud._welcome=state=="welcome"
			game.progression.xp=280 if state.ends_with("unlocked") or state in ["catalog-doors","catalog-terrain","catalog-treasures"] else 0
			game.get_node("PlayArea/World/Dungeon").access_visible=state=="access"
			game.sim.grid[7][7]=TYPES.Tile.FLOOR if state=="welcome" else TYPES.Tile.CORE
			if state.begins_with("catalog"): hud._catalog_open=true; hud.catalog._choose_category({"catalog-doors":1,"catalog-terrain":0,"catalog-treasures":3}.get(state,2))
			if state=="placing": game.tool=TYPES.Tool.TRAP_SPIKE
			if state in ["selection","transfer"]: game.selected=Vector2i(9,9)
			if state=="menu": game.paused=true
			if state=="raid": game.raid.raid_active=true; game.raid.elapsed_seconds=42; game.sim.core_hp=62
			else: game.sim.core_hp=100
			if state=="result": game.result_open=true; game.raid.last_result={"killed":1,"hero_name":"Neris","escaped":0,"stolen":0}; game.last_reward={"xp":25}
			if state=="reset": game.paused=true; game.confirmation_open=true; hud._reset_pending=true
			if state=="defeat": game.sim.game_over=true; game.sim.core_hp=0
			if state=="blocked": game.save_blocked=true; game.save_error="The save could not be read. The file has been kept."
			hud._last_gold=game.sim.gold; hud._last_hp=game.sim.core_hp
			for child in hud.root.get_children():
				if child.has_meta("transient_feedback"): child.queue_free()
			game.changed.emit(true)
			if state.begins_with("radial"): hud.world_tapped(Vector2i(6,6))
			if state=="transfer": hud.selection._open_transfer()
			await settle()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"captures/%d-%s.png" % [extent.x,state])
			var controls: Array=[]; describe(hud.root,controls)
			records.append({"size":[extent.x,extent.y],"state":state,"world":str(hud._world_rect),"controls":controls})
	var file=FileAccess.open(output+"native-layout.json",FileAccess.WRITE); file.store_string(JSON.stringify(records,"\t")); file.close()
	game.queue_free(); await process_frame
	print("Captured ",records.size()," native states. No player save accessed."); quit()
func describe(node: Node, records_out: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Control:
		var entry={"type":node.get_class(),"path":str(node.get_path()),"rect":str(node.get_global_rect()),"text":node.text if node is Label or node is Button else ""}
		if node is Label and node.autowrap_mode==TextServer.AUTOWRAP_OFF and not node.text.is_empty():
			entry["clipped"]=node.get_theme_font("font").get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size")).x>node.size.x+.5
		records_out.append(entry)
	for child in node.get_children(): describe(child,records_out)
