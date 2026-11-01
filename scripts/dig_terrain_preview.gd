extends "res://scripts/game/excavation_terrain.gd"
## Active preview shares production; only historical regression profiles differ.
const Recess=preload("res://scripts/continuous_recess_geometry.gd")
var continuous_recess:=true
var sloped_recess:=false

func _make_geometry(cells: Array[Vector2i]) -> Dictionary:
	if not continuous_recess: return Geometry.build(cells,cut_margin)
	if sloped_recess: return Recess.build(cells,cut_margin,HEIGHT,Geometry.EXTENT)
	return super._make_geometry(cells)

func _add_surfaces() -> void:
	if continuous_recess and sloped_recess:
		_mesh(geometry.vertices,geometry.uvs,geometry.indices,geometry.colors,3,"RockTop")
	else:
		super._add_surfaces()
