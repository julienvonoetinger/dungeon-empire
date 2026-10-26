extends MeshInstance2D
## Continue only the rock material beneath transparent HUD gaps. The playable
## dungeon remains in its separate viewport; no rooms or controls overlap it.
const Terrain = preload("res://scripts/game/dungeon_terrain.gd")
var hud: CanvasLayer
var area := Rect2()
var _mapping := Transform2D()
var _previous_area := Rect2()
var _initialized := false

func _ready() -> void:
	material=hud.session.get_node("PlayArea/World/Terrain")._material(0)

func _process(_delta: float) -> void:
	if not area.has_area(): return
	var world: SubViewport=hud.session.get_node("PlayArea/World")
	var play: Control=hud.session.get_node("PlayArea")
	var screen_to_world := world.canvas_transform.affine_inverse()
	var mapping := screen_to_world*Transform2D(0,hud.scale,0,-play.position)
	if _initialized and mapping.is_equal_approx(_mapping) and area.is_equal_approx(_previous_area): return
	_mapping=mapping; _previous_area=area; _initialized=true
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	for p in [area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]:
		vertices.append(Vector3(p.x,p.y,0))
		var projected: Vector2=mapping*p
		var y := (projected.y+Terrain.HEIGHT*156.767343538)/128.0
		uvs.append(Vector2(y+projected.x/256.0,y-projected.x/256.0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
	var quad := ArrayMesh.new()
	quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh=quad
