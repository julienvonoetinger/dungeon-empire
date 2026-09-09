class_name FloorRenderer
extends MeshInstance3D

const FLOOR_TEXTURE := preload("res://production/textures/floor/floor_controlled_seamless.png")
const STONE_RELIEF := preload("res://scripts/world/stone_floor_relief.gd")

var _signature := ""
var _relief: Node3D

func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func sync_cells(open_cells: Array[Vector2i], cell_size: float, inset_cells: Array[Vector2i] = []) -> void:
	var ordered := open_cells.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var signature := "%s|%.4f|%s" % [str(ordered), cell_size, str(inset_cells)]
	if signature == _signature:
		return
	_signature = signature
	if _relief == null:
		_relief = STONE_RELIEF.new()
		_relief.name = "MeshyStoneRelief"
		add_child(_relief)
	# A trap directly replaces this 1x1 relief instance. Its own base surface is
	# aligned to the same height, so no second slab remains visible underneath.
	var relief_cells: Array[Vector2i] = []
	for cell in ordered:
		if not inset_cells.has(cell):
			relief_cells.append(cell)
	_relief.sync_cells(relief_cells, cell_size)
	if ordered.is_empty():
		mesh = null
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for cell in ordered:
		var surface_y := 0.12
		var x0 := float(cell.x) * cell_size
		var z0 := float(cell.y) * cell_size
		var x1 := x0 + cell_size
		var z1 := z0 + cell_size
		var base := vertices.size()
		vertices.append_array(PackedVector3Array([
			Vector3(x0, surface_y, z0), Vector3(x1, surface_y, z0),
			Vector3(x1, surface_y, z1), Vector3(x0, surface_y, z1),
		]))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
		uvs.append_array(PackedVector2Array([
			Vector2(float(cell.x), float(cell.y)), Vector2(float(cell.x + 1), float(cell.y)),
			Vector2(float(cell.x + 1), float(cell.y + 1)), Vector2(float(cell.x), float(cell.y + 1)),
		]))
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var generated := ArrayMesh.new()
	generated.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	generated.surface_set_material(0, _make_material())
	mesh = generated

func surface_count() -> int:
	return 0 if mesh == null else mesh.get_surface_count()

func _make_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = FLOOR_TEXTURE
	material.uv1_scale = Vector3(0.25, 0.25, 1.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.roughness = 0.9
	material.metallic = 0.0
	return material
