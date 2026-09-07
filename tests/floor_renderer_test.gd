extends SceneTree

const FloorRendererScript := preload("res://scripts/world/floor_renderer.gd")

func _initialize() -> void:
	var renderer: MeshInstance3D = FloorRendererScript.new()
	root.add_child(renderer)
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	renderer.sync_cells(cells, 1.0)
	assert(renderer.surface_count() == 1, "adjacent cells must share one floor surface")
	assert(renderer.find_children("*", "OmniLight3D", true, false).is_empty(), "floor renderer must not create lights")
	var material := renderer.mesh.surface_get_material(0) as BaseMaterial3D
	assert(material != null and material.albedo_texture != null, "floor surface must use the seamless floor texture")
	assert(material.get_flag(BaseMaterial3D.FLAG_USE_TEXTURE_REPEAT), "world-space floor UVs require texture repeat")
	var arrays := renderer.mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert(indices.slice(0, 6) == PackedInt32Array([0, 1, 2, 0, 2, 3]), "floor triangles must face the overhead camera")
	var first_mesh: ArrayMesh = renderer.mesh
	renderer.sync_cells(cells, 1.0)
	assert(renderer.mesh == first_mesh, "identical floor sync must reuse its mesh")
	print("OK: continuous floor renderer")
	quit()
