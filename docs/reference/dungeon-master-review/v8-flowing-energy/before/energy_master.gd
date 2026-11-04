extends Node3D
## Procedural energy deity. All motion is driven by present(), never TIME.
const ENERGY = preload("res://shaders/energy_master.gdshader")
var materials: Array[ShaderMaterial] = []
var core: MeshInstance3D
var iris: Node3D
var orbit: Node3D
var eye_root := Node3D.new()
var birth_vortex := Node3D.new()
var eyelids: Array[MeshInstance3D] = []
var motes := MultiMeshInstance3D.new()
var clock := 0.0

func _ready() -> void:
	eye_root.name = "EyeEmergence"
	add_child(eye_root)
	core = MeshInstance3D.new()
	core.name = "BlackCore"
	var sphere := SphereMesh.new()
	sphere.radius = 0.62
	sphere.height = 1.24
	sphere.radial_segments = 64
	sphere.rings = 32
	core.mesh = sphere
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0.002,0.001,0.008)
	core.material_override = black
	# The vortex throat becomes the pupil: keep only one opaque volume.
	add_child(core)
	iris = Node3D.new()
	iris.name = "IrisVolume"
	eye_root.add_child(iris)
	for i in 3:
		var band := _annulus(0.58 + i * 0.08, 1.3 + i * 0.13, 160, 12, 0.22 - i * 0.15)
		band.material_override = _material(float(i), 0.0)
		iris.add_child(band)
		band.rotation.z = i * 0.77
	orbit = Node3D.new()
	orbit.name = "AccretionDisk"
	add_child(orbit)
	var disk := _annulus(0.75, 2.05, 192, 14, 0.0)
	disk.material_override = _material(4.5, 0.0)
	orbit.add_child(disk)
	orbit.rotation = Vector3(1.12, 0.08, -0.22)
	for sign_value in [-1.0, 1.0]:
		var arc := _eye_arc(sign_value)
		arc.material_override = _material(8.0 + sign_value, 1.0)
		eye_root.add_child(arc)
		eyelids.append(arc)
	# A concave funnel is visible before any part of the eye appears.
	birth_vortex.name = "BirthVortex"
	birth_vortex.position.z = -0.25
	birth_vortex.rotation = Vector3(0.24,-0.12,-0.17)
	add_child(birth_vortex)
	var funnel := _annulus(0.12,1.85,192,24,-0.95)
	funnel.material_override = _material(11.7,0.0)
	birth_vortex.add_child(funnel)
	var dot := SphereMesh.new()
	dot.radius = 0.012
	dot.height = 0.024
	dot.radial_segments = 8
	dot.rings = 4
	var light := StandardMaterial3D.new()
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light.albedo_color = Color(0.65,0.24,1.0)
	dot.material = light
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = dot
	multimesh.instance_count = 64
	motes.multimesh = multimesh
	add_child(motes)
	present(0.0, 0.0, 0.0)

func _material(seed_value: float, kind_value: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ENERGY
	material.set_shader_parameter("seed", seed_value)
	material.set_shader_parameter("kind", kind_value)
	materials.append(material)
	return material

func _mesh(vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.FORWARD)
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.custom_aabb = AABB(Vector3(-2.5,-2.5,-2.5),Vector3(5,5,5))
	return instance

func _annulus(inner: float, outer: float, segments: int, rows: int, depth: float) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in rows + 1:
		var radial := float(row) / rows
		var radius := lerpf(inner, outer, radial)
		for column in segments + 1:
			var turn := float(column) / segments
			var angle := turn * TAU
			var r := radius * (1.0 + 0.025 * radial * sin(angle * 5.0 + radial * 8.0))
			vertices.append(Vector3(cos(angle)*r, sin(angle)*r, depth * (1.0-radial) + 0.05*sin(angle*3.0)*radial))
			uvs.append(Vector2(radial,turn))
	for row in rows:
		for column in segments:
			var a := row * (segments + 1) + column
			var b := a + segments + 1
			indices.append_array(PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	return _mesh(vertices,uvs,indices)

func _eye_arc(sign_value: float) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in 129:
		var t := float(i)/128.0
		var x := lerpf(-1.85,1.85,t)
		var shape := pow(maxf(0.0,sin(t*PI)),0.9)
		for j in 5:
			var side := float(j)/4.0
			vertices.append(Vector3(x,sign_value*(0.84*shape+(side-0.5)*0.19*shape),0.17+0.24*sin(t*TAU)))
			uvs.append(Vector2(side,t))
	for i in 128:
		for j in 4:
			var a := i*5+j
			indices.append_array(PackedInt32Array([a,a+5,a+1,a+1,a+5,a+6]))
	return _mesh(vertices,uvs,indices)

func present(time: float, attention: float, manifestation: float) -> void:
	clock = time
	visible = manifestation > 0.001
	if not is_instance_valid(core): return
	scale = Vector3.ONE * lerpf(0.08,1.0,smoothstep(0.0,1.0,manifestation))
	var emergence := smoothstep(3.0,8.0,time)
	var eye_shape := smoothstep(5.5,9.0,time)
	eye_root.visible = emergence > 0.001
	birth_vortex.rotation.z = -0.17 + 0.06*sin(time*0.18)
	var throat_position := birth_vortex.transform * Vector3(0,0,-0.95)
	core.position = throat_position.lerp(Vector3(0,0,0.55),emergence)
	# No opaque throat during the opening: the pupil grows from zero only
	# when the eye emerges. Keep the hidden transform invertible at rest.
	core.visible = emergence > 0.0
	core.basis = Basis.IDENTITY.scaled(Vector3.ONE * maxf(0.00001,emergence))
	eye_root.position = core.position
	eye_root.scale = Vector3.ONE * lerpf(0.17/0.62,1.0,emergence)
	iris.rotation = Vector3(0.08*sin(time*0.23),0.12*sin(time*0.19),0.045*sin(time*0.31))
	orbit.position.z = eye_root.position.z * emergence * 0.6
	orbit.rotation.z = -0.22 + 0.07*sin(time*0.21)
	for i in materials.size():
		materials[i].set_shader_parameter("clock_time",time)
		var opacity := 0.7 if i == 0 else 0.24
		if i < 3: opacity *= emergence
		if i == 3: opacity = lerpf(0.18,0.9,emergence)
		if i == 4 or i == 5: opacity = eye_shape * lerpf(0.12,1.0,attention)
		if i == 6: opacity = lerpf(1.0,0.28,emergence)
		materials[i].set_shader_parameter("strength",opacity*manifestation)
	for arc in eyelids:
		arc.scale.y = lerpf(1.35,0.94,attention)
	for i in motes.multimesh.instance_count:
		var phase := fposmod(float(i)*0.6180339 + time*0.055,1.0)
		var angle := float(i)*2.39996 + time*0.28 + phase*3.0
		var radius := lerpf(2.25,0.7,phase)
		var point := Vector3(cos(angle)*radius,sin(angle)*radius*0.68,sin(angle*1.7+i)*0.55)
		var dot_scale := sin(phase*PI)*manifestation*(0.45+float(i%5)*0.16)
		motes.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*dot_scale),point))
