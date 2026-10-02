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
	assert(renderer.has_node("MeshyStoneRelief"), "desktop keeps modeled floor relief")
	assert(is_equal_approx(renderer.mesh.get_aabb().position.y, 0.12), "desktop floor keeps its existing height")

	var mobile := FloorRendererScript.new()
	mobile.mobile_mode = true
	root.add_child(mobile)
	mobile.sync_cells(cells, 1.0)
	assert(mobile.surface_count() == 1, "mobile floor batches all cells into one surface")
	assert(mobile.get_node_or_null("MeshyStoneRelief") == null, "mobile floor skips GLB relief instances")
	var mobile_material := mobile.mesh.surface_get_material(0) as BaseMaterial3D
	assert(mobile_material != null and mobile_material.albedo_texture != null, "mobile floor uses a textured material")
	assert(is_equal_approx(mobile.mesh.get_aabb().position.y, 0.175), "mobile floor sits at y=0.175")
	assert(is_equal_approx(mobile.mesh.get_aabb().end.y, 0.175), "mobile floor is flat")
	assert(mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == cells.size() * 4, "mobile cells share one batched mesh")
	var first_mobile_mesh: ArrayMesh = mobile.mesh
	mobile.sync_cells(cells, 1.0)
	assert(mobile.mesh == first_mobile_mesh, "identical mobile floor sync reuses its mesh")
	print("OK: continuous floor renderer")
	quit()
