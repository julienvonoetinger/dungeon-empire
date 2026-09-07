class_name ModelFit
extends RefCounted

static var _last_error := ""

static func uniform_scale(bounds: AABB, target_footprint: float) -> float:
	_last_error = ""
	var span := maxf(bounds.size.x, bounds.size.z)
	if span <= 0.0001:
		_last_error = "model has no measurable horizontal geometry"
		return 1.0
	if target_footprint <= 0.0001:
		_last_error = "target footprint must be positive"
		return 1.0
	return target_footprint / span

static func last_validation_error() -> String:
	return _last_error

static func bounds(instance: Node) -> AABB:
	return _bounds_xf(instance, Transform3D.IDENTITY)

static func place_on_floor(instance: Node3D, floor_y: float) -> void:
	var measured := bounds(instance)
	if measured.size == Vector3.ZERO:
		_last_error = "cannot place model without geometry"
		return
	instance.position.y += floor_y - measured.position.y

static func center_xz(instance: Node3D) -> void:
	var measured := bounds(instance)
	if measured.size == Vector3.ZERO:
		_last_error = "cannot center model without geometry"
		return
	instance.position.x -= measured.get_center().x
	instance.position.z -= measured.get_center().z

static func fit_footprint(instance: Node3D, target_footprint: float, floor_y: float = 0.0) -> float:
	var scalar := uniform_scale(bounds(instance), target_footprint)
	instance.scale = Vector3.ONE * scalar
	center_xz(instance)
	place_on_floor(instance, floor_y)
	return scalar

static func _bounds_xf(node: Node, parent_xf: Transform3D) -> AABB:
	var local_xf := parent_xf
	if node is Node3D:
		local_xf = parent_xf * (node as Node3D).transform
	var result := AABB()
	var has_geometry := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		result = (node as MeshInstance3D).get_aabb() * local_xf
		has_geometry = true
	for child in node.get_children():
		var child_bounds := _bounds_xf(child, local_xf)
		if child_bounds.size == Vector3.ZERO:
			continue
		result = result.merge(child_bounds) if has_geometry else child_bounds
		has_geometry = true
	return result if has_geometry else AABB()
