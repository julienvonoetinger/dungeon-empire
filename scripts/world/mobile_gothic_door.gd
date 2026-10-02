extends RefCounted

const FRAME := preload("res://assets/mobile/gothic-door-frame.res")
const LEAF := preload("res://assets/mobile/gothic-door-leaf.res")
const SURFACES := preload("res://scripts/world/mobile_surfaces.gd")
static var _joins: ArrayMesh
static var _low_joins: ArrayMesh
static var _rubble: ArrayMesh

static func add_to(parent: Node3D, yaw: float, hp: int, opened: bool) -> void:
	var root := Node3D.new()
	root.name = "MobileDoor"
	root.position = Vector3(0.5, 0.175, 0.5)
	root.rotation.y = yaw
	parent.add_child(root)
	_mesh(root, "GothicFrame", FRAME)
	if _joins == null:
		var builder := SURFACES._builder()
		var low_builder := SURFACES._builder()
		var half_width := FRAME.get_aabb().size.x * 0.5 - 0.01
		var courses := [0.0, 0.16, 0.37, 0.54, 0.76, 0.925]
		for side in [-1, 1]:
			var low := Vector2(half_width if side > 0 else -0.50, -0.14)
			var high := Vector2(0.50 if side > 0 else -half_width, 0.14)
			SURFACES._stone(low_builder, SURFACES._outline(low, high, 0.012), 0.008, 0.23, 0.012, SURFACES.MASONRY_BODY)
			for row in 5:
				SURFACES._stone(builder, SURFACES._outline(low, high, 0.012), courses[row] + 0.008,
					courses[row + 1] - 0.008, 0.012, SURFACES.MASONRY_BODY)
			SURFACES._stone(builder, SURFACES._outline(low, high, 0.016), 0.925, 1.10, 0.02, SURFACES.MASONRY_CAP)
		_joins = SURFACES._finish(builder, false)
		_low_joins = SURFACES._finish(low_builder, false)
	var connections := Node3D.new()
	connections.name = "WallConnections"
	connections.set_meta("mobile_natural_rock", true)
	root.add_child(connections)
	var joins := _mesh(connections, "Masonry", _joins)
	joins.set_meta("full_mesh", _joins)
	joins.set_meta("foundation_mesh", _low_joins)
	joins.position.y = -0.175
	if hp <= 0 and not opened:
		if _rubble == null:
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in 5:
				var board := BoxMesh.new()
				board.size = Vector3(0.045, 0.025, 0.20 + 0.03 * (i % 2))
				builder.append_from(board, 0, Transform3D(Basis(Vector3.UP, i * 0.6), Vector3(-0.12 + i * 0.06, 0.025, (i % 2) * 0.09)))
			var wood := StandardMaterial3D.new()
			wood.albedo_color = Color("30251e")
			wood.roughness = 0.95
			builder.set_material(wood)
			_rubble = builder.commit()
		_mesh(root, "Rubble", _rubble)
		return
	var half := LEAF.get_aabb().size * 0.5
	var hinge := Node3D.new()
	hinge.name = "LeafHinge"
	hinge.position = Vector3(-half.x, 0.008, half.z)
	hinge.rotation.y = -PI / 2 if opened else 0.0
	root.add_child(hinge)
	var leaf := _mesh(hinge, "Leaf", LEAF)
	leaf.position = Vector3(half.x, 0, -half.z)

static func _mesh(parent: Node3D, label: String, mesh: Mesh) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
