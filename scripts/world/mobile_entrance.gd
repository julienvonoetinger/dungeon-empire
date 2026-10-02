extends RefCounted

const TORCH_RIG := preload("res://scripts/world/wall_torch_rig.gd")
const ARCH := preload("res://assets/mobile/entrance-rock-v1.res")
const SURFACES := preload("res://scripts/world/mobile_surfaces.gd")
static var _join: ArrayMesh
static var _join_foundation: ArrayMesh

static func add_to(parent: Node3D, face: Vector3) -> void:
	var root := Node3D.new()
	root.name = "MobileEntrance"
	root.position = Vector3(0.5, 0.175, 0.5) - face * 0.44
	root.rotation.y = atan2(face.x, face.z)
	parent.add_child(root)
	var arch := MeshInstance3D.new()
	arch.name = "EntranceArch"
	arch.mesh = ARCH
	arch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(arch)
	var joins := Node3D.new()
	joins.name = "WallJoins"
	root.add_child(joins)
	if _join == null:
		_join = SURFACES.pillar()
		_join_foundation = SURFACES.pillar(true)
	for side in [-1, 1]:
		var join := MeshInstance3D.new()
		join.mesh = _join
		join.set_meta("full_mesh", _join)
		join.set_meta("foundation_mesh", _join_foundation)
		join.position = Vector3(side * 0.52, -0.175, -0.02)
		join.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		joins.add_child(join)
	var torches := Node3D.new()
	torches.name = "Torches"
	root.add_child(torches)
	for side in [-1, 1]:
		var mount := Node3D.new()
		mount.position = Vector3(side * 0.37, 0.40, 0.20)
		torches.add_child(mount)
		var visual := TORCH_RIG.create_visual()
		visual.scale *= 0.5
		# Anchor the small backplate on the arch face, independently of wall cutaway.
		var bounds := TORCH_RIG._bounds(visual, Transform3D.IDENTITY)
		visual.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.position.z)
		mount.add_child(visual)
