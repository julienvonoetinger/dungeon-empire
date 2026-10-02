extends RefCounted

static var _masonry_material: ShaderMaterial
static var _rock_material: ShaderMaterial
const GEOLOGY := preload("res://scripts/world/mobile_geology.gd")
const MASONRY_BODY := Color("626570")
const MASONRY_CAP := Color("727887")

static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material

static func _mesh(parent: Node3D, shape: Mesh, position: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = position
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

static func _box(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	_mesh(parent, shape, position, material)

static func trap(parent: Node3D, tile: int, spent: bool, sprung: bool = false) -> void:
	if tile == GameTypes.Tile.SNARE:
		preload("res://scripts/world/mobile_grasp.gd").add_to(parent, spent, sprung)
		return
	if tile == GameTypes.Tile.SPIKE:
		preload("res://scripts/world/mobile_spines.gd").add_to(parent, spent, sprung)
	elif tile == GameTypes.Tile.VOID:
		preload("res://scripts/world/mobile_void.gd").add_to(parent, spent, sprung)

# Combine stones into one mesh per module to keep mobile draw calls bounded.

static func _builder() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	return surface

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	if (b - a).cross(c - a).length_squared() < 0.0000000001:
		return
	for vertex in [a, c, b]:
		surface.set_color(color)
		surface.add_vertex(vertex)

static func _stone(surface: SurfaceTool, outline: Array[Vector2], bottom: float, top: float, bevel: float, color: Color, slope: Vector2 = Vector2.ZERO, slope_origin: Vector2 = Vector2.ZERO) -> void:
	var center := Vector2.ZERO
	for point in outline:
		center += point
	center /= outline.size()
	var summit := Vector3(center.x, top + slope.dot(center - slope_origin), center.y)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var inset_a := a.move_toward(center, bevel)
		var inset_b := b.move_toward(center, bevel)
		var low_a := Vector3(a.x, bottom, a.y)
		var low_b := Vector3(b.x, bottom, b.y)
		var edge_a := Vector3(a.x, top - bevel + slope.dot(a - slope_origin), a.y)
		var edge_b := Vector3(b.x, top - bevel + slope.dot(b - slope_origin), b.y)
		var top_a := Vector3(inset_a.x, top + slope.dot(inset_a - slope_origin), inset_a.y)
		var top_b := Vector3(inset_b.x, top + slope.dot(inset_b - slope_origin), inset_b.y)
		_triangle(surface, edge_a, edge_b, low_a, color.darkened(0.12))
		_triangle(surface, edge_b, low_b, low_a, color.darkened(0.12))
		_triangle(surface, top_a, top_b, edge_a, color)
		_triangle(surface, top_b, edge_b, edge_a, color)
		_triangle(surface, top_a, summit, top_b, color.lightened(0.06))

static func _outline(low: Vector2, high: Vector2, chip: float) -> Array[Vector2]:
	return [Vector2(low.x + chip, low.y), Vector2(high.x - chip, low.y),
		Vector2(high.x, low.y + chip), Vector2(high.x, high.y - chip),
		Vector2(high.x - chip, high.y), Vector2(low.x + chip, high.y),
		Vector2(low.x, high.y - chip), Vector2(low.x, low.y + chip)]

static func _finish(surface: SurfaceTool, rock_texture: bool) -> ArrayMesh:
	surface.generate_normals()
	if rock_texture:
		if _rock_material == null:
			_rock_material = ShaderMaterial.new()
			_rock_material.shader = load("res://assets/rendering/rock_strata.gdshader")
			_rock_material.set_shader_parameter("stone", load("res://assets/mobile/bedrock-v2.png"))
		surface.set_material(_rock_material)
	else:
		if _masonry_material == null:
			var shader := Shader.new()
			shader.code = """
shader_type spatial;
uniform sampler2D stone : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 position_world;
varying vec3 normal_world;
void vertex() {
    position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    normal_world = MODEL_NORMAL_MATRIX * NORMAL;
}
void fragment() {
    vec3 weights = pow(abs(normalize(normal_world)), vec3(4.0));
    weights /= max(dot(weights, vec3(1.0)), 0.001);
    vec3 p = position_world * 0.22;
    vec3 grain = texture(stone, p.yz).rgb * weights.x
        + texture(stone, p.xz).rgb * weights.y
        + texture(stone, p.xy).rgb * weights.z;
    ALBEDO = COLOR.rgb * (grain * 1.85 + vec3(0.025));
    ROUGHNESS = 0.9;
    SPECULAR = 0.15;
}
"""
			_masonry_material = ShaderMaterial.new()
			_masonry_material.shader = shader
			_masonry_material.set_shader_parameter("stone", load("res://assets/mobile/masonry-grain-v2.png"))
		surface.set_material(_masonry_material)
	return surface.commit()

static func rock(cell: Vector2i, low: Vector2, high: Vector2) -> ArrayMesh:
	var surface := _builder()
	rock_into(surface, cell, low, high, Vector2(cell))
	return _finish(surface, true)

static func rock_into(surface: SurfaceTool, cell: Vector2i, low: Vector2, high: Vector2, origin: Vector2 = Vector2.ZERO) -> void:
	var world_low := Vector2(cell) + low
	var world_high := Vector2(cell) + high
	# The continuous low bed prevents fissures exposing the black background.
	_stone(surface, _outline(world_low - origin, world_high - origin, 0.0), -0.5, -0.40, 0.0, Color("464951"))
	for fragment in GEOLOGY.fragments(world_low, world_high):
		_rock_piece(surface, fragment, world_low, world_high, origin)

static func _rock_point(point: Vector2, fragment: Dictionary, drop: float = 0.0) -> Vector3:
	var relief := sin(point.x * 2.7 + point.y * 1.3) * sin(point.y * 2.1 - point.x * 1.6) * 0.025
	return Vector3(point.x, fragment.height + fragment.slope.dot(point - fragment.site) + relief - drop, point.y)

static func _rock_piece(surface: SurfaceTool, fragment: Dictionary, low: Vector2, high: Vector2, origin: Vector2) -> void:
	var polygon: Array[Vector2] = fragment.outline
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= polygon.size()
	# Bevel the actual fracture, then clip faces to tiles: no grid-shaped bevels.
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		var ia := a.move_toward(center, minf(0.14, a.distance_to(center) * 0.25))
		var ib := b.move_toward(center, minf(0.14, b.distance_to(center) * 0.25))
		_rock_face(surface, [_rock_point(ia, fragment), _rock_point(center, fragment), _rock_point(ib, fragment)], low, high, origin, fragment.tint)
		_rock_face(surface, [_rock_point(a, fragment, 0.13), _rock_point(ia, fragment), _rock_point(ib, fragment), _rock_point(b, fragment, 0.13)], low, high, origin, fragment.tint.lightened(0.025))
		var ma := a.move_toward(center, 0.025 + absf(sin(a.x * 8.7 + a.y * 6.3)) * 0.06)
		var mb := b.move_toward(center, 0.025 + absf(sin(b.x * 8.7 + b.y * 6.3)) * 0.06)
		var mid_a := Vector3(ma.x, fragment.height * 0.35, ma.y)
		var mid_b := Vector3(mb.x, fragment.height * 0.35, mb.y)
		_rock_face(surface, [mid_a, _rock_point(a, fragment, 0.13), _rock_point(b, fragment, 0.13), mid_b], low, high, origin, fragment.tint.darkened(0.23))
		_rock_face(surface, [Vector3(a.x, -0.45, a.y), mid_a, mid_b, Vector3(b.x, -0.45, b.y)], low, high, origin, fragment.tint.darkened(0.38))
	var cut: Array[Vector2] = fragment.polygon
	for i in cut.size():
		var a := cut[i]
		var b := cut[(i + 1) % cut.size()]
		var boundary := (is_equal_approx(a.x, low.x) and is_equal_approx(b.x, low.x)) or (is_equal_approx(a.x, high.x) and is_equal_approx(b.x, high.x)) or (is_equal_approx(a.y, low.y) and is_equal_approx(b.y, low.y)) or (is_equal_approx(a.y, high.y) and is_equal_approx(b.y, high.y))
		if boundary:
			_rock_face(surface, [Vector3(a.x, -0.45, a.y), _rock_point(a, fragment, 0.13), _rock_point(b, fragment, 0.13), Vector3(b.x, -0.45, b.y)], low, high, origin, fragment.tint.darkened(0.25))

static func _rock_face(surface: SurfaceTool, face: Array[Vector3], low: Vector2, high: Vector2, origin: Vector2, color: Color) -> void:
	var polygon := face
	for plane in [Vector3(-1, 0, -low.x), Vector3(1, 0, high.x), Vector3(0, -1, -low.y), Vector3(0, 1, high.y)]:
		if polygon.size() < 3:
			return
		var clipped: Array[Vector3] = []
		var before: Vector3 = polygon[-1]
		var distance_before: float = before.x * plane.x + before.z * plane.y - plane.z
		for point in polygon:
			var distance: float = point.x * plane.x + point.z * plane.y - plane.z
			if (distance_before <= 0) != (distance <= 0):
				clipped.append(before.lerp(point, distance_before / (distance_before - distance)))
			if distance <= 0:
				clipped.append(point)
			before = point
			distance_before = distance
		polygon = clipped
	var offset := Vector3(origin.x, 0, origin.y)
	for i in range(1, polygon.size() - 1):
		_triangle(surface, polygon[0] - offset, polygon[i] - offset, polygon[i + 1] - offset, color)

static func wall(span: int, seed_value: int, foundation: bool = false) -> ArrayMesh:
	var surface := _builder()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var courses := [0.0, 0.16, 0.37, 0.54, 0.76, 0.925]
	# Recessed mortar prevents worn joints from opening through the whole wall.
	_stone(surface, _outline(Vector2(0, 0.028), Vector2(span, 0.252), 0.0),
		0.0, 0.18 if foundation else 0.918, 0.0, MASONRY_BODY.darkened(0.22))
	for row in (1 if foundation else 5):
		var x := -rng.randf_range(0.09, 0.23) if row % 2 else 0.0
		while x < span:
			var width := rng.randf_range(0.20, 0.48)
			var end := minf(x + width, float(span))
			var start := maxf(x, 0.0)
			if end - start > 0.04:
				var low := Vector2(start + 0.004, rng.randf_range(0.002, 0.026))
				var high := Vector2(end - 0.004, rng.randf_range(0.253, 0.278))
				var color := MASONRY_BODY * rng.randf_range(0.83, 1.13)
				var bottom: float = courses[row] + rng.randf_range(0.004, 0.010)
				var top: float = (0.23 if foundation else courses[row + 1]) - rng.randf_range(0.006, 0.018)
				_stone(surface, _worn_outline(low, high, rng), bottom, top, rng.randf_range(0.013, 0.026), color,
					Vector2(rng.randf_range(-0.025, 0.025), 0), (low + high) * 0.5)
			x += width
	if foundation:
		return _finish(surface, false)
	var cap_x := 0.0
	while cap_x < span:
		var end := minf(cap_x + rng.randf_range(0.29, 0.52), span)
		var low := Vector2(cap_x + 0.004, 0)
		var high := Vector2(end - 0.004, 0.28)
		if end - cap_x > 0.025:
			_stone(surface, _worn_outline(low, high, rng), 0.915,
				1.10 + rng.randf_range(-0.025, 0.018), 0.026, MASONRY_CAP * rng.randf_range(0.91, 1.04))
		cap_x = end
	return _finish(surface, false)

static func _worn_outline(low: Vector2, high: Vector2, rng: RandomNumberGenerator) -> Array[Vector2]:
	var chip := minf(0.035, (high.x - low.x) * 0.16)
	var points := _outline(low, high, chip)
	var result: Array[Vector2] = []
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		result.append(a)
		if a.distance_to(b) > 0.10:
			var middle := a.lerp(b, rng.randf_range(0.3, 0.7))
			result.append(middle.move_toward((low + high) * 0.5, rng.randf_range(0.002, 0.014)))
	return result

static func pillar(foundation: bool = false) -> ArrayMesh:
	var surface := _builder()
	for row in (1 if foundation else 4):
		var half := 0.145 if row % 2 else 0.16
		_stone(surface, _outline(Vector2(-half, -half), Vector2(half, half), 0.025),
			row * 0.28 + 0.008, (row + 1) * 0.28 - 0.008, 0.02, MASONRY_BODY)
	if foundation:
		return _finish(surface, false)
	_stone(surface, _outline(Vector2(-0.18, -0.18), Vector2(0.18, 0.18), 0.025),
		1.12, 1.23, 0.025, MASONRY_CAP)
	return _finish(surface, false)
