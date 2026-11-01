extends SceneTree
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const Cut=preload("res://scripts/excavated_recess_geometry.gd")
const Terrain=preload("res://scripts/game/dungeon_terrain.gd")
const OUT="res://artifacts/excavated-recess/"
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func inspect_contour(geometry: Dictionary, cells: Array[Vector2i], stage: String) -> void:
	var degree: Dictionary={}; var top_vertices: Dictionary={}; var off_edge:=0
	for polygon: PackedVector2Array in geometry.top:
		for p in polygon: top_vertices["%.4f,%.4f" % [p.x,p.y]]=true
	for edge: PackedVector2Array in geometry.edges:
		for p in edge:
			var key: String="%.4f,%.4f" % [p.x,p.y]
			degree[key]=degree.get(key,0)+1
			if not top_vertices.has(key): off_edge+=1
			var distance:=INF
			for cell in cells: distance=minf(distance,p.distance_to(p.clamp(Vector2(cell),Vector2(cell)+Vector2.ONE)))
			if absf(distance-1.35)>.025: off_edge+=1
	var unjoined:=0
	for count in degree.values():
		if count!=2: unjoined+=1
	check(unjoined==0,stage+": every cut endpoint joins exactly one next segment, no isolated strips")
	check(off_edge==0,stage+": rock top and section share the same edge at the exterior clearance")
	var covered:=0
	for cell in cells:
		for polygon: PackedVector2Array in geometry.top:
			if Geometry2D.is_point_in_polygon(Vector2(cell)+Vector2(.5,.5),polygon): covered+=1; break
	check(covered==0,stage+": upper rock never refills an excavated cell")
func inspect(terrain: Node2D, stage: String) -> void:
	var faces:=terrain.get_node_or_null("CutFaces") as MeshInstance2D
	check(faces!=null,stage+": a rock cross-section separates the raised exterior from the lower floor")
	if faces==null: return
	var arrays: Array=faces.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var bad:=0
	for i in range(0,vertices.size(),4):
		for j in 2:
			var lower:=vertices[i+j]; var upper:=vertices[i+3-j]
			if absf(lower.x-upper.x)>.001 or absf(lower.y-upper.y-terrain.HEIGHT*156.767343538)>.001: bad+=1
	check(bad==0,stage+": all exposed faces join the floor directly to wall height")
	check(terrain.get_node("RockTop").get_index()>faces.get_index(),stage+": foreground upper rock hides lower faces")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var layouts: Dictionary={"empty":[],"single":[Vector2i(4,4)],"concave":[Vector2i(4,4),Vector2i(4,5),Vector2i(5,5)],"separate":[Vector2i(2,2),Vector2i(6,6)]}
	var ring: Array[Vector2i]=[]
	for y in 9:
		for x in 9:
			if x==0 or x==8 or y==0 or y==8: ring.append(Vector2i(x,y))
	layouts["rock-island"]=ring
	for label in layouts:
		var cells: Array[Vector2i]=[]; cells.assign(layouts[label])
		inspect_contour(Cut.build(cells,1.35,Terrain.Geometry.EXTENT),cells,label)
	var preview=SCENE.instantiate(); root.add_child(preview); await settle()
	var game=preview.game; var terrain=game.get_node("PlayArea/World/Terrain")
	check(not game.persistence_enabled,"Fixture cannot access player saves")
	var original: Dictionary=terrain.geometry.duplicate(true)
	inspect(terrain,"initial")
	inspect_contour(terrain.geometry,terrain._occupancy,"initial")
	var gold: int=game.sim.gold
	game.dig_cell(Vector2i(4,9)); await settle()
	check(game.sim.gold==gold-5 and game.sim.grid[9][4]==game.Types.Tile.FLOOR,"Actually expand the corridor")
	inspect(terrain,"expanded")
	inspect_contour(terrain.geometry,terrain._occupancy,"expanded")
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=size; await settle(); preview.center_review(); await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"expanded-%dx%d.png" % [size.x,size.y])
	game.undo_build(); await settle()
	check(game.sim.gold==gold and terrain.geometry==original,"Undo exactly restores the original cut and balance")
	root.size=Vector2i(1280,720); await settle(); preview.center_review(); await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"initial-1280x720.png")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Excavated recess: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
