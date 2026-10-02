extends RefCounted

const ARMED: Texture2D = preload("res://assets/mobile/spike-armed-v2.png")
const ACTIVE: Texture2D = preload("res://assets/mobile/spike-active-v2.png")
const BROKEN: Texture2D = preload("res://assets/mobile/spike-broken-v2.png")

static func add_to(parent: Node3D, spent: bool, sprung: bool) -> void:
	var texture := ACTIVE if sprung else BROKEN if spent else ARMED
	# Artwork margins differ; anchor each state's emergence point at the floor.
	var canvas_height := 0.36 if sprung else 0.25 if spent else 0.14
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
