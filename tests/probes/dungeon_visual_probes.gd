extends RefCounted


static func core_anchor_grid(game: Node) -> Array[Vector2i]:
	var origins: Array[Vector2i] = []
	if game == null or game.dungeon == null or game.dungeon._expand_root == null:
		return origins
	for child in game.dungeon._expand_root.get_children():
		if child is Label3D and child.text == "Core":
			var pos := (child as Label3D).position
			origins.append(Vector2i(roundi(pos.x - 1.0), roundi(pos.z - 1.0)))
	return origins


static func core_anchor_report(game: Node) -> Dictionary:
	var origins := core_anchor_grid(game)
	var overlaps := 0
	for i in origins.size():
		for j in range(i + 1, origins.size()):
			var diff := origins[i] - origins[j]
			if abs(diff.x) < GameTypes.CORE_W and abs(diff.y) < GameTypes.CORE_H:
				overlaps += 1
	return {
		"count": origins.size(),
		"origins": origins,
		"has_origin": origins.has(Vector2i.ZERO),
		"has_far_corner": origins.has(Vector2i(GameTypes.COLS - GameTypes.CORE_W, GameTypes.ROWS - GameTypes.CORE_H)),
		"overlaps": overlaps,
	}


static func dungeon_boundary(game: Node) -> Dictionary:
	var result := {
		"exists": false,
		"rails": 0,
		"min_x": INF,
		"max_x": -INF,
		"min_z": INF,
		"max_z": -INF,
		"y": INF,
		"no_depth_test": true,
	}
	if game == null or game.dungeon == null or game.dungeon._dig_bound == null:
		return result
	var bound: Node3D = game.dungeon._dig_bound
	result["exists"] = true
	result["rails"] = bound.get_child_count()
	for child in bound.get_children():
		if not child is MeshInstance3D:
			continue
		var rail := child as MeshInstance3D
		if rail.mesh == null:
			continue
		var aabb := rail.mesh.get_aabb()
		var rail_min := rail.position + aabb.position
		var rail_max := rail_min + aabb.size
		result["min_x"] = minf(float(result["min_x"]), rail_min.x)
		result["max_x"] = maxf(float(result["max_x"]), rail_max.x)
		result["min_z"] = minf(float(result["min_z"]), rail_min.z)
		result["max_z"] = maxf(float(result["max_z"]), rail_max.z)
		result["y"] = minf(float(result["y"]), rail.position.y)
		var mat := rail.material_override as StandardMaterial3D
		if mat != null:
			result["no_depth_test"] = bool(result["no_depth_test"]) and mat.no_depth_test
	return result


static func first_fill_for_label(root: Node3D, label: String) -> MeshInstance3D:
	if root == null:
		return null
	var previous_fill: MeshInstance3D = null
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh is QuadMesh:
			previous_fill = child
		elif child is Label3D and child.text == label:
			return previous_fill
	return null


static func first_fill(root: Node3D) -> MeshInstance3D:
	if root == null:
		return null
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh is QuadMesh:
			return child
	return null


static func first_dash(root: Node3D) -> MeshInstance3D:
	if root == null:
		return null
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			return child
	return null


static func first_label(root: Node3D) -> Label3D:
	if root == null:
		return null
	for child in root.get_children():
		if child is Label3D:
			return child
	return null


static func first_vault_label(game: Node) -> Label3D:
	if game == null or game.dungeon == null:
		return null
	for p in game.dungeon._cells:
		if int(game.grid[p.y][p.x]) != game.Tile.VAULT:
			continue
		var label := first_label(game.dungeon._cells[p])
		if label != null:
			return label
	return null


static func light_report(root: Node) -> Dictionary:
	var report := {"directional": 0, "omni": 0}
	if root == null:
		return report
	for node in root.find_children("*", "", true, false):
		if node is DirectionalLight3D:
			report["directional"] = int(report["directional"]) + 1
		elif node is OmniLight3D:
			report["omni"] = int(report["omni"]) + 1
	return report


static func child_global_transforms(root: Node) -> Dictionary:
	var result: Dictionary = {}
	if root == null:
		return result
	for child in root.get_children():
		if child is Node3D:
			result[child.get_instance_id()] = (child as Node3D).global_transform
	return result
