extends SceneTree

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/world/mobile_entrance.gd"):
		push_error("Missing wall-mounted mobile entrance")
		quit(1)
		return
	var script = load("res://scripts/world/mobile_entrance.gd")
	for face in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var holder := Node3D.new()
		script.add_to(holder, face)
		var arch := holder.get_node("MobileEntrance/EntranceArch") as MeshInstance3D
		assert(arch != null and arch.mesh != null)
		assert(arch.get_aabb().size.z >= 0.4, "Masonry arch has tunnel depth")
		assert(holder.find_children("*", "Sprite3D", true, false).is_empty())
		assert(holder.get_node("MobileEntrance").position.is_equal_approx(Vector3(0.5, 0.175, 0.5) - face * 0.44))
		assert(holder.get_node("MobileEntrance").basis.z.is_equal_approx(face))
		var entrance: Node3D = holder.get_node("MobileEntrance")
		assert(entrance.get_node_or_null("Steps") == null, "No duplicate stairs on the Meshy steps")
		assert(arch.mesh.resource_path == "res://assets/mobile/entrance-rock-v1.res")
		var joins := entrance.get_node("WallJoins").get_children()
		assert(joins.size() == 2)
		for join in joins:
			assert(join.has_meta("full_mesh") and join.has_meta("foundation_mesh"))
			var bounds: AABB = join.transform * join.get_aabb()
			assert(bounds.end.x <= -0.33 or bounds.position.x >= 0.33, "Masonry joins leave the passage clear")
		assert(entrance.get_node("Torches").get_child_count() == 2)
		var torches := entrance.get_node("Torches").get_children()
		var rig = load("res://scripts/world/wall_torch_rig.gd")
		for torch in torches:
			var bounds: AABB = rig._bounds(torch, Transform3D.IDENTITY)
			assert(bounds.size.y <= 0.36, "Entrance torches must be proportionate to the doorway")
			assert(bounds.position.x >= -0.49 and bounds.end.x <= 0.49, "Torch sides stay inside the corridor wall planes")
			for join in joins:
				var stone: AABB = join.transform * join.get_aabb()
				assert(not bounds.intersects(stone), "Torch geometry must not intersect masonry connectors")
		assert(torches[0].get_child_count() == 1 and torches[1].get_child_count() == 1)
		assert(torches[0].get_child(0) != torches[1].get_child(0), "Torch models are distinct instances")
		assert(entrance.find_children("*", "OmniLight3D", true, false).is_empty(), "Entrance adds no unbudgeted lights")
		assert(holder.find_children("*", "MeshInstance3D", true, false).size() >= 5)
		holder.free()
	var first := Node3D.new()
	var second := Node3D.new()
	script.add_to(first, Vector3.RIGHT)
	script.add_to(second, Vector3.FORWARD)
	assert(first.get_node("MobileEntrance/EntranceArch").mesh == second.get_node("MobileEntrance/EntranceArch").mesh,
		"Arch geometry is cached across entrances")
	first.free()
	second.free()
	print("OK: volumetric wall entrance, tunnel, steps and budgeted torch visuals")
	quit()
