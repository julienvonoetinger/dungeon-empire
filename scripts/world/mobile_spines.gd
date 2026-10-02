extends RefCounted

const ARMED: Texture2D = preload("res://assets/mobile/spike-armed-v2.png")
const ACTIVE: Texture2D = preload("res://assets/mobile/spike-active-v2.png")
const BROKEN: Texture2D = preload("res://assets/mobile/spike-broken-v2.png")
static var _sockets: ArrayMesh

static func add_to(parent: Node3D, spent: bool, sprung: bool) -> void:
	var sockets := MeshInstance3D.new()
	sockets.name = "SpikeSockets"
	sockets.mesh = _socket_mesh()
	sockets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sockets)
	var texture := ACTIVE if sprung else BROKEN if spent else ARMED
	# Artwork margins differ; anchor each state's emergence point at the floor.
	var canvas_height := 0.55 if sprung else 0.25 if spent else 0.14
	var anchor := 0.40 if sprung else 0.18 if spent else 0.22
	for x in 3:
		for z in 3:
			var spike := Sprite3D.new()
			spike.name = "Spike%d" % (x * 3 + z)
			spike.texture = texture
			spike.pixel_size = canvas_height / texture.get_height()
			spike.offset.y = texture.get_height() * anchor
			spike.position = Vector3(0.25 + x * 0.25, 0.185, 0.25 + z * 0.25)
			spike.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			spike.shaded = false
			spike.no_depth_test = false
			spike.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			spike.alpha_scissor_threshold = 0.15
			spike.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(spike)

static func _socket_mesh() -> ArrayMesh:
	if _sockets != null:
		return _sockets
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in 3:
		for z in 3:
			var center := Vector3(0.25 + x * 0.25, 0.179, 0.25 + z * 0.25)
			var corners := [Vector3(-0.08, 0, -0.08), Vector3(0.08, 0, -0.08), Vector3(0.08, 0, 0.08), Vector3(-0.08, 0, 0.08)]
			for index in [0, 2, 1, 0, 3, 2]:
				surface.set_normal(Vector3.UP)
				surface.add_vertex(center + corners[index])
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("211e28")
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	_sockets = surface.commit()
	return _sockets
