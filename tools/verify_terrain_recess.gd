extends SceneTree
## A lower cut face must never paint over the upper rock surface in front of it.
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
var output_dir: String="res://artifacts/terrain-recess/"
var checks:=0
var failures: Array[String]=[]
var samples: Array[Dictionary]=[]
var top_strips: Dictionary={}
var topology_mode:=false
var cut_mode:=false
var overlap_focus:=Vector2.ZERO
var has_overlap_focus:=false
var skipped_no_overlap: Array[String]=[]

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func index_top(terrain: Node2D) -> void:
	top_strips.clear()
	for polygon: PackedVector2Array in terrain.geometry.top:
		var bounds:=Rect2(polygon[0],Vector2.ZERO)
		for point in polygon: bounds=bounds.expand(point)
		for strip in range(floori(bounds.position.x*2),floori(bounds.end.x*2)+1):
			if not top_strips.has(strip): top_strips[strip]=[]
			top_strips[strip].append(polygon)
func rock_at(point: Vector2) -> bool:
	for polygon in top_strips.get(floori(point.x*2),[]):
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	return false
func inspect(preview: Node, extent: Vector2i, stage: String) -> void:
	root.size=extent; await settle(); preview.center_review(); await settle()
	var view: Node2D=preview.game.get_node("PlayArea/World/Dungeon")
	var terrain: Node2D=preview.game.get_node("PlayArea/World/Terrain")
	var hud=preview.game.get_node("HUD")
	if extent.y>extent.x:
		# Pan to the recess under test; the central portrait crop otherwise
		# contains the room, while the problematic outer edge is offscreen.
		var camera: Camera2D=preview.game.get_node("PlayArea/World/Camera2D")
		camera.position=view.grid_to_local(Vector2(3,8.5))-Vector2(0,45)
		if cut_mode and has_overlap_focus: camera.position=overlap_focus
		camera.force_update_scroll(); await settle()
	var faces: MeshInstance2D=terrain.get_node("CutFaces")
	if topology_mode:
		# Flat diagnostic materials expose the actual mesh independently of art.
		var colors: Dictionary={"RawGround":Color(.10,.13,.20),"CutFaces":Color(.20,.26,.34),"RockTop":Color(.46,.51,.58)}
		for name in colors:
			var material:=ShaderMaterial.new()
			var shader:=Shader.new()
			shader.code="shader_type canvas_item; render_mode unshaded; uniform vec4 tone: source_color; void fragment(){COLOR=tone;}"
			material.shader=shader; material.set_shader_parameter("tone",colors[name])
			terrain.get_node(name).material=material
	index_top(terrain)
	faces.hide(); await settle(); await RenderingServer.frame_post_draw
	var without:=root.get_texture().get_image()
	faces.show(); await settle(); await RenderingServer.frame_post_draw
	var with_faces:=root.get_texture().get_image()
	var arrays: Array=faces.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var canvas: Transform2D=terrain.get_global_transform_with_canvas()
	var image_scale:=Vector2(with_faces.get_size())/root.get_visible_rect().size
	var tested: Dictionary={}
	var violations:=0
	var inspected:=0
	var overlap_points: Array[Vector2]=[]
	for offset in range(0,vertices.size(),4):
		var face:=PackedVector2Array()
		for i in 4: face.append((canvas*Vector2(vertices[offset+i].x,vertices[offset+i].y))*image_scale)
		var bounds:=Rect2(face[0],Vector2.ZERO)
		for p in face: bounds=bounds.expand(p)
		for y in range(maxi(0,ceili(bounds.position.y)),mini(with_faces.get_height(),ceili(bounds.end.y)),1 if cut_mode else 2):
			for x in range(maxi(0,ceili(bounds.position.x)),mini(with_faces.get_width(),ceili(bounds.end.x)),1 if cut_mode else 2):
				var pixel:=Vector2i(x,y)
				if tested.has(pixel): continue
				var centre:=Vector2(pixel)+Vector2(.5,.5)
				if not Geometry2D.is_point_in_polygon(centre,face): continue
				tested[pixel]=true
				var screen: Vector2=centre/image_scale
				if hud.blocks_pointer(screen): continue
				var rock_interior:=true
				for delta in [Vector2.ZERO,Vector2(2,0),Vector2(-2,0),Vector2(0,2),Vector2(0,-2),Vector2(2,2),Vector2(-2,2),Vector2(2,-2),Vector2(-2,-2)]:
					var local: Vector2=canvas.affine_inverse()*((centre+delta)/image_scale)
					if not rock_at(view.local_to_grid(local,terrain.HEIGHT)): rock_interior=false; break
				if not rock_interior: continue
				inspected+=1
				overlap_points.append(canvas.affine_inverse()*screen)
				var a:=without.get_pixel(x,y); var b:=with_faces.get_pixel(x,y)
				if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>.02: violations+=1
	if inspected==0 and cut_mode:
		# A swept opening may expose every face without any stable overlap.
		# Report missing pixel coverage explicitly, never count a vacuous pass.
		skipped_no_overlap.append(stage+str(extent))
	else:
		check(inspected>0,"Fixture samples a cut-face/upper-rock projection overlap at "+stage+str(extent))
		check(violations==0,"Upper rock occludes lower cut faces at "+stage+str(extent)+": "+str(violations)+" wrong pixels")
	if extent.x==1280 and not overlap_points.is_empty():
		overlap_focus=overlap_points[overlap_points.size()/2]; has_overlap_focus=true
	samples.append({"stage":stage,"size":str(extent),"inspected":inspected,"wrong_pixels":violations})
	with_faces.save_png(output_dir+("topology-" if topology_mode else "")+stage+"-%dx%d.png" % [extent.x,extent.y])
func run() -> void:
	cut_mode=OS.get_cmdline_user_args().has("--cut")
	if cut_mode: output_dir="res://artifacts/excavated-recess/occlusion/"
	DirAccess.make_dir_recursive_absolute(output_dir)
	topology_mode=OS.get_cmdline_user_args().has("--topology")
	# Preserve a regression for the shared vertical renderer as well as the
	# continuous preview, which has its own height-field fixture.
	var preview=SCENE.instantiate(); preview.continuous_recess=cut_mode; root.add_child(preview); await settle()
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]: await inspect(preview,extent,"initial")
	var cell:=Vector2i(4,9)
	var gold: int=preview.game.sim.gold
	preview.game.dig_cell(cell); await settle()
	check(preview.game.sim.grid[cell.y][cell.x]==preview.game.Types.Tile.FLOOR and preview.game.sim.gold==gold-5,"Recess fixture actually extends the corridor")
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]: await inspect(preview,extent,"expanded")
	check(not preview.game.persistence_enabled,"Recess fixture does not access player saves")
	FileAccess.open(output_dir+("topology-report.json" if topology_mode else "report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples,"skipped_no_overlap":skipped_no_overlap},"\t"))
	print("Terrain recess: ",checks," checks, ",failures.size()," failures")
	if not skipped_no_overlap.is_empty(): print("Pixel comparisons skipped (no stable overlap): ",skipped_no_overlap.size())
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
