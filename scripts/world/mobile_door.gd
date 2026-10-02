extends RefCounted

const SURFACES := preload("res://scripts/world/mobile_surfaces.gd")
const SHADER := preload("res://assets/rendering/door_leaves.gdshader")
const WOOD := preload("res://assets/mobile/door-leaves-v3.png")
const SEALED := preload("res://assets/mobile/door-sealed-v3.png")
const DAMAGED := preload("res://assets/mobile/door-damaged-v3.png")
const SEALED_DAMAGED := preload("res://assets/mobile/door-sealed-damaged-v3.png")
static var _frame: ArrayMesh
static var _leaf_materials: Dictionary = {}
static var _wood_edge: StandardMaterial3D

static func add_to(parent: Node3D, yaw: float, magic: bool, hp: int, max_hp: int, opened: bool) -> void:
	var root := Node3D.new()
	root.name = "MobileDoor"
	root.position = Vector3(0.5, 0, 0.5)
	root.rotation.y = yaw
	parent.add_child(root)
	var masonry := MeshInstance3D.new()
	masonry.name = "MasonryFrame"
	masonry.mesh = _frame_mesh()
	root.add_child(masonry)
	if _wood_edge == null:
		_wood_edge = StandardMaterial3D.new()
		_wood_edge.albedo_color = Color("30251e")
		_wood_edge.roughness = 0.9
	if hp <= 0 and not opened:
		var rubble := Node3D.new()
		rubble.name = "Rubble"
		root.add_child(rubble)
		for i in 5:
			var board := _box(Vector3(0.11, 0.035, 0.29 + (i % 2) * 0.08))
			board.position = Vector3(-0.25 + i * 0.12, 0.195 + (i % 2) * 0.025, (i % 3 - 1) * 0.11)
			board.rotation.y = -0.5 + i * 0.27
			rubble.add_child(board)
		return
	var damaged := hp < max_hp
	var texture: Texture2D = (SEALED_DAMAGED if damaged else SEALED) if magic else (DAMAGED if damaged else WOOD)
	for side in [-1, 1]:
		var hinge := Node3D.new()
		hinge.name = "LeftHinge" if side < 0 else "RightHinge"
		hinge.position = Vector3(side * 0.365, 0, 0)
		hinge.rotation.y = side * PI / 2 if opened else 0.0
		root.add_child(hinge)
		var body := _box(Vector3(0.358, 0.70, 0.055))
		body.name = "LeafThickness"
		body.position = Vector3(-side * 0.179, 0.535, 0)
		hinge.add_child(body)
		var key := "%s:%d:%s" % [texture.resource_path, side, opened]
		if not _leaf_materials.has(key):
			var material := ShaderMaterial.new()
			material.shader = SHADER
			material.set_shader_parameter("artwork", texture)
			material.set_shader_parameter("half_offset", 0.0 if side < 0 else 0.5)
			material.set_shader_parameter("rune_energy", 1.5 if magic and not opened else 0.0)
			_leaf_materials[key] = material
		for facing in [-1, 1]:
			var face := MeshInstance3D.new()
			face.name = "Front" if facing > 0 else "Back"
			var quad := QuadMesh.new()
			quad.size = Vector2(0.358, 0.70)
			face.mesh = quad
			face.material_override = _leaf_materials[key]
			face.position = body.position + Vector3(0, 0, facing * 0.029)
			face.rotation.y = PI if facing < 0 else 0.0
			hinge.add_child(face)

static func _box(size: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	node.mesh = box
	node.material_override = _wood_edge
	return node

static func _frame_mesh() -> ArrayMesh:
	if _frame != null:
		return _frame
	var surface := SURFACES._builder()
	# Jamb courses and coping share heights, grain and palette with corridor walls.
	for side in [-1, 1]:
		for row in 4:
			var low := Vector2(0.37 if side > 0 else -0.50, -0.14)
			var high := Vector2(0.50 if side > 0 else -0.37, 0.14)
			SURFACES._stone(surface, SURFACES._outline(low, high, 0.012), row * 0.23 + 0.008,
				(row + 1) * 0.23 - 0.008, 0.012, SURFACES.MASONRY_BODY)
	for i in 5:
		var left := -0.37 + i * 0.148 + 0.004
		var right := left + 0.140
		var a := 0.80 + 0.08 * (1.0 - absf(left) / 0.37)
		var b := 0.80 + 0.08 * (1.0 - absf(right) / 0.37)
		_prism(surface, PackedVector2Array([Vector2(left, a), Vector2(right, b), Vector2(right, 0.918), Vector2(left, 0.918)]))
	for i in 2:
		SURFACES._stone(surface, SURFACES._outline(Vector2(-0.50 + i * 0.5 + 0.004, -0.14),
			Vector2(i * 0.5 - 0.004, 0.14), 0.018), 0.925, 1.10, 0.02, SURFACES.MASONRY_CAP)
	_frame = SURFACES._finish(surface, false)
	return _frame

static func _prism(surface: SurfaceTool, outline: PackedVector2Array) -> void:
	surface.set_color(SURFACES.MASONRY_BODY)
	var indices := Geometry2D.triangulate_polygon(outline)
	for depth in [-0.14, 0.14]:
		for triangle in range(0, indices.size(), 3):
			for corner in ([0, 2, 1] if depth > 0 else [0, 1, 2]):
				var point := outline[indices[triangle + corner]]
				surface.add_vertex(Vector3(point.x, point.y, depth))
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		for point in [Vector3(a.x, a.y, 0.14), Vector3(b.x, b.y, 0.14), Vector3(a.x, a.y, -0.14),
				Vector3(b.x, b.y, 0.14), Vector3(b.x, b.y, -0.14), Vector3(a.x, a.y, -0.14)]:
			surface.add_vertex(point)
