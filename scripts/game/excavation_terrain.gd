extends "res://scripts/game/dungeon_terrain.gd"
## Shared production terrain: level excavated ground inside a full-height cut.
const PAINT=preload("res://assets/previews/dig-terrain/bedrock.png")
const PAINT_SHADER=preload("res://shaders/dig_terrain_preview.gdshader")
const Cut=preload("res://scripts/excavated_recess_geometry.gd")
const EDGE_GAP:=.04

func _init() -> void:
	cut_margin=1.35

func _make_geometry(cells: Array[Vector2i]) -> Dictionary:
	var setback:=Vector2.ONE*(-project(Vector2.ZERO,HEIGHT).y/project(Vector2.ONE).y)
	return Cut.build(cells,cut_margin+EDGE_GAP,Geometry.EXTENT,setback)

func _add_faces() -> void:
	# Historical review profiles can still provide the older contour data.
	if not geometry.has("edges"):
		super._add_faces(); return
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var colors:=PackedColorArray()
	for edge: PackedVector2Array in geometry.edges:
		var a:=edge[0]; var b:=edge[1]; var delta:=b-a
		if delta.x-delta.y>=-.000001: continue
		var offset:=vertices.size()
		vertices.append_array([project(a),project(b),project(b,HEIGHT),project(a,HEIGHT)])
		uvs.append_array([Vector2(a.x-a.y,0),Vector2(b.x-b.y,0),Vector2(b.x-b.y,-HEIGHT*2),Vector2(a.x-a.y,-HEIGHT*2)])
		colors.append_array([Color(1,1,1,0),Color(1,1,1,0),Color.WHITE,Color.WHITE])
		for k in [0,1,2,0,2,3]: indices.append(offset+k)
	_mesh(vertices,uvs,indices,colors,4,"CutFaces")

func _material(surface: int) -> ShaderMaterial:
	var result:=ShaderMaterial.new()
	result.shader=PAINT_SHADER
	result.set_shader_parameter("surface",surface)
	result.set_shader_parameter("bedrock",PAINT)
	result.set_shader_parameter("quiet",preload("res://assets/dungeon/bedrock/quiet.png"))
	return result
