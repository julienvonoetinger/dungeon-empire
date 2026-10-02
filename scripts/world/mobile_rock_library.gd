extends RefCounted

static var _meshes: Dictionary = {}
static var _material: ShaderMaterial

static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://assets/rendering/rock_strata.gdshader")
		_material.set_shader_parameter("stone", preload("res://assets/mobile/bedrock-v2.png"))
		_material.set_shader_parameter("albedo_gain", 1.25)
		_material.set_shader_parameter("texture_scale", 0.38)
		_material.set_shader_parameter("bump_strength", 0.0)
	return _material

static func mesh(variant: int, distant: bool = false) -> Mesh:
	var path := "res://assets/mobile/rocks/rock_%d%s.res" % [variant, "_far" if distant else ""]
	if not _meshes.has(path):
		var resource: ArrayMesh = load(path)
		resource.surface_set_material(0, material())
		_meshes[path] = resource
	return _meshes[path]

static func placement(cell: Vector2i) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("rock:%d:%d" % [cell.x, cell.y])
	var variant := rng.randi_range(0, 5)
	return {"variant": variant, "height": rng.randf_range(0.28, 0.48) if variant in [2, 5] else rng.randf_range(0.65, 1.45),
		"yaw": rng.randi_range(0, 3) * PI * 0.5, "width": rng.randf_range(0.86, 0.98)}
