extends SceneTree
## Presentation capture only: no player commands, save writes or assertions.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const REVIEW := "res://docs/reference/interface-review/compact-hud/"
var observations: Array = []

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var stage := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	var spacing := OS.get_cmdline_user_args().has("--spacing")
	var output := "res://docs/reference/interface-review/spacing-hud/" if spacing else REVIEW+stage+"/"
	DirAccess.make_dir_recursive_absolute(output)
	var game := GAME.instantiate()
	game.save_path=REVIEW+"never-created.save"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var hud=game.get_node("HUD")
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[7][7]=TYPES.Tile.CORE
	game.sim.gold=245; game.sim.core_hp=16 if spacing else 58
	game.notice="Dungeon restored. Preparation resumes."
	game.save_error=""; game.save_blocked=false; hud._welcome=false
	game.changed.emit(true)
	game.get_node("Input").center_core()
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(740,360),Vector2i(320,568)]:
		root.size=extent
		for state in (["tools","tools-scrolled","catalog","observe"] if spacing else ["tools","catalog","observe"]):
			hud._catalog_open=state=="catalog"
			hud._observe=state=="observe"
			hud._refresh(false)
			if spacing: hud.tools_scroll.scroll_vertical=0
			for frame in 8: await process_frame
			if state=="tools-scrolled":
				hud.tools_scroll.scroll_vertical=10000
				for frame in 3: await process_frame
			var controls: Array=[]
			_describe(hud.root,controls)
			observations.append({"size":[extent.x,extent.y],"state":state,"world":str(hud._world_rect),"controls":controls})
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"%d-%s.png" % [extent.x,state])
	var file := FileAccess.open(output+"layout.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t")); file.close()
	game.queue_free(); await process_frame
	print("Compact Forge: ",observations.size()," static captures (",stage,"). No player commands or saves.")
	quit()

func _describe(node: Node, controls: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Control:
		controls.append({"type":node.get_class(),"path":str(node.get_path()),"rect":str(node.get_global_rect()),"minimum":str(node.get_combined_minimum_size()),"text":node.text if node is Label or node is Button else ""})
	for child in node.get_children(): _describe(child,controls)
