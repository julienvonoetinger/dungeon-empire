extends SceneTree

func _initialize() -> void:
	var entrance_script = load("res://scripts/world/mobile_entrance.gd")
	assert(entrance_script != null, "mobile entrance renderer exists")
	var root_node := Node3D.new()
	root.add_child(root_node)
	entrance_script.add_to(root_node, Vector3.RIGHT)
	var arch := root_node.get_node_or_null("MobileEntrance/EntranceArch") as MeshInstance3D
	assert(arch != null, "Entrance must have a volumetric masonry arch, not a sprite")
	assert(arch.get_aabb().size.z >= 0.4, "Arch has real tunnel depth")
	assert(root_node.find_children("*", "Sprite3D", true, false).is_empty(), "No baked torch or frontal arch image remains")
	var entrance := root_node.get_node("MobileEntrance")
	assert(entrance.get_node("Torches").get_child_count() == 2, "Entrance uses two separate wall torch models")
	assert(entrance.get_node("Steps").get_child_count() == 4, "Passage contains real steps")
	assert(entrance.find_children("*", "OmniLight3D", true, false).is_empty(), "Entrance reuses budgeted world illumination")
	var other := Node3D.new()
	root.add_child(other)
	entrance_script.add_to(other, Vector3.FORWARD)
	assert(other.get_node("MobileEntrance/EntranceArch").mesh == arch.mesh, "Arch geometry is cached across rebuilds")
	other.free()
	root_node.free()
	print("OK: mobile wall-backed entrance renderer")
	quit()
