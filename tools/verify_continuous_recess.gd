extends SceneTree
## Geometry and native captures for the continuous exterior recess proposal.
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const Recess=preload("res://scripts/continuous_recess_geometry.gd")
const Terrain=preload("res://scripts/game/dungeon_terrain.gd")
const OUT="res://artifacts/terrain-recess/continuous/"
var checks:=0
var failures: Array[String]=[]
var records: Array[Dictionary]=[]

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame

func inspect(mesh: Dictionary, cells: Array[Vector2i], label: String) -> void:
	var levels: PackedFloat32Array=mesh.heights
	var points: PackedVector2Array=mesh.uvs
	var vertices: PackedVector3Array=mesh.vertices
	var indices: PackedInt32Array=mesh.indices
	var folded:=0; var nonfinite:=0; var clipped:=0; var misplaced:=0; var raised_floor:=0
	var inconsistent:=0; var slopes:=0; var samples: Dictionary={}
	for i in levels.size():
		var h:=levels[i]; var p:=points[i]
		if not is_finite(h): nonfinite+=1
		if h<0 or h>Terrain.HEIGHT+.000001: clipped+=1
		if samples.has(p) and absf(float(samples[p])-h)>.000001: inconsistent+=1
		samples[p]=h
		if h>.000001 and h<Terrain.HEIGHT-.000001: slopes+=1
		# Brute-force rectangle distances, independent of the spatial lookup.
		var distance:=INF
		for cell in cells:
			var nearest:=p.clamp(Vector2(cell),Vector2(cell)+Vector2.ONE)
			distance=minf(distance,p.distance_to(nearest))
		if distance<.000001 and h>.000001: raised_floor+=1
		if distance<=.55 and h>.000001: misplaced+=1
		if distance>=1.350001 and h<Terrain.HEIGHT-.000001: misplaced+=1
	var covered:=0.0; var projected:=0.0; var smallest:=INF
	for i in range(0,indices.size(),3):
		var a:=indices[i]; var b:=indices[i+1]; var c:=indices[i+2]
		covered+=(points[b]-points[a]).cross(points[c]-points[a])*.5
		var edge_b:=Vector2(vertices[b].x-vertices[a].x,vertices[b].y-vertices[a].y)
		var edge_c:=Vector2(vertices[c].x-vertices[a].x,vertices[c].y-vertices[a].y)
		var area:=edge_b.cross(edge_c)*.5
		projected+=area; smallest=minf(smallest,area)
		if area<=0: folded+=1
	check(nonfinite==0 and clipped==0,label+": all heights stay between floor and wall top")
	check(inconsistent==0,label+": shared positions have one height, including outer panels")
	check(raised_floor==0 and misplaced==0,label+": floor clearance and outer edge follow the excavated cells")
	check(slopes>0 or cells.is_empty(),label+": actual sloped geometry joins floor and rock")
	check(folded==0,label+": no triangle folds over the isometric view or turns into a vertical strip")
	check(absf(covered-4096)<.01 and absf(projected-4096*16384)<10,label+": complete world coverage in plan and projection")
	records.append({"layout":label,"vertices":vertices.size(),"triangles":indices.size()/3,"slope_vertices":slopes,"folded_triangles":folded,"minimum_projected_triangle_area":smallest})

func excavated(game: Node) -> Array[Vector2i]:
	var result: Array[Vector2i]=[]
	for y in game.Types.ROWS:
		for x in game.Types.COLS:
			if game.sim.grid[y][x]!=game.Types.Tile.ROCK: result.append(Vector2i(x,y))
	return result

func capture(preview: Node, stage: String) -> void:
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=size; await settle(); preview.center_review(); await settle()
		if size.y>size.x:
			var view=preview.game.get_node("PlayArea/World/Dungeon")
			var camera: Camera2D=preview.game.get_node("PlayArea/World/Camera2D")
			camera.position=view.grid_to_local(Vector2(3,8.5))-Vector2(0,45)
			camera.force_update_scroll(); await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+stage+"-%dx%d.png" % [size.x,size.y])

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
		inspect(Recess.build(cells,1.35,Terrain.HEIGHT,Terrain.Geometry.EXTENT),cells,label)
	# Retain coverage of the superseded v27 sloped proposal explicitly.
	var preview=SCENE.instantiate(); preview.sloped_recess=true; root.add_child(preview); await settle()
	var game=preview.game
	var terrain=game.get_node("PlayArea/World/Terrain")
	check(not game.persistence_enabled,"Preview disables persistence before entering the tree")
	check(terrain.get_child_count()==1 and not terrain.has_node("CutFaces"),"Preview has a continuous surface instead of standalone cliff faces")
	var original: Dictionary=terrain.geometry.duplicate(true)
	var rebuilds: int=terrain.rebuild_count
	game.changed.emit(false); await settle()
	check(terrain.rebuild_count==rebuilds,"Ordinary HUD changes do not regenerate terrain")
	inspect(original,excavated(game),"demo")
	await capture(preview,"initial")
	var cell:=Vector2i(4,9); var gold: int=game.sim.gold
	game.dig_cell(cell); await settle()
	check(game.sim.grid[cell.y][cell.x]==game.Types.Tile.FLOOR and game.sim.gold==gold-5,"Regression scene really expands the corridor for 5 gold")
	check(terrain.geometry!=original,"Actual excavation updates the recess")
	inspect(terrain.geometry,excavated(game),"expanded-corridor")
	await capture(preview,"expanded")
	game.undo_build(); await settle()
	check(game.sim.gold==gold and terrain.geometry==original,"Undo restores exactly the original continuous terrain and gold")
	# Diagnostic uses the actual native geometry, not a hand-drawn mock-up.
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
render_mode unshaded;
void fragment(){
 float h=COLOR.a;
 vec3 stone=mix(vec3(.10,.15,.23),vec3(.42,.48,.57),h);
	 vec2 line=abs(fract(UV+.5)-.5)/fwidth(UV);
 float grid=1.-smoothstep(.5,1.25,min(line.x,line.y));
 COLOR=vec4(mix(stone,vec3(.63,.48,.79),grid*.5),1.);
}"""
	var material:=ShaderMaterial.new(); material.shader=shader
	terrain.get_node("RockTop").material=material
	game.notice=""; game.changed.emit(false)
	for node in game.get_node("HUD").root.get_children():
		if node.has_meta("transient_feedback"): node.queue_free()
	root.size=Vector2i(1280,720); await settle(); preview.center_review(); await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"geometry.png")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":records},"\t"))
	print("Continuous recess: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
