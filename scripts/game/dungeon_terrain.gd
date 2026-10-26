extends Node2D
## Fixed map coverage (16x16 + generous camera margin). No per-frame rebuilds.
const Geometry = preload("res://scripts/game/terrain_geometry.gd")
const MaterialShader = preload("res://shaders/dungeon_terrain.gdshader")
const Types = preload("res://scripts/game/game_types.gd")
const HEIGHT := .3133333333333333
var session: IsometricGameSession
var _occupancy: Array[Vector2i] = []
var _built := false
var rebuild_count := 0
var geometry: Dictionary = {}

func _ready() -> void:
	session = owner as IsometricGameSession
	z_index = -10
	session.changed.connect(_changed)

static func project(p: Vector2, height: float = 0) -> Vector3:
	return Vector3((p.x-p.y)*128, (p.x+p.y)*64-height*156.767343538, 0)

func _changed(structure: bool) -> void:
	if not structure and _built: return
	var cells: Array[Vector2i] = []
	for y in Types.ROWS:
		for x in Types.COLS:
			if session.sim.grid[y][x] != Types.Tile.ROCK: cells.append(Vector2i(x,y))
	if _built and cells == _occupancy: return
	_occupancy = cells
	_built = true
	rebuild_count += 1
	for child in get_children(): remove_child(child); child.queue_free()
	geometry = Geometry.build(cells)
	var bounds: Rect2 = Geometry.EXTENT
	_add_surface([PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])],0,1,"RawGround")
	_add_surface(geometry.top,HEIGHT,0,"RockTop")
	_add_faces()

func _material(surface: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = MaterialShader
	material.set_shader_parameter("surface",surface)
	for name in ["quiet","strata","mineral"]: material.set_shader_parameter(name,load("res://assets/dungeon/bedrock/"+name+".png"))
	return material

func _mesh(vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, colors: PackedColorArray, surface: int, title: String) -> void:
	if indices.is_empty(): return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_TEX_UV]=uvs; arrays[Mesh.ARRAY_INDEX]=indices; arrays[Mesh.ARRAY_COLOR]=colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance2D.new()
	node.name=title; node.mesh=mesh; node.material=_material(surface)
	add_child(node)

func _add_surface(polygons: Array, height: float, surface: int, title: String) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()
	for polygon: PackedVector2Array in polygons:
		var triangles := Geometry2D.triangulate_polygon(polygon)
		if triangles.is_empty(): continue
		var offset := vertices.size()
		for p in polygon:
			vertices.append(project(p,height)); uvs.append(p); colors.append(Color.WHITE)
		for index in triangles: indices.append(offset+index)
	_mesh(vertices,uvs,indices,colors,surface,title)

func _add_faces() -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()
	for contour: PackedVector2Array in geometry.contours:
		for i in contour.size():
			var a := contour[i]
			var b := contour[(i+1)%contour.size()]
			var delta := b-a
			if delta.x-delta.y <= .000001: continue
			var axis := 0 if absf(delta.x)>absf(delta.y) else 1
			var offset := vertices.size()
			vertices.append_array([project(a),project(b),project(b,HEIGHT),project(a,HEIGHT)])
			uvs.append_array([Vector2(a[axis],0),Vector2(b[axis],0),Vector2(b[axis],HEIGHT),Vector2(a[axis],HEIGHT)])
			for k in 4: colors.append(Color.WHITE if axis==0 else Color(.85,.85,.85))
			for k in [0,1,2,0,2,3]: indices.append(offset+k)
	_mesh(vertices,uvs,indices,colors,2,"CutFaces")
