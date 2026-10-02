extends SceneTree

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/world/mobile_surfaces.gd"):
		push_error("Integrated mobile surfaces missing")
		quit(1)
		return
	var surfaces = load("res://scripts/world/mobile_surfaces.gd")
	var geology = load("res://scripts/world/mobile_geology.gd")
	var detail_points := 0
	for piece in geology.patch(Vector2i(2, 2)).pieces:
		detail_points += piece.outline.size()
	assert(detail_points > 24, "rock masses have chipped contours rather than straight polygon plates")
	for tile in [GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE, GameTypes.Tile.VOID]:
		var root := Node3D.new()
		surfaces.trap(root, tile, false)
		assert(root.get_child_count() == 0 if tile == GameTypes.Tile.SNARE else root.get_child_count() > 0)
		if tile == GameTypes.Tile.VOID:
			assert(root.get_node("VoidFloor").billboard == BaseMaterial3D.BILLBOARD_DISABLED)
		for node in root.find_children("*", "MeshInstance3D", true, false):
			var bounds: AABB = node.transform * node.get_aabb()
			assert(bounds.position.x >= 0 and bounds.end.x <= 1)
			assert(bounds.position.z >= 0 and bounds.end.z <= 1)
			assert(bounds.position.y >= 0.12 and bounds.end.y < 0.65)
		root.free()
	var a: ArrayMesh = surfaces.rock(Vector2i(2, 2), Vector2.ZERO, Vector2.ONE)
	var b: ArrayMesh = surfaces.rock(Vector2i(3, 2), Vector2.ZERO, Vector2.ONE)
	var va: PackedVector3Array = a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var vb: PackedVector3Array = b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(a.get_aabb().end.y < 1.0, "bedrock stays below masonry")
	assert(a.get_aabb().position.x >= -0.00001 and a.get_aabb().end.x <= 1.00001, "rock bounds may meet exact cell edges")
	assert(va != vb, "neighboring rock silhouettes vary")
	var left_edge := _top_edge_points(a, 1.0)
	var right_edge := _top_edge_points(b, 0.0)
	var shared_top_points := 0
	for left_point in left_edge:
		for right_point in right_edge:
			if left_point.distance_to(right_point) <= 0.0001:
				shared_top_points += 1
	assert(shared_top_points > 0, "adjacent rock cells share deterministic positive-height points along their common top edge")
	assert(a.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size() == va.size())
	assert(surfaces.has_method("wall"), "mobile masonry mesh exists")
	var wall: ArrayMesh = surfaces.wall(2, 17)
	assert(wall.get_aabb().size.x <= 2.00001 and wall.get_aabb().size.z <= 0.28001, "masonry stays inside its footprint (float32 tolerance)")
	assert(wall.get_aabb().end.y > 1.0, "masonry rises above bedrock")
	assert(wall.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > 200, "wall has modeled individual stones")
	for x in 8:
		for y in 8:
			var cell := Vector2i(x, y)
			var rock: ArrayMesh = surfaces.rock(cell, Vector2(0.3, 0.3), Vector2(0.7, 0.7))
			var bounds := rock.get_aabb()
			assert(bounds.position.x >= 0.29999 and bounds.end.x <= 0.70001)
			assert(bounds.position.z >= 0.29999 and bounds.end.z <= 0.70001)
			assert(bounds.end.y < 1.0)
			assert(rock.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == surfaces.rock(cell, Vector2(0.3, 0.3), Vector2(0.7, 0.7)).surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "dig rebuilds retain deterministic silhouettes")
	assert(surfaces.pillar().get_aabb().end.y > wall.get_aabb().end.y)
	for masonry in [wall, surfaces.pillar()]:
		for color in masonry.surface_get_arrays(0)[Mesh.ARRAY_COLOR]:
			assert(maxf(color.r, maxf(color.g, color.b)) <= 0.60, "masonry and coping avoid pale vertex tints")
	print("OK: floor traps, fragmented bedrock and modeled masonry")
	quit()

func _top_edge_points(mesh: ArrayMesh, edge_x: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex in vertices:
		if is_equal_approx(vertex.x, edge_x) and vertex.y > 0.0:
			var point := Vector2(vertex.z, vertex.y)
			if not points.any(func(existing: Vector2): return existing.distance_to(point) <= 0.0001):
				points.append(point)
	return points
