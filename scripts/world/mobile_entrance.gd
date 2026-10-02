extends RefCounted

const TORCH_RIG := preload("res://scripts/world/wall_torch_rig.gd")
const SURFACES := preload("res://scripts/world/mobile_surfaces.gd")
static var _arch: ArrayMesh
static var _stone: StandardMaterial3D

static func add_to(parent: Node3D, face: Vector3) -> void:
	var root := Node3D.new()
	root.name = "MobileEntrance"
	root.position = Vector3(0.5, 0.175, 0.5) - face * 0.44
	root.rotation.y = atan2(face.x, face.z)
	parent.add_child(root)
	var arch := MeshInstance3D.new()
	arch.name = "EntranceArch"
	arch.mesh = _arch_mesh()
	root.add_child(arch)
	var darkness := StandardMaterial3D.new()
	darkness.albedo_color = Color("090a0b")
	darkness.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_box(root, "PassageDepth", Vector3(0.62, 0.90, 0.02), Vector3(0, 0.45, -0.25), darkness)
	_box(root, "RearStone", Vector3(0.62, 0.94, 0.025), Vector3(0, 0.47, -0.285), _stone)
	var steps := Node3D.new()
	steps.name = "Steps"
	root.add_child(steps)
	for i in 4:
		var height := 0.025 + i * 0.035
		_box(steps, "Step%d" % i, Vector3(0.59, height, 0.10), Vector3(0, height * 0.5, 0.10 - i * 0.10), _stone)
	var torches := Node3D.new()
	torches.name = "Torches"
	root.add_child(torches)
	for side in [-1, 1]:
		var mount := Node3D.new()
		mount.position = Vector3(side * 0.43, 0, 0.18)
		torches.add_child(mount)
		mount.add_child(TORCH_RIG.create_visual())

static func _box(parent: Node3D, label: String, size: Vector3, position: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)

static func _arch_mesh() -> ArrayMesh:
	if _arch != null:
		return _arch
	_stone = StandardMaterial3D.new()
	_stone.albedo_texture = preload("res://assets/mobile/masonry-grain-v2.png")
	_stone.albedo_color = Color("a5a7ae")
	_stone.vertex_color_use_as_albedo = true
	_stone.uv1_triplanar = true
	_stone.roughness = 0.95
	_stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for side in [-1, 1]:
		for row in 3:
			var low := Vector2(0.31 if side > 0 else -0.54, row * 0.21 + 0.007)
			var high := Vector2(0.54 if side > 0 else -0.31, (row + 1) * 0.21 - 0.007)
			_prism(surface, PackedVector2Array([low, Vector2(high.x, low.y), high, Vector2(low.x, high.y)]), SURFACES.MASONRY_BODY * (0.90 + row * 0.035))
	for i in 9:
		var a := PI * i / 9.0 + 0.012
		var b := PI * (i + 1) / 9.0 - 0.012
		var center := Vector2(0, 0.63)
		_prism(surface, PackedVector2Array([
			center + Vector2(cos(a), sin(a)) * 0.31,
			center + Vector2(cos(a), sin(a)) * 0.54,
			center + Vector2(cos(b), sin(b)) * 0.54,
			center + Vector2(cos(b), sin(b)) * 0.31,
		]), SURFACES.MASONRY_CAP * (0.90 + (i % 3) * 0.035))
	_arch = SURFACES._finish(surface, false)
	return _arch

static func _prism(surface: SurfaceTool, outline: PackedVector2Array, tint: Color) -> void:
	# Separate extruded stones leave an actual opening from oblique views.
	surface.set_color(tint)
	var indices := Geometry2D.triangulate_polygon(outline)
	for depth in [0.18, -0.28]:
		for triangle in range(0, indices.size(), 3):
			for corner in ([0, 2, 1] if depth > 0 else [0, 1, 2]):
				var point := outline[indices[triangle + corner]]
				surface.add_vertex(Vector3(point.x, point.y, depth))
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		for point in [Vector3(a.x, a.y, 0.18), Vector3(b.x, b.y, 0.18), Vector3(a.x, a.y, -0.28),
				Vector3(b.x, b.y, 0.18), Vector3(b.x, b.y, -0.28), Vector3(a.x, a.y, -0.28)]:
			surface.add_vertex(point)
