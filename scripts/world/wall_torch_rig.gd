extends Node3D

const TORCH := preload("res://assets/models/walls/wall_torch_emberstone.glb")
const PROFILE := preload("res://assets/rendering/dungeon_render_profile.tres")
const SPACING := 2.6
var _fixtures: Dictionary = {}

func sync_cells(cells: Array[Vector2i], target: Vector3, cell_size: float) -> void:
	var occupied: Dictionary = {}
	for cell in cells:
		occupied[cell] = true
	var candidates: Array[Dictionary] = []
	for cell in cells:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if occupied.has(cell + direction):
				continue
			var inward := Vector3(-direction.x, 0, -direction.y)
			var point := Vector3(cell.x + 0.5, 0, cell.y + 0.5) * cell_size - inward * cell_size * 0.48
			var key := "%d,%d:%d,%d" % [cell.x, cell.y, direction.x, direction.y]
			candidates.append({"key": key, "point": point, "inward": inward, "distance": point.distance_squared_to(target)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if is_equal_approx(a.distance, b.distance):
			return a.key < b.key
		return a.distance < b.distance)
	var selected: Dictionary = {}
	for candidate in candidates:
		if selected.size() >= PROFILE.max_practical_lights:
			break
		var separated := true
		for previous in selected.values():
			if candidate.point.distance_to(previous.point) < SPACING * cell_size:
				separated = false
				break
		if separated:
			selected[candidate.key] = candidate
	for key in _fixtures.keys():
		if not selected.has(key):
			var fixture: Node3D = _fixtures[key]
			remove_child(fixture)
			fixture.queue_free()
			_fixtures.erase(key)
	for key in selected:
		if not _fixtures.has(key):
			_fixtures[key] = _make_fixture(selected[key])

func _make_fixture(candidate: Dictionary) -> Node3D:
	var fixture := Node3D.new()
	fixture.position = candidate.point
	fixture.rotation.y = atan2(candidate.inward.x, candidate.inward.z)
	add_child(fixture)
	var visual := TORCH.instantiate() as Node3D
	fixture.add_child(visual)
	var measured := _bounds(visual, Transform3D.IDENTITY)
	if measured.size.y > 0.001:
		var scalar := 0.65 / measured.size.y
		# Measure once before scaling; preserve the imported model's proportions.
		visual.scale *= scalar
		visual.position = Vector3(-measured.get_center().x, -measured.position.y, -measured.get_center().z) * scalar
		visual.position += Vector3(0, 0.18, 0.04)
	var light := OmniLight3D.new()
	PROFILE.configure_practical(light)
	light.position = Vector3(0, 0.85, 0.42)
	fixture.add_child(light)
	return fixture

func _bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	var result := AABB()
	var found := false
	if node is MeshInstance3D and node.mesh != null:
		result = transform * node.get_aabb()
		found = true
	for child in node.get_children():
		var child_bounds := _bounds(child, transform)
		if child_bounds.size != Vector3.ZERO:
			result = result.merge(child_bounds) if found else child_bounds
			found = true
	return result
