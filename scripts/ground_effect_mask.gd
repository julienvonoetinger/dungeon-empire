extends RefCounted
## Rebuild-time receiving cells. Prepared images stay unchanged on the GPU.
const MIX := preload("res://shaders/ground_effect_mix.gdshader")
const ADD := preload("res://shaders/ground_effect_add.gdshader")

static func receivers(at: Vector2, cells: Dictionary, specials: Dictionary) -> Dictionary:
	var origin := Vector2i(floori(at.x-1.5), floori(at.y-1.5))
	var mask := 0
	for y in 4:
		for x in 4:
			var cell := origin+Vector2i(x,y)
			if cells.has(cell) and not specials.has(cell):
				mask |= 1 << (y*4+x)
	return {"origin":origin,"bits":mask,"enabled":not cells.is_empty()}

static func material(entry: Dictionary, at: Vector2, scale: Vector2, receiving: Dictionary, px: Vector3, py: Vector3) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = ADD if entry.get("ground_blend", "mix") == "add" else MIX
	var determinant := px.x*py.y-px.y*py.x
	result.set_shader_parameter("ground_u", Vector2(py.y,-px.y)/(determinant*256.0))
	result.set_shader_parameter("ground_v", Vector2(-py.x,px.x)/(determinant*256.0))
	result.set_shader_parameter("effect_origin",at)
	result.set_shader_parameter("frame_offset",Vector2(entry.offset[0],entry.offset[1]))
	result.set_shader_parameter("logical_per_texel",scale)
	result.set_shader_parameter("clip_enabled",receiving.enabled)
	result.set_shader_parameter("floor_origin",receiving.origin)
	result.set_shader_parameter("floor_mask",receiving.bits)
	return result
