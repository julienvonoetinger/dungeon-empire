extends SceneTree
## Focused native header review. All data lives in a separate review directory.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const TYPES=preload("res://scripts/game/game_types.gd")
const OUT="res://docs/reference/interface-review/v11-header-alignment/"
var records: Array=[]
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for frame in 8: await process_frame
func run() -> void:
	var stage:="before" if "--before" in OS.get_cmdline_user_args() else "after"
	var dest:=OUT+stage+"/"
	DirAccess.make_dir_recursive_absolute(dest)
	var game=GAME.instantiate(); game.save_path=OUT+"never-created.save"
	root.add_child(game); game.set_process(false); await process_frame
	var hud=game.get_node("HUD"); hud._welcome=false
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[7][7]=TYPES.Tile.CORE
	for p in [Vector2i(5,5),Vector2i(9,5),Vector2i(9,9)]:
		game.sim.grid[p.y][p.x]=TYPES.Tile.VAULT; game.sim.vault_gold[p]=75
	game.sim.grid[7][9]=TYPES.Tile.ENTRANCE
	game.sim.grid[5][7]=TYPES.Tile.SPIKE; game.sim.trap_charges[Vector2i(7,5)]=2
	game.notice="Building"
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(568,299),Vector2i(390,844),Vector2i(320,568)]:
		root.size=extent; await settle(); game.get_node("Input").center_core(); await settle()
		for state in ["idle","raid","access","after-raid","large-gold","pause"]:
			game.paused=state=="pause"; game.save_error=""; game.result_open=false
			game.sim.gold=38400 if state=="large-gold" else 225
			game.raid.raid_active=state in ["raid","access"]
			game.raid.elapsed_seconds=74; game.raid.raid_timer=74
			game.sim.core_hp=34 if state in ["raid","access"] else 100
			game.get_node("PlayArea/World/Dungeon").access_visible=state=="access"
			hud._last_gold=game.sim.gold; hud._last_hp=game.sim.core_hp
			game.changed.emit(true); await settle()
			for child in hud.root.get_children():
				if child.has_meta("transient_feedback"): child.queue_free()
			await settle()
			await RenderingServer.frame_post_draw
			var frame:=root.get_texture().get_image()
			frame.save_png(dest+"%d-%s.png" % [extent.x,state])
			var rect:=Rect2i(hud.header.position, hud.header.size)
			frame.get_region(rect).save_png(dest+"%d-%s-header.png" % [extent.x,state])
			var labels: Array=[]
			for child in hud.header.get_children():
				if child is Label:
					var font: Font=child.get_theme_font("font")
					var font_size: int=child.get_theme_font_size("font_size")
					labels.append({"text":child.text,"rect":str(child.get_rect()),"clipped":font.get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>child.size.x+.5,"height_ok":font.get_height(font_size)<=child.size.y+.5})
			records.append({"size":[extent.x,extent.y],"state":state,"header":str(rect),"eye":str(hud.header.eye.get_rect()),"hint":hud.hint.text,"labels":labels})
	var file=FileAccess.open(dest+"layout.json",FileAccess.WRITE); file.store_string(JSON.stringify(records,"\t")); file.close()
	game.queue_free(); await process_frame
	print("Captured ",records.size()," isolated native header views (",stage,")."); quit()
