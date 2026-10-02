extends RefCounted

static var _masonry_material: ShaderMaterial
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
	for vertex in [a, c, b]:
		surface.set_color(color)
		surface.add_vertex(vertex)

static func _stone(surface: SurfaceTool, outline: Array[Vector2], bottom: float, top: float, bevel: float, color: Color) -> void:
	var center := Vector2.ZERO
	for point in outline:
		center += point
	center /= outline.size()
	var summit := Vector3(center.x, top, center.y)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var inset_a := a.move_toward(center, bevel)
		var inset_b := b.move_toward(center, bevel)
		var low_a := Vector3(a.x, bottom, a.y)
		var low_b := Vector3(b.x, bottom, b.y)
		var edge_a := Vector3(a.x, top - bevel, a.y)
		var edge_b := Vector3(b.x, top - bevel, b.y)
		var top_a := Vector3(inset_a.x, top, inset_a.y)
		var top_b := Vector3(inset_b.x, top, inset_b.y)
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
	var material := _material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = load("res://assets/mobile/bedrock-v1.png")
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * (0.24 if rock_texture else 0.8)
	if rock_texture:
		surface.set_material(material)
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
    vec3 p = position_world * 0.8;
    vec3 grain = texture(stone, p.yz).rgb * weights.x
        + texture(stone, p.xz).rgb * weights.y
        + texture(stone, p.xy).rgb * weights.z;
    ALBEDO = COLOR.rgb * (grain * 1.65 + vec3(0.08));
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
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(cell))
	var surface := _builder()
	var gap := 0.025
	var split := rng.randf_range(0.36, 0.64)
	var vertical := rng.randi_range(0, 1) == 0
	for i in 2:
		var start := low + Vector2.ONE * gap
		var end := high - Vector2.ONE * gap
		if vertical:
			if i == 0:
				end.x = lerpf(low.x, high.x, split) - gap
			else:
				start.x = lerpf(low.x, high.x, split) + gap
		else:
			if i == 0:
				end.y = lerpf(low.y, high.y, split) - gap
			else:
				start.y = lerpf(low.y, high.y, split) + gap
		var chip := minf(end.x - start.x, end.y - start.y) * rng.randf_range(0.18, 0.32)
		var outline := _outline(start, end, chip)
		var height := rng.randf_range(0.30, 0.86)
		var tint := Color("66727e") * rng.randf_range(0.8, 1.05)
		_stone(surface, outline, -0.5, height, 0.055, tint)
	return _finish(surface, true)

static func wall(span: int, seed_value: int, foundation: bool = false) -> ArrayMesh:
	var surface := _builder()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for row in (1 if foundation else 4):
		var x := -0.22 if row % 2 else 0.0
		while x < span:
			var width := rng.randf_range(0.30, 0.62)
			var end := minf(x + width, float(span))
			var start := maxf(x, 0.0)
			if end - start > 0.04:
				var low := Vector2(start + 0.009, rng.randf_range(0.008, 0.023))
				var high := Vector2(end - 0.009, rng.randf_range(0.253, 0.272))
				var color := MASONRY_BODY * rng.randf_range(0.88, 1.08)
				_stone(surface, _outline(low, high, minf(0.024, (end - start) * 0.2)), row * 0.23 + 0.012,
					(row + 1) * 0.23 - rng.randf_range(0.006, 0.018), 0.022, color)
			x += width
	if foundation:
		return _finish(surface, false)
	for i in span * 2:
		var low := Vector2(i * 0.5 + 0.008, 0)
		var high := Vector2((i + 1) * 0.5 - 0.008, 0.28)
		_stone(surface, _outline(low, high, 0.025), 0.925,
			1.10 + rng.randf_range(-0.018, 0.018), 0.025, MASONRY_CAP * rng.randf_range(0.94, 1.04))
	return _finish(surface, false)

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
