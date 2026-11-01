extends "res://scripts/game/dungeon_terrain.gd"
## Preview only: one continuous rock mass surrounding the carved dungeon.
const PAINT=preload("res://assets/previews/dig-terrain/bedrock.png")
const PAINT_SHADER=preload("res://shaders/dig_terrain_preview.gdshader")
const Recess=preload("res://scripts/continuous_recess_geometry.gd")
const Cut=preload("res://scripts/excavated_recess_geometry.gd")
var continuous_recess:=true
var sloped_recess:=false

func _make_geometry(cells: Array[Vector2i]) -> Dictionary:
	if not continuous_recess: return super._make_geometry(cells)
	if not sloped_recess: return Cut.build(cells,cut_margin,Geometry.EXTENT)
	return Recess.build(cells,cut_margin,HEIGHT,Geometry.EXTENT)

func _add_surfaces() -> void:
	if not continuous_recess:
		super._add_surfaces(); return
	if not sloped_recess:
		super._add_surfaces(); return
	_mesh(geometry.vertices,geometry.uvs,geometry.indices,geometry.colors,3,"RockTop")

func _add_faces() -> void:
	if not continuous_recess:
		super._add_faces(); return
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var colors:=PackedColorArray()
	for edge: PackedVector2Array in geometry.edges:
		var a:=edge[0]; var b:=edge[1]; var delta:=b-a
		# Outside polygons have the opposite winding from a hole contour.
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
