extends SceneTree

func _initialize() -> void:
	var world = load("res://scripts/world/dungeon_world.gd").new()
	for part in ["frame", "leaf"]:
		var source: Node3D = load("res://assets/models/doors/door_gothic_%s_v1.glb" % part).instantiate()
		var bounds: AABB = world._model_aabb(source)
		var scale_factor := (1.08 if part == "frame" else 0.91597285) / bounds.size.y
		var fit := Transform3D(Basis.from_scale(Vector3.ONE * scale_factor), -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor)
		var mesh := ArrayMesh.new()
		_collect(source, Transform3D.IDENTITY, fit, mesh)
		if part == "frame":
			var surfaces = preload("res://scripts/world/mobile_surfaces.gd")
			var material: Material = surfaces.wall(1, 0).surface_get_material(0)
			var stone := ArrayMesh.new()
			for surface in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(surface)
				var colors := PackedColorArray()
				colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
				colors.fill(surfaces.MASONRY_BODY)
				arrays[Mesh.ARRAY_COLOR] = colors
				stone.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				stone.surface_set_material(surface, material)
			mesh = stone
		assert(ResourceSaver.save(mesh, "res://assets/mobile/gothic-door-%s.res" % part) == OK)
		print(part, " baked bounds=", mesh.get_aabb())
		source.free()
	world.free()
	quit()

func _collect(node: Node3D, parent: Transform3D, fit: Transform3D, output: ArrayMesh) -> void:
	var transform := parent * node.transform
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			builder.append_from(node.mesh, surface, fit * transform)
			var source: StandardMaterial3D = node.mesh.surface_get_material(surface)
			var material := StandardMaterial3D.new()
			material.albedo_texture = source.albedo_texture
			material.roughness = 0.95
			builder.set_material(material)
			builder.commit(output)
	for child in node.get_children():
		if child is Node3D:
			_collect(child, transform, fit, output)
