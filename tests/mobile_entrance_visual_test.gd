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
		assert(entrance.get_node("Steps").get_child_count() == 4)
		assert(entrance.get_node("Torches").get_child_count() == 2)
		var torches := entrance.get_node("Torches").get_children()
		assert(torches[0].get_child_count() == 1 and torches[1].get_child_count() == 1)
		assert(torches[0].get_child(0) != torches[1].get_child(0), "Torch models are distinct instances")
		assert(entrance.find_children("*", "OmniLight3D", true, false).is_empty(), "Entrance adds no unbudgeted lights")
		assert(holder.find_children("*", "MeshInstance3D", true, false).size() >= 7)
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
