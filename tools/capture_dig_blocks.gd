extends SceneTree
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/dig-uniform/native/"
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

func check_marker_ink(view: Node2D, targets: Control) -> void:
	var stage := SubViewport.new()
	stage.size = Vector2i(256,256)
	stage.transparent_bg = true
	stage.world_2d = World2D.new()
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var marker = targets.Block.new()
	marker.configure(view, targets.blocks[0].cell)
	var center := Vector2i(128,140)
	marker.position = Vector2(center) - marker.top_center
	stage.add_child(marker)
	for active in [false,true]:
		marker.pressed = active
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := stage.get_texture().get_image()
		check(picture.get_used_rect().has_area(),"The marker actually draws in the isolated viewport")
		var fill := picture.get_pixelv(center+Vector2i(30,8))
		check(fill.a > .15 and fill.a < .5, "The marked tile has a translucent fill at rest and on press")
		for corner: Vector2 in marker.footprint:
			var tip := Vector2i((Vector2(center) + (corner-marker.top_center)*.92).round())
			var bright := false
			for dx in range(-2,3):
				for dy in range(-2,3):
					var ink := picture.get_pixelv(tip+Vector2i(dx,dy))
					if ink.a > .8 and ink.g > .75: bright = true
			check(bright, "Each of the four corners has a bright bracket")
		var bottom := ceili(center.y+marker.support.rect.size.y*.5)+2
		check(picture.get_used_rect().end.y <= bottom, "The tile has no painted sides below its footprint")
	stage.queue_free()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	var preview=SCENE.instantiate(); root.add_child(preview); await settle()
	var game=preview.game
	var hud=game.get_node("HUD")
	var view=game.get_node("PlayArea/World/Dungeon")
	var terrain=game.get_node("PlayArea/World/Terrain")
	await check_marker_ink(view,preview.targets)
	check(is_equal_approx(terrain.cut_margin,1.35),"Actual terrain cutout keeps its wall clearance")
	var original_surface=terrain.get_node("RockTop")
	check(rock_at(terrain,Vector2(-5,-5)),"Rock mass continues far beyond actionable frontier")
	var funded: int=game.sim.gold
	game.sim.gold=0; game.changed.emit(false); await settle()
	check(preview.targets.blocks.is_empty(),"Unaffordable dig actions are not offered")
	check(is_instance_valid(original_surface) and original_surface.is_visible_in_tree(),"No gold never removes the physical rock mass")
	game.sim.gold=funded; game.changed.emit(false); await settle()
	# The affordability fixture is not an actual purchase; omit its transient toast.
	for node in hud.root.get_children():
		if node.has_meta("transient_feedback"): node.queue_free()
	await settle()
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=extent; await settle(); preview.center_review(); await settle()
		check(preview.targets.blocks.size()==view.dig_cells.size(),"One marker per legal rock cell")
		var clickable:=0
		var clickable_picks:=0
		for block in preview.targets.blocks:
			check(block.top_center.is_equal_approx(view.grid_to_local(Vector2(block.cell)+Vector2(.5,.5))),"The excavation tile is centered on the floor of its grid cell")
			check((block.support.max-block.support.min).is_equal_approx(Vector3(.87,.87,0)),"The tap footprint matches the village gift on one plane")
			check(not block.covers(block.footprint[2]+Vector2.DOWN*5.),"The former cube side is outside the tap footprint")
			var plane: Vector2=(Vector2(block.support.min.x,block.support.min.y)+Vector2(block.support.max.x,block.support.max.y))*.5
			check(not rock_at(terrain,plane),"The marker fits in the rock clearance")
			check(game.sim.grid[block.cell.y][block.cell.x]==game.Types.Tile.ROCK,"Each pick targets a logical rock cell")
			var point: Vector2=view.get_global_transform_with_canvas()*block.top_center
			if not hud.blocks_pointer(point) and preview.targets.hit_cell(point/hud.scale.x)==block.cell: clickable+=1
			var pick_point: Vector2=block.preview.get_global_transform_with_canvas().origin
			if not hud.blocks_pointer(pick_point) and preview.targets.hit_cell(pick_point/hud.scale.x)==block.cell: clickable_picks+=1
		check(clickable>0,"Visible rock anchors are tappable at "+str(extent))
		check(clickable_picks>0,"Floating picks are tappable at "+str(extent))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"%dx%d.png" % [extent.x,extent.y])
	root.size=Vector2i(1280,720); await settle(); preview.center_review(); await settle()
	view.dig_guides_visible=false; await settle()
	check(is_instance_valid(original_surface) and original_surface.is_visible_in_tree(),"Bedrock remains when action highlights are hidden")
	view.dig_guides_visible=true; await settle()
	var tile_tapped := false
	for block in preview.targets.blocks:
		var point: Vector2=view.get_global_transform_with_canvas()*block.top_center.lerp(block.footprint[1],.8)
		if hud.blocks_pointer(point) or preview.targets.hit_cell(point/hud.scale.x)!=block.cell: continue
		var cell: Vector2i=block.cell
		var gold: int=game.sim.gold
		var geometry_before: Dictionary=terrain.geometry.duplicate(true)
		var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
		var camera_before:=camera.position
		var event:=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"pressed.png")
		var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=point+Vector2(70,0)
		root.push_input(drag,true); await process_frame
		event=event.duplicate(); event.pressed=false; event.position=drag.position; root.push_input(event,true); await settle()
		check(game.sim.gold==gold and camera.position!=camera_before,"Dragging from a marked site pans without digging")
		preview.center_review(); await settle()
		event=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		event=event.duplicate(); event.pressed=false; root.push_input(event,true); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"Tapping near the painted corner excavates its cell exactly once")
		check(terrain.geometry!=geometry_before,"Dig moves the actual rock cutout around the new floor cell")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"after-dig.png")
		game.undo_build(); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.ROCK and game.sim.gold==gold,"Preview uses normal Undo without saves")
		check(terrain.geometry==geometry_before,"Undo restores the original cutout and its clearance")
		tile_tapped = true
		break
	check(tile_tapped,"Native touch near a marked tile corner was exercised")
	var pick_tapped:=false
	for block in preview.targets.blocks:
		var point: Vector2=block.preview.get_global_transform_with_canvas().origin
		if hud.blocks_pointer(point) or preview.targets.hit_cell(point/hud.scale.x)!=block.cell: continue
		var cell: Vector2i=block.cell
		var gold: int=game.sim.gold
		var event:=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		event=event.duplicate(); event.pressed=false; root.push_input(event,true); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"A pick touch digs its cell for five gold")
		game.undo_build(); await settle()
		pick_tapped=true
		break
	check(pick_tapped,"Native pick touch was exercised")
	check(not game.persistence_enabled,"Preview never reads or writes the player's dungeon")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Dig blocks: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
