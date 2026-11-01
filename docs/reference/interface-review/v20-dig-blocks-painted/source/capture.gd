extends SceneTree
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/dig-blocks-painted/"
var failures: Array[String]=[]
var checks:=0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	var preview=SCENE.instantiate(); root.add_child(preview); await settle()
	var game=preview.game
	var hud=game.get_node("HUD")
	var view=game.get_node("PlayArea/World/Dungeon")
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=extent; await settle(); preview.center_review(); await settle()
		check(preview.targets.blocks.size()==view.dig_cells.size(),"One block per legal rock cell")
		var clickable:=0
		var clickable_sides:=0
		for block in preview.targets.blocks:
			check(is_equal_approx(block.support.max.z,float(view._definition.get("entries")["wall-v-0"].bounds.max[2])),"Block exactly matches wall height")
			var point: Vector2=view.get_global_transform_with_canvas()*block.top_center
			if not hud.blocks_pointer(point) and preview.targets.hit_cell(point/hud.scale.x)==block.cell: clickable+=1
			for face_index in 2:
				var middle:=Vector2.ZERO
				for vertex in block.faces[face_index]: middle+=vertex/4
				var side: Vector2=view.get_global_transform_with_canvas()*middle
				if not hud.blocks_pointer(side) and preview.targets.hit_cell(side/hud.scale.x)==block.cell: clickable_sides+=1
		check(clickable>0,"Visible tops are clickable at "+str(extent))
		check(clickable_sides>0,"Exposed side faces also identify their own cube")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"%dx%d.png" % [extent.x,extent.y])
	root.size=Vector2i(1280,720); await settle(); preview.center_review(); await settle()
	for block in preview.targets.blocks:
		var point: Vector2=view.get_global_transform_with_canvas()*block.top_center
		if hud.blocks_pointer(point) or preview.targets.hit_cell(point/hud.scale.x)!=block.cell: continue
		var cell: Vector2i=block.cell
		var gold: int=game.sim.gold
		var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
		var camera_before:=camera.position
		var event:=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=point+Vector2(70,0)
		root.push_input(drag,true); await process_frame
		event=event.duplicate(); event.pressed=false; event.position=drag.position; root.push_input(event,true); await settle()
		check(game.sim.gold==gold and camera.position!=camera_before,"Dragging from a cube pans without digging")
		preview.center_review(); await settle()
		event=InputEventScreenTouch.new(); event.index=0; event.pressed=true; event.position=point
		root.push_input(event,true); await process_frame
		event=event.duplicate(); event.pressed=false; root.push_input(event,true); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"Tapping a raised top excavates its own grid cell exactly once")
		game.undo_build(); await settle()
		check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.ROCK and game.sim.gold==gold,"Preview uses normal Undo without saves")
		break
	check(not game.persistence_enabled,"Preview never reads or writes the player's dungeon")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Dig blocks: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
