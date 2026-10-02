extends RefCounted

static var _meshes := {}

static func add_to(hinge: Node3D, side: int) -> void:
	if not _meshes.has(side):
		_meshes[side] = _build(side)
	var root := Node3D.new()
	root.name = "PrototypeLeaf"
	hinge.add_child(root)
	for mesh in _meshes[side]:
		var part := MeshInstance3D.new()
		part.mesh = mesh
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(part)

static func _box(surface: SurfaceTool, size: Vector3, position: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.append_from(mesh, 0, Transform3D(Basis.IDENTITY, position))

static func _build(side: int) -> Array:
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	for board in 4:
		_box(wood, Vector3(0.108, 0.70, 0.05), Vector3(-side * (0.058 + board * 0.113), 0.535, -0.070))
	var timber := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
    vec3 p = local_position;
    float grain = sin(p.x * 650.0 + sin(p.y * 19.0) * 1.5);
    float board = fract(floor(abs(p.x) / 0.113) * 0.37);
    ALBEDO = mix(vec3(0.105, 0.051, 0.025), vec3(0.27, 0.15, 0.068), 0.40 + board * 0.30 + grain * 0.12);
    ROUGHNESS = 0.87;
}
"""
	timber.shader = shader
	wood.set_material(timber)
	var metal := SurfaceTool.new()
	metal.begin(Mesh.PRIMITIVE_TRIANGLES)
	for facing in [-1, 1]:
		for height in [0.31, 0.76]:
			_box(metal, Vector3(0.432, 0.048, 0.012), Vector3(-side * 0.226, height, -0.070 + facing * 0.033))
			var barrel := CylinderMesh.new()
			barrel.top_radius = 0.014
			barrel.bottom_radius = 0.014
			barrel.height = 0.082
			barrel.radial_segments = 8
			metal.append_from(barrel, 0, Transform3D(Basis.IDENTITY, Vector3(-side * 0.018, height, -0.070 + facing * 0.040)))
			for rivet in [0.045, 0.20, 0.405]:
				var stud := SphereMesh.new()
				stud.radius = 0.009
				stud.height = 0.018
				stud.radial_segments = 6
				stud.rings = 3
				metal.append_from(stud, 0, Transform3D(Basis.IDENTITY, Vector3(-side * rivet, height, -0.070 + facing * 0.043)))
		_box(metal, Vector3(0.042, 0.085, 0.012), Vector3(-side * 0.385, 0.54, -0.070 + facing * 0.034))
		var ring := TorusMesh.new()
		ring.inner_radius = 0.020
		ring.outer_radius = 0.031
		ring.rings = 12
		ring.ring_segments = 6
		metal.append_from(ring, 0, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(-side * 0.385, 0.52, -0.070 + facing * 0.049)))
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("514c42")
	iron.metallic = 0.72
	iron.roughness = 0.55
	metal.set_material(iron)
	return [wood.commit(), metal.commit()]
