extends SceneTree
## Isolated presentation inventory. No player-save reads/writes or raid simulation.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/interface-review/implementation/"
var observations: Array = []
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT+"captures")
	var game := GAME.instantiate()
	game.save_path=OUT+"never-created.save"
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
		game.sim.vault_gold[p]=100
	game.sim.gold=300
	game.notice="Aménagement"; game.save_error=""; game.save_blocked=false; hud._welcome=false
	game.changed.emit(true)
	game.get_node("Input").center_core()
	for extent in [Vector2i(844,390),Vector2i(740,360),Vector2i(1280,720),Vector2i(390,844),Vector2i(320,568)]:
		root.size=extent
		for state in ["tools","observe","catalog","selection","transfer-loot","menu","raid","result-paused","reset","defeat-paused","save-blocked-paused"]:
			game.selected=Vector2i(9,9) if state in ["selection","transfer-loot"] else Vector2i(-1,-1)
			game.sim.loot_bags=[{"pos":Vector2i(9,9),"gold":10}] if state=="transfer-loot" else []
			game.sim.corpses=[{"pos":Vector2i(9,9)}] if state=="transfer-loot" else []
			game.tool=TYPES.Tool.NONE
			game.paused=state=="menu" or state.ends_with("paused") or state=="reset"
			game.raid.raid_active=state=="raid"
			game.result_open=state=="result-paused" or state=="defeat-paused"
			game.sim.game_over=state=="defeat-paused"
			game.save_blocked=state=="save-blocked-paused"
			game.save_error="Sauvegarde illisible : le fichier est conservé." if game.save_blocked else ""
			game.confirmation_open=state=="reset"
			hud._reset_pending=state=="reset"
			hud._observe=state=="observe"
			hud._catalog_open=state=="catalog"
			hud._refresh(false)
			if state=="transfer-loot":
				hud.selection._transfer_open=true
				hud.selection._amount=25
				hud.selection.refresh()
			await _settle()
			var items: Array=[]
			_describe(hud.root,items)
			observations.append({"size":[extent.x,extent.y],"state":state,"world":str(hud._world_rect),"controls":items,"terrain_rebuilds":game.get_node("PlayArea/World/Terrain").rebuild_count})
			await _image("%d-%s" % [extent.x,state])
	root.size=Vector2i(1280,720)
	game.paused=false; game.selected=Vector2i(-1,-1); hud._observe=true; hud._catalog_open=false
	game.raid.raid_active=false; game.result_open=false; game.sim.game_over=false; game.save_blocked=false; game.save_error=""; game.confirmation_open=false; hud._reset_pending=false
	for x in range(10,13): game.sim.grid[7][x]=TYPES.Tile.FLOOR
	for y in range(6,9):
		for x in range(13,16): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.changed.emit(true)
	await _settle()
	await _image("extended")
	var file:=FileAccess.open(OUT+"presentation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t")); file.close()
	game.queue_free(); await process_frame
	print("Forge presentation captured: ",observations.size()," states, plus extension. No player commands or saves.")
	quit()

func _settle() -> void:
	for frame in 8: await process_frame

func _image(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"captures/"+title+".png")

func _describe(node: Node, items: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Button or node is PanelContainer:
		items.append({"type":node.get_class(),"path":str(node.get_path()),"rect":str(node.get_global_rect()),"minimum":str(node.get_combined_minimum_size()),"text":node.text if node is Button else ""})
	for child in node.get_children(): _describe(child,items)
