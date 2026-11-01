extends "res://scripts/game/dungeon_terrain.gd"
## Preview only: one continuous rock mass surrounding the carved dungeon.
const PAINT=preload("res://assets/previews/dig-terrain/bedrock.png")
const PAINT_SHADER=preload("res://shaders/dig_terrain_preview.gdshader")
const Recess=preload("res://scripts/continuous_recess_geometry.gd")
var continuous_recess:=true

func _make_geometry(cells: Array[Vector2i]) -> Dictionary:
	if not continuous_recess: return super._make_geometry(cells)
	return Recess.build(cells,cut_margin,HEIGHT,Geometry.EXTENT)

func _add_surfaces() -> void:
	if not continuous_recess:
		super._add_surfaces(); return
	_mesh(geometry.vertices,geometry.uvs,geometry.indices,geometry.colors,3,"RockTop")

func _material(surface: int) -> ShaderMaterial:
	var result:=ShaderMaterial.new()
	result.shader=PAINT_SHADER
	result.set_shader_parameter("surface",surface)
	result.set_shader_parameter("bedrock",PAINT)
	result.set_shader_parameter("quiet",preload("res://assets/dungeon/bedrock/quiet.png"))
	return result
