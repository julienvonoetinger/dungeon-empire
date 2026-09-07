class_name FloorRenderer
extends MeshInstance3D

const FLOOR_TEXTURE := preload("res://production/textures/floor/floor_controlled_seamless.png")

var _signature := ""

func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func sync_cells(open_cells: Array[Vector2i], cell_size: float) -> void:
	var ordered := open_cells.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var signature := "%s|%.4f" % [str(ordered), cell_size]
	if signature == _signature:
		return
	_signature = signature
	if ordered.is_empty():
		mesh = null
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for cell in ordered:
		var x0 := float(cell.x) * cell_size
		var z0 := float(cell.y) * cell_size
		var x1 := x0 + cell_size
		var z1 := z0 + cell_size
		var base := vertices.size()
		vertices.append_array(PackedVector3Array([
			Vector3(x0, 0.12, z0), Vector3(x1, 0.12, z0),
			Vector3(x1, 0.12, z1), Vector3(x0, 0.12, z1),
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
