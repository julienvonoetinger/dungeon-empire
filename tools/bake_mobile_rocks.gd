extends SceneTree

const NAMES := ["rock_formation_reference_v1", "rock_crag_high_v1", "rock_shelf_low_v1", "rock_compact_mid_v1", "rock_split_mid_v1", "rock_broken_low_v1"]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/mobile/rocks")
	for i in NAMES.size():
		var scene: Node3D = load("res://assets/models/walls/%s.glb" % NAMES[i]).instantiate()
		var parts: Array = []
		_collect(scene, Transform3D.IDENTITY, parts)
		var bounds: AABB = parts[0].transform * parts[0].mesh.get_aabb()
		for part in parts:
			bounds = bounds.merge(part.transform * part.mesh.get_aabb())
		var width := maxf(bounds.size.x, bounds.size.z)
		var basis := Basis.from_scale(Vector3(1.0 / width, 1.0 / bounds.size.y, 1.0 / width))
		var fit := Transform3D(basis, basis * Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z))
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in parts:
			for surface in part.mesh.get_surface_count():
				builder.append_from(part.mesh, surface, fit * part.transform)
		builder.generate_normals()
		var mesh := builder.commit()
		mesh.surface_set_material(0, null)
		assert(ResourceSaver.save(mesh, "res://assets/mobile/rocks/rock_%d.res" % i) == OK)
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(0))
		importer.generate_lods(60, 25, [])
		var arrays := mesh.surface_get_arrays(0)
		var best := 1000000
		for lod in importer.get_surface_lod_count(0):
			var indices := importer.get_surface_lod_indices(0, lod)
			var count := indices.size() / 3
			if count >= 250 and count < best:
				best = count
				arrays[Mesh.ARRAY_INDEX] = indices
		var distant := ArrayMesh.new()
		distant.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		assert(ResourceSaver.save(distant, "res://assets/mobile/rocks/rock_%d_far.res" % i) == OK)
		print(NAMES[i], " distant triangles=", arrays[Mesh.ARRAY_INDEX].size() / 3)
		scene.free()
	quit()

func _collect(node: Node, parent: Transform3D, parts: Array) -> void:
	var transform: Transform3D = parent * node.transform if node is Node3D else parent
	if node is MeshInstance3D:
		parts.append({"mesh": node.mesh, "transform": transform})
	for child in node.get_children():
		_collect(child, transform, parts)
