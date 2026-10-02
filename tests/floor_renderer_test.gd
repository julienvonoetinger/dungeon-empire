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
	var mobile_material := mobile.mesh.surface_get_material(0) as ShaderMaterial
	assert(mobile_material != null, "mobile paving has shallow shader relief without extra geometry")
	var treasury_texture: Texture2D = mobile_material.get_shader_parameter("treasury_stone")
	assert(treasury_texture != null and treasury_texture.resource_path.ends_with("treasury-floor-v1.png"), "treasury uses dedicated coin and stone artwork")
	var stone: Texture2D = mobile_material.get_shader_parameter("stone")
	assert(stone != null and stone.resource_path.ends_with("floor-pavers-v4.png"), "mobile uses the approved finer gray paving")
	assert(mobile_material.get_shader_parameter("bump_strength") > 0.0, "paving relief responds to light")
	assert(is_equal_approx(mobile.mesh.get_aabb().position.y, 0.175), "mobile floor sits at y=0.175")
	assert(is_equal_approx(mobile.mesh.get_aabb().end.y, 0.175), "mobile floor is flat")
	assert(mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == cells.size() * 4, "mobile cells share one batched mesh")
	var first_mobile_mesh: ArrayMesh = mobile.mesh
	mobile.sync_cells(cells, 1.0)
	assert(mobile.mesh == first_mobile_mesh, "identical mobile floor sync reuses its mesh")
	assert(mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2] != null, "mobile paving carries exposed-edge masks")
	var edges: PackedVector2Array = mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
	assert(edges.size() == 16, "mobile paving carries exposed-edge masks")
	assert(edges[0].x == 5 and edges[4].x == 6 and edges[8].x == 9 and edges[12].x == 10,
		"only outer boundaries get dust; shared floor edges stay continuous")
	var expanded: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)]
	mobile.sync_cells(expanded, 1.0)
	edges = mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
	assert(edges[4].x == 4, "digging removes dust from the newly connected edge")
	var treasury: Array[Vector2i] = [Vector2i(1, 0)]
	var no_insets: Array[Vector2i] = []
	mobile.sync_cells(cells, 1.0, no_insets, treasury)
	var treasury_arrays := mobile.mesh.surface_get_arrays(0)
	assert(treasury_arrays[Mesh.ARRAY_VERTEX].size() == 16, "treasury replaces the tile without overlay geometry")
	var tags: PackedVector2Array = treasury_arrays[Mesh.ARRAY_TEX_UV2]
	assert(tags[4].y == 1.0 and tags[0].y == 0.0, "only treasury cell uses inset stone tile")
	mobile.sync_cells(cells, 1.0, no_insets, treasury, treasury)
	assert(mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][4].y == 2.0, "empty vault selects coin-free paving")
	mobile.sync_cells(cells, 1.0, no_insets, treasury)
	assert(mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][4].y == 1.0, "refilling restores coins")
	for vertex in treasury_arrays[Mesh.ARRAY_VERTEX]:
		assert(is_equal_approx(vertex.y, 0.175), "treasury stays flush with adjoining paving")
	mobile.sync_cells(cells, 1.0)
	assert(mobile.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][4].y == 0.0, "removing treasury restores ordinary paving")
	print("OK: continuous floor renderer")
	quit()
