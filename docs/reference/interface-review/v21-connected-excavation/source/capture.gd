extends SceneTree
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/dig-terrain/"
var failures: Array[String]=[]
var checks:=0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func rock_at(terrain: Node2D, point: Vector2) -> bool:
	for polygon in terrain.geometry.top:
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	var preview=SCENE.instantiate(); root.add_child(preview); await settle()
	var game=preview.game
	var hud=game.get_node("HUD")
	var view=game.get_node("PlayArea/World/Dungeon")
	var terrain=game.get_node("PlayArea/World/Terrain")
	check(is_equal_approx(terrain.cut_margin,.23),"Connected rock keeps a narrow real clearance beside masonry")
	var original_surface=terrain.get_node("RockTop")
	check(rock_at(terrain,Vector2(-5,-5)),"Rock mass continues far beyond actionable frontier")
	var funded: int=game.sim.gold
	game.sim.gold=0; game.changed.emit(false); await settle()
	check(preview.targets.blocks.is_empty(),"Unaffordable dig actions are not offered")
	check(is_instance_valid(original_surface) and original_surface.is_visible_in_tree(),"No gold never removes the physical rock mass")
	game.sim.gold=funded; game.changed.emit(false); await settle()
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=extent; await settle(); preview.center_review(); await settle()
		check(preview.targets.blocks.size()==view.dig_cells.size(),"One block per legal rock cell")
		var clickable:=0
		for block in preview.targets.blocks:
			check(is_equal_approx(block.support.max.z,float(view._definition.get("entries")["wall-v-0"].bounds.max[2])),"Block exactly matches wall height")
			check(block.faces.size()==1,"Action marks have no freestanding rock flanks")
			var on_rock:=false
			var plane: Vector2=(Vector2(block.support.min.x,block.support.min.y)+Vector2(block.support.max.x,block.support.max.y))*.5
			for polygon in terrain.geometry.top:
				if Geometry2D.is_point_in_polygon(plane,polygon): on_rock=true; break
			check(on_rock,"Every target lies on the continuous raised terrain")
			var point: Vector2=view.get_global_transform_with_canvas()*block.top_center
			if not hud.blocks_pointer(point) and preview.targets.hit_cell(point/hud.scale.x)==block.cell: clickable+=1
		check(clickable>0,"Visible tops are clickable at "+str(extent))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"%dx%d.png" % [extent.x,extent.y])
	root.size=Vector2i(1280,720); await settle(); preview.center_review(); await settle()
	view.dig_guides_visible=false; await settle()
	check(is_instance_valid(original_surface) and original_surface.is_visible_in_tree(),"Bedrock remains when action highlights are hidden")
	view.dig_guides_visible=true; await settle()
	for block in preview.targets.blocks:
		var point: Vector2=view.get_global_transform_with_canvas()*block.top_center
		if hud.blocks_pointer(point) or preview.targets.hit_cell(point/hud.scale.x)!=block.cell: continue
		var cell: Vector2i=block.cell
		var gold: int=game.sim.gold
		var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
		var camera_before:=camera.position
		var event:=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"pressed.png")
		var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=point+Vector2(70,0)
		root.push_input(drag,true); await process_frame
		event=event.duplicate(); event.pressed=false; event.position=drag.position; root.push_input(event,true); await settle()
		check(game.sim.gold==gold and camera.position!=camera_before,"Dragging from a cube pans without digging")
		preview.center_review(); await settle()
		event=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		event=event.duplicate(); event.pressed=false; root.push_input(event,true); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"Tapping a raised top excavates its own grid cell exactly once")
		check(not rock_at(terrain,Vector2(cell)+Vector2(.5,.5)),"Dig actually removes terrain from the purchased cell")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"after-dig.png")
		game.undo_build(); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.ROCK and game.sim.gold==gold,"Preview uses normal Undo without saves")
		check(rock_at(terrain,Vector2(cell)+Vector2(.5,.5)),"Undo restores the continuous rock surface")
		break
	check(not game.persistence_enabled,"Preview never reads or writes the player's dungeon")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Dig blocks: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
