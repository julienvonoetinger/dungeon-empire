@tool
extends Node
## One phase per renderer, no TIME dependency, texture writes or scene rebuilds.
const EFFECT = preload("res://shaders/heart_vortex.gdshader")
const CYCLE_SECONDS := 12.0
var phase := 0.0
var enabled := true
var materials: Array[ShaderMaterial] = []

func _ready() -> void:
	_refresh_processing()

func clear_materials() -> void:
	materials.clear()
	_refresh_processing()

func set_enabled(value: bool) -> void:
	enabled = value
	for material in materials:
		material.set_shader_parameter("animation_enabled", enabled and not Engine.is_editor_hint())
	_refresh_processing()

func _refresh_processing() -> void:
	set_process(not Engine.is_editor_hint() and enabled and not materials.is_empty())

func bind(entry: Dictionary, texture: AtlasTexture) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = EFFECT
	var atlas_size := texture.atlas.get_size()
	var region := texture.region
	material.set_shader_parameter("atlas_rect", Vector4(region.position.x/atlas_size.x, region.position.y/atlas_size.y, region.size.x/atlas_size.x, region.size.y/atlas_size.y))
	material.set_shader_parameter("frame_size", Vector2(entry.size[0], entry.size[1]))
	material.set_shader_parameter("vortex_center", Vector2(entry.vortex.center[0], entry.vortex.center[1]))
	material.set_shader_parameter("vortex_radius", float(entry.vortex.radius))
	material.set_shader_parameter("phase", phase)
	material.set_shader_parameter("animation_enabled", enabled and not Engine.is_editor_hint())
	materials.append(material)
	_refresh_processing()
	return material

func _process(delta: float) -> void:
	if not enabled or not get_parent()._vortex_can_advance():
		return
	phase = fposmod(phase + delta/CYCLE_SECONDS, 1.0)
	for material in materials:
		material.set_shader_parameter("phase", phase)
