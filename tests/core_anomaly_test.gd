extends SceneTree

func _initialize() -> void:
	var script = load("res://scripts/world/core_anomaly.gd")
	if script == null:
		printerr("FAIL: separated core anomaly is missing")
		quit(1)
		return
	var core = script.new()
	root.add_child(core)
	core.set_health(100)
	var void_mesh: MeshInstance3D = core.get_node("Void")
	var halo: MeshInstance3D = core.get_node("Halo")
	var stones: Node3D = core.get_node("Fragments")
	assert(void_mesh.visible and halo.visible)
	assert(core.get_node_or_null("ConvergingVeins") == null,
		"the core must not project straight emissive strips onto surrounding floor tiles")
	var pedestal_bounds := _bounds(core.get_node("Pedestal"), Transform3D.IDENTITY)
	assert(absf(pedestal_bounds.position.y - 0.175) < 0.006,
		"the core pedestal must rest on the finished floor instead of being buried")
	var ids: Array[int] = []
	for stone in stones.get_children():
		ids.append(stone.get_instance_id())
	assert(ids.size() >= 5, "anomaly requires distinct floating fragments")
	var initial: Vector3 = stones.get_child(0).position
	core.advance(1.0)
	assert(stones.get_child(0).position.distance_to(initial) > 0.001, "fragments must drift")
	core.set_health(15)
	assert(void_mesh.visible, "critical core retains the same void identity")
	for index in ids.size():
		assert(stones.get_child(index).get_instance_id() == ids[index], "damage must preserve the fragment family")
	core.set_health(0)
	assert(not void_mesh.visible and not halo.visible, "destroyed core cannot keep a living anomaly")
	assert(core.light_strength() == 0.0, "destroyed core must stop casting violet light")
	var fallen: Vector3 = stones.get_child(0).position
	core.advance(2.0)
	assert(stones.get_child(0).position == fallen, "destroyed fragments must remain settled")
	core.set_health(100)
	assert(void_mesh.visible and halo.visible, "reset restores the living anomaly")
	assert(core.light_strength() > 0.0)
	core.free()
	print("OK: core animation, persistent identity, destruction and reset")
	quit()

func _bounds(node: Node, parent: Transform3D) -> AABB:
	var transform := parent
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
	return result if found else AABB()
