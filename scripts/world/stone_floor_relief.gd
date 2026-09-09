extends Node3D
## Instance one Meshy floor module per logical cell. Stable quarter-turns provide
## variation while every floor and trap keeps the same 1x1 footprint.

const SOURCE := "res://assets/models/environment/floor_tile_trap_match_1x1.glb"
var _batch: MultiMeshInstance3D
var _signature := ""

func sync_cells(cells: Array[Vector2i], cell_size: float) -> void:
	if _batch == null:
		_build_tile()
	if _batch == null:
		return
	var ordered := cells.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var signature := "%s|%.4f" % [str(ordered), cell_size]
	if signature == _signature:
		return
	_signature = signature
	var mm := _batch.multimesh
	mm.instance_count = ordered.size()
	for index in ordered.size():
		var cell: Vector2i = ordered[index]
		var angle := float(orientation_for(cell)) * PI * 0.5
		var basis := Basis(Vector3.UP, angle).scaled(Vector3(cell_size, 1.0, cell_size))
		var center := Vector3((float(cell.x) + 0.5) * cell_size, 0.0, (float(cell.y) + 0.5) * cell_size)
		mm.set_instance_transform(index, Transform3D(basis, center - basis * Vector3(0.5, 0.0, 0.5)))

static func orientation_for(cell: Vector2i) -> int:
	return posmod(cell.x * 3 + cell.y * 5 + cell.x * cell.y, 4)

func _build_tile() -> void:
	if not ResourceLoader.exists(SOURCE):
		return
	var model := (load(SOURCE) as PackedScene).instantiate()
	var surfaces: Array = []
	_collect(model, Transform3D.IDENTITY, surfaces)
	model.free()
	if surfaces.is_empty():
		return
	var bounds := AABB(surfaces[0].vertices[0].p, Vector3.ZERO)
	for surface in surfaces:
		for vertex in surface.vertices:
			bounds = bounds.expand(vertex.p)
	var horizontal := maxf(bounds.size.x, bounds.size.z)
	var scale := Vector3(1.0 / horizontal, 0.14 / maxf(bounds.size.y, 0.001), 1.0 / horizontal)
	var offset := Vector3(0.5 - bounds.get_center().x * scale.x,
		0.035 - bounds.position.y * scale.y,
		0.5 - bounds.get_center().z * scale.z)
	var mesh := ArrayMesh.new()
	for surface in surfaces:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(surface.material)
		for vertex in surface.vertices:
			builder.set_normal((vertex.n / scale).normalized())
			builder.set_uv(vertex.uv)
			builder.add_vertex(vertex.p * scale + offset)
		builder.generate_tangents()
		builder.index()
		builder.commit(mesh)
	_batch = MultiMeshInstance3D.new()
	_batch.name = "FloorTile1x1"
	_batch.multimesh = MultiMesh.new()
	_batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_batch.multimesh.mesh = mesh
	add_child(_batch)

func _collect(node: Node, parent_transform: Transform3D, surfaces: Array) -> void:
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: Array = []
			var normal_basis := transform.basis.inverse().transposed()
			var count := positions.size() if indices.is_empty() else indices.size()
			for index in count:
				var source_index := index if indices.is_empty() else indices[index]
				vertices.append({"p": transform * positions[source_index],
					"n": (normal_basis * normals[source_index]).normalized(), "uv": uvs[source_index]})
			var material := node.get_active_material(surface).duplicate() as BaseMaterial3D
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			material.metallic = 0.0
			material.roughness = 0.93
			surfaces.append({"vertices": vertices, "material": material})
	for child in node.get_children():
		_collect(child, transform, surfaces)
