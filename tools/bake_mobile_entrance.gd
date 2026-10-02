extends SceneTree

func _initialize() -> void:
	var source: Node3D = load("res://assets/models/walls/entrance_rock_arch_v1.glb").instantiate()
	var parts: Array = []
	_collect(source, Transform3D.IDENTITY, parts)
	var bounds: AABB = parts[0].transform * parts[0].mesh.get_aabb()
	for part in parts:
		bounds = bounds.merge(part.transform * part.mesh.get_aabb())
	var scale := Vector3(1.6, 1.4, 0.85) / bounds.size
	var basis := Basis.from_scale(scale)
	var fit := Transform3D(basis, Vector3(-bounds.get_center().x * scale.x, -bounds.position.y * scale.y, 0.20 - bounds.end.z * scale.z))
	var output := ArrayMesh.new()
	var triangles := 0
	for part in parts:
		for surface in part.mesh.get_surface_count():
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			builder.append_from(part.mesh, surface, fit * part.transform)
			builder.generate_normals()
			var source_material: StandardMaterial3D = part.mesh.surface_get_material(surface)
			var material := ShaderMaterial.new()
			material.shader = load("res://assets/rendering/entrance_stone.gdshader")
			material.set_shader_parameter("artwork", source_material.albedo_texture)
			material.set_shader_parameter("grain", load("res://assets/mobile/masonry-grain-v2.png"))
			builder.set_material(material)
			builder.commit(output)
			var arrays := output.surface_get_arrays(output.get_surface_count() - 1)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
	var fitted := ArrayMesh.new()
	for surface in output.get_surface_count():
		var arrays := output.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		# Recess the outer rock behind the masonry jambs, keeping the throat intact.
		for i in vertices.size():
			var v := vertices[i]
			v.z -= smoothstep(0.48, 0.70, absf(v.x)) * maxf(0.0, v.z + 0.18)
			vertices[i] = v
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var adjusted := ArrayMesh.new()
		adjusted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var builder := SurfaceTool.new()
		builder.create_from(adjusted, 0)
		builder.generate_normals()
		builder.set_material(output.surface_get_material(surface))
		builder.commit(fitted)
	assert(ResourceSaver.save(fitted, "res://assets/mobile/entrance-rock-v1.res") == OK)
	print("Entrance baked: ", triangles, " triangles; bounds=", output.get_aabb())
	source.free()
	quit()

func _collect(node: Node, parent: Transform3D, parts: Array) -> void:
	var transform: Transform3D = parent * node.transform if node is Node3D else parent
	if node is MeshInstance3D:
		parts.append({"mesh": node.mesh, "transform": transform})
	for child in node.get_children():
		_collect(child, transform, parts)
