extends RefCounted

const ACTIVE: Texture2D = preload("res://assets/mobile/grasp-active-v2.png")
const BROKEN: Texture2D = preload("res://assets/mobile/grasp-broken-v2.png")

static func add_to(parent: Node3D, spent: bool, sprung: bool) -> void:
	# The last charge still shows its activation before becoming rubble.
	if not sprung and not spent:
		return
	var hand := _sprite(ACTIVE if sprung else BROKEN, 0.80)
	hand.name = "StoneGrasp"
	hand.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hand.offset.y = hand.texture.get_height() * (0.44 if sprung else 0.29)
	hand.position = Vector3(0.5, 0.185, 0.5)
	parent.add_child(hand)

static func _sprite(texture: Texture2D, width: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = width / texture.get_width()
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.15
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return sprite
