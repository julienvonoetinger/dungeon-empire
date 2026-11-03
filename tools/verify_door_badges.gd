extends SceneTree
## Presentation-only regression; uses an isolated, unwritten save path.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const Badge = preload("res://scripts/game/ui/world_badge.gd")
var failures: Array[String] = []
var checks := 0
var out := "res://artifacts/door-badges/"

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func markers(view: Node2D) -> Array:
	return view._markers.filter(func(item): return item.kind=="door")

func check_screen_size(view: Node2D) -> void:
	var scale_to_screen := view.get_canvas_transform().get_scale().x*root.size.x/root.get_visible_rect().size.x
	for item in view._markers:
		var badge: Control = item.node.badge
		if not badge: continue
		var pixels := badge.size.x*badge.scale.x*scale_to_screen
		check(absf(pixels-44)<.2,"%s ring is 44 screen pixels at %s" % [item.kind,root.size])

func state(view: Node2D, expected: float, status: String) -> void:
	var items:=markers(view)
	check(items.size()==2,"Each door must have exactly one status ring")
	for item in items:
		var badge=item.node.badge
		check(badge!=null,"Door uses shared badge")
		if not badge: continue
		check(is_equal_approx(badge.ratio,expected),"Door ring follows remaining resistance")
		check(badge.glyph=="lock" and not badge.segmented,"Door shows a single lock in its durability ring")
		check(badge.get("door_status")==status,"Door state must distinguish opened and broken")
		check(badge.contains_ink(Vector2(29,28)) and not badge.contains_ink(Vector2(43,33)),"The status mark stays inside the circular hit area")
		check(badge.z_index==10 and badge.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Badge above architecture and input-transparent")
		check(not item.node.label.visible,"No duplicate floating door text")
		var arches: Array=view.solid_groups.filter(func(p): return Vector2i(p.at)==item.cell and str(p.id).begins_with("door-") and str(p.id).ends_with("-arch"))
		if not arches.is_empty():
			check(item.node.position.y+badge.position.y+badge.size.y*badge.scale.y <= arches[0].rect.position.y,"Door ring sits above the arch")

func snapshot(name: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+name+".png")

func check_inner_margin() -> void:
	var states := [["coins",0,""],["spike",0,""],["snare",0,""],["void",0,""],
		["coins",1,""],["coins",2,""],["lock",1,"closed"],["lock",2,"closed"],["lock",1,"open"],["lock",1,"broken"]]
	var stage := SubViewport.new()
	const STRIDE := 100
	stage.size = Vector2i(STRIDE * states.size(), STRIDE * 2)
	stage.transparent_bg = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	for i in states.size():
		for row in 2:
			var badge := Badge.new()
			badge.position = Vector2(i*STRIDE+8,row*STRIDE+8)
			badge.scale = Vector2(2,2)
			stage.add_child(badge)
			badge.set_amount(1,3,states[i][1] if row == 0 else 0,true)
			# Lower row is the identical ring alone; subtract it to measure actual drawn ink.
			if row == 0:
				badge.configure(states[i][0],badge.color)
				badge.set_door_status(states[i][2])
	await process_frame
	await RenderingServer.frame_post_draw
	var img := stage.get_texture().get_image()
	for i in states.size():
		var extent := 0.0
		for x in STRIDE:
			for y in STRIDE:
				if img.get_pixel(i*STRIDE+x,y) != img.get_pixel(i*STRIDE+x,y+STRIDE):
					extent = maxf(extent,(Vector2(x+.5,y+.5)-Vector2(50,50)).length()/2.0)
		check(extent > 0 and extent <= 15.5, "%s artwork radius %.1f should leave space before the ring" % [str(states[i]),extent])
		if states[i][0] == "lock":
			var expected := Color("ffd377") if states[i][1] == 1 else Color("e0a2ff")
			if states[i][2] == "open": expected = Color("9de4c9")
			if states[i][2] == "broken": expected = Color("ff9a9e")
			for offset in [-9,9]:
				var actual := img.get_pixel(i*STRIDE+50+offset,58)
				check(Vector3(actual.r,actual.g,actual.b).distance_to(Vector3(expected.r,expected.g,expected.b)) < .04, "Lock body is centered and identifies %s" % str(states[i]))
	stage.queue_free()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	await check_inner_margin()
	var game=GAME.instantiate(); game.save_path=out+"never-created.save"
	game.persistence_enabled=false
	root.add_child(game); game.set_process(false); await process_frame
	game.sim.new_map()
	for i in range(5,12): game.sim.grid[8][i]=TYPES.Tile.FLOOR; game.sim.grid[i][8]=TYPES.Tile.FLOOR
	game.sim.grid[8][8]=TYPES.Tile.CORE
	var cells: Array[Vector2i]=[Vector2i(8,6),Vector2i(10,8)]
	game.sim.grid[6][8]=TYPES.Tile.DOOR; game.sim.grid[8][10]=TYPES.Tile.MAGIC_DOOR
	game.sim.grid[8][6]=TYPES.Tile.VAULT; game.sim.vault_gold[Vector2i(6,8)]=75
	game.sim.grid[10][8]=TYPES.Tile.SPIKE
	game.sim.grid[9][8]=TYPES.Tile.SNARE
	game.sim.grid[8][11]=TYPES.Tile.VOID
	var view: Node2D=game.get_node("PlayArea/World/Dungeon")
	game.changed.emit(true)
	for i in 5: await process_frame
	state(view,1.0,"closed"); check_screen_size(view); await snapshot("closed-landscape")
	var original_nodes:=markers(view).map(func(item): return item.node.get_instance_id())
	for p in cells: game.sim.door_hp[p]=30
	game.frame_updated.emit()
	state(view,.5,"closed")
	check(markers(view).map(func(item): return item.node.get_instance_id())==original_nodes,"Damage updates without rebuilding markers")
	game.select_cell(cells[0])
	check(game.get_node("HUD").selection.detail.text=="30 / 60 HP","Selection retains exact remaining resistance")
	game.cancel_selection()
	await snapshot("damaged-landscape")
	root.size=Vector2i(390,844)
	for i in 8: await process_frame
	game.frame_updated.emit() # Session clock is frozen; normal frames refresh badges.
	check_screen_size(view)
	await snapshot("damaged-portrait")
	root.size=Vector2i(740,360)
	for i in 8: await process_frame
	game.frame_updated.emit()
	check_screen_size(view); await snapshot("damaged-short-landscape")
	root.size=Vector2i(1280,720)
	for p in cells: game.sim.door_hp[p]=0; game.sim.door_opened[p]=true
	game.changed.emit(true); state(view,0.0,"open"); await snapshot("opened-landscape")
	game.select_cell(cells[0])
	check(game.get_node("HUD").selection.detail.text=="Unlocked","Selection identifies unlocked door")
	game.cancel_selection()
	game.sim.door_opened.clear(); game.changed.emit(true)
	state(view,0.0,"broken"); await snapshot("broken-landscape")
	game.select_cell(cells[0])
	check(game.get_node("HUD").selection.detail.text=="Broken · Needs repair","Selection identifies broken door")
	game.cancel_selection()
	game.sim.gold=100
	for p in cells: check(game.sim.repair_door(p),"Repair succeeds")
	game.changed.emit(true); state(view,1.0,"closed")
	for item in view._markers:
		if item.kind=="chest":
			check(item.node.badge.glyph=="coins" and is_equal_approx(item.node.badge.ratio,.5),"Chest shows coins and fill level")
			check(not item.node.badge.contains_ink(Vector2(43,33)),"Free chest has no lock outside the ring")
		if item.kind=="trap":
			var glyphs := {TYPES.Tile.SPIKE:"spike", TYPES.Tile.SNARE:"snare", TYPES.Tile.VOID:"void"}
			check(item.node.badge.glyph==glyphs[game.sim.grid[item.cell.y][item.cell.x]] and item.node.badge.segmented,"Trap uses its own pictogram and charge ring")
	for p in cells: game.sim.grid[p.y][p.x]=TYPES.Tile.FLOOR
	game.changed.emit(true); check(markers(view).is_empty(),"Removing a door removes its badge")
	check(not FileAccess.file_exists(game.save_path),"No save written")
	FileAccess.open(out+"results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	game.queue_free(); await process_frame
	print("Door badges: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
