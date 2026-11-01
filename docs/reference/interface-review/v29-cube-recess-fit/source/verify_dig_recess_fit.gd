extends SceneTree
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/dig-recess-fit/"
var checks:=0
var failures: Array[String]=[]
var intersections: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func bounds(polygon: PackedVector2Array) -> Rect2:
	var result:=Rect2(polygon[0],Vector2.ZERO)
	for p in polygon: result=result.expand(p)
	return result
func area(polygon: PackedVector2Array) -> float:
	var sum:=0.0
	for i in polygon.size(): sum+=polygon[i].cross(polygon[(i+1)%polygon.size()])
	return absf(sum)*.5
func inspect(preview: Node, stage: String) -> void:
	var terrain=preview.game.get_node("PlayArea/World/Terrain")
	var view=preview.game.get_node("PlayArea/World/Dungeon")
	var upper: Array=terrain.geometry.top
	var upper_bounds: Array[Rect2]=[]
	for polygon in upper: upper_bounds.append(bounds(polygon))
	for block in preview.targets.blocks:
		var physical:=0.0; var projected:=0.0
		for face_index in block.faces.size():
			var polygon:=PackedVector2Array()
			for p in block.faces[face_index]: polygon.append(view.local_to_grid(p,terrain.HEIGHT))
			var rectangle:=bounds(polygon)
			for i in upper.size():
				if not rectangle.intersects(upper_bounds[i]): continue
				for intersection in Geometry2D.intersect_polygons(polygon,upper[i]):
					var amount:=area(intersection)
					projected+=amount
					if face_index==0: physical+=amount
		check(physical<.0001,stage+": full footprint clears the exterior rock at "+str(block.cell))
		check(projected<.0001,stage+": visible cube faces do not paint over upper rock at "+str(block.cell))
		if physical>=.0001 or projected>=.0001: intersections.append({"stage":stage,"cell":str(block.cell),"physical_area":physical,"projected_area":projected})
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var preview=SCENE.instantiate(); root.add_child(preview)
	for i in 8: await process_frame
	var terrain=preview.game.get_node("PlayArea/World/Terrain")
	var original: Dictionary=terrain.geometry.duplicate(true)
	var original_grid: Array=preview.game.sim.grid.duplicate(true)
	var original_gold: int=preview.game.sim.gold
	inspect(preview,"initial")
	preview.game.dig_cell(Vector2i(4,9))
	for i in 8: await process_frame
	inspect(preview,"expanded")
	preview.game.undo_build()
	for i in 2: await process_frame
	check(terrain.geometry==original,"Undo restores the original silhouette clearance")
	var rng:=RandomNumberGenerator.new(); rng.seed=241025
	var transactions:=0
	for step in 24:
		if preview.targets.blocks.is_empty(): break
		var cell: Vector2i=preview.targets.blocks[rng.randi_range(0,preview.targets.blocks.size()-1)].cell
		var gold: int=preview.game.sim.gold
		preview.game.dig_cell(cell)
		for i in 2: await process_frame
		check(preview.game.sim.gold==gold-5,"Sweep performs paid excavation "+str(step))
		transactions+=1; inspect(preview,"dig-"+str(step))
	for step in transactions:
		preview.game.undo_build()
		for i in 2: await process_frame
		inspect(preview,"undo-"+str(step))
	check(transactions==24,"Exercise all 24 planned expansions")
	check(terrain.geometry==original and preview.game.sim.grid==original_grid and preview.game.sim.gold==original_gold,"All undos restore terrain, cells and balance")
	var surface=terrain.get_node("RockTop")
	preview.game.sim.gold=0; preview.game.changed.emit(false)
	for i in 2: await process_frame
	check(preview.targets.blocks.is_empty() and terrain.get_node("RockTop")==surface and terrain.geometry==original,"Money hides the actions without changing the physical cut")
	preview.game.sim.gold=original_gold; preview.game.changed.emit(false)
	check(not preview.game.persistence_enabled,"No player saves")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"intersections":intersections,"expansions":transactions,"seed":241025},"\t"))
	print("Dig recess fit: ",checks," checks, ",failures.size()," failures")
	for failure in failures.slice(0,8): print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
