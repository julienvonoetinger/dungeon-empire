extends RefCounted

const ARMED: Texture2D = preload("res://assets/mobile/void-armed-v3.png")
const ACTIVE: Texture2D = preload("res://assets/mobile/void-active-v3.png")
const BROKEN: Texture2D = preload("res://assets/mobile/void-broken-v3.png")
const FLOOR_SHADER := preload("res://assets/rendering/void_floor.gdshader")
static var _materials: Dictionary = {}

static func add_to(parent: Node3D, spent: bool, sprung: bool) -> void:
	var trap := Sprite3D.new()
	trap.name = "VoidFloor"
	# Keep the abyss open throughout the final-charge absorption.
	trap.texture = ACTIVE if sprung else BROKEN if spent else ARMED
	trap.pixel_size = 0.98 / trap.texture.get_width()
	trap.position = Vector3(0.5, 0.181, 0.5)
	trap.rotation.x = -PI / 2
	trap.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	trap.shaded = true
	if not _materials.has(trap.texture):
		var material := ShaderMaterial.new()
		material.shader = FLOOR_SHADER
		material.set_shader_parameter("artwork", trap.texture)
		_materials[trap.texture] = material
	trap.material_override = _materials[trap.texture]
	trap.no_depth_test = false
	trap.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	trap.alpha_scissor_threshold = 0.15
	trap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trap.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(trap)
