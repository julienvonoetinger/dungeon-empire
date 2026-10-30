extends SceneTree
## Presentation-only regression; uses an isolated, unwritten save path.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
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

func state(view: Node2D, expected: float, status: String) -> void:
	var items:=markers(view)
	check(items.size()==2,"Each door must have exactly one status ring")
	for item in items:
		var badge=item.node.badge
		check(badge!=null,"Door uses shared badge")
		if not badge: continue
		check(is_equal_approx(badge.ratio,expected),"Door ring follows remaining resistance")
		check(badge.glyph=="door" and not badge.segmented,"Continuous durability ring with door icon")
		check(badge.get("door_status")==status,"Door state must distinguish opened and broken")
		check(badge.z_index==10 and badge.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Badge above architecture and input-transparent")
		check(not item.node.label.visible,"No duplicate floating door text")
		var arches: Array=view.solid_groups.filter(func(p): return Vector2i(p.at)==item.cell and str(p.id).begins_with("door-") and str(p.id).ends_with("-arch"))
		if not arches.is_empty():
			check(item.node.position.y+badge.position.y+badge.size.y*badge.scale.y <= arches[0].rect.position.y,"Door ring sits above the arch")

func snapshot(name: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+name+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var game=GAME.instantiate(); game.save_path=out+"never-created.save"
	root.add_child(game); game.set_process(false); await process_frame
	game.sim.new_map()
	for i in range(5,12): game.sim.grid[8][i]=TYPES.Tile.FLOOR; game.sim.grid[i][8]=TYPES.Tile.FLOOR
	game.sim.grid[8][8]=TYPES.Tile.CORE
	var cells: Array[Vector2i]=[Vector2i(8,6),Vector2i(10,8)]
	game.sim.grid[6][8]=TYPES.Tile.DOOR; game.sim.grid[8][10]=TYPES.Tile.MAGIC_DOOR
	game.sim.grid[8][6]=TYPES.Tile.VAULT; game.sim.vault_gold[Vector2i(6,8)]=75
	game.sim.grid[10][8]=TYPES.Tile.SPIKE
	var view: Node2D=game.get_node("PlayArea/World/Dungeon")
	game.changed.emit(true)
	for i in 5: await process_frame
	state(view,1.0,"closed"); await snapshot("closed-landscape")
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
	for item in markers(view):
		var pixels: float=item.node.badge.scale.x*42*view.get_canvas_transform().get_scale().x*root.size.x/root.get_visible_rect().size.x
		check(absf(pixels-32)<.1,"Door ring stays 32 screen pixels in portrait")
	await snapshot("damaged-portrait")
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
		if item.kind=="chest": check(item.node.badge.glyph=="coins" and is_equal_approx(item.node.badge.ratio,.5),"Chest ring unchanged")
		if item.kind=="trap": check(item.node.badge.glyph=="spike" and item.node.badge.segmented,"Trap ring unchanged")
	for p in cells: game.sim.grid[p.y][p.x]=TYPES.Tile.FLOOR
	game.changed.emit(true); check(markers(view).is_empty(),"Removing a door removes its badge")
	check(not FileAccess.file_exists(game.save_path),"No save written")
	FileAccess.open(out+"results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	game.queue_free(); await process_frame
	print("Door badges: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
