@tool
extends RefCounted
## Only the rails intersecting an explicitly declared prepared door are cut.
const SHADER = preload("res://shaders/door_wall_junction.gdshader")

static func key(axis: String, at: Vector2) -> String:
	return "%s:%d:%d" % [axis, roundi(at.x), roundi(at.y)]

static func collect(specials: Dictionary, entries: Dictionary) -> Dictionary:
	var cuts := {}
	for cell: Vector2i in specials:
		var special := str(specials[cell])
		if not special.begins_with("doors/"):
			continue
		var id := "door-%s-leaf" % special.get_slice("/", 1)
		var junction: Dictionary = entries.get(id, {}).get("wall_junction", {})
		if junction.is_empty():
			continue
		var axis := str(junction.axis)
		for side in [0, 1]:
			var at := Vector2(cell) + (Vector2(0, side) if axis == "h" else Vector2(side, 0))
			cuts[key(axis, at)] = junction
	return cuts

static func split_parts(parts: Array[Dictionary], cuts: Dictionary, view: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for part in parts:
		var axis := str(part.id).get_slice("-", 1)
		var cut: Dictionary = cuts.get(key(axis, part.at), {}) if str(part.id).begins_with("wall-") else {}
		if cut.is_empty():
			result.append(part)
			continue
		var coordinate := 0 if axis == "h" else 1
		var anchor: float = part.at[coordinate]
		var lo: float = part.min[coordinate] - anchor
		var hi: float = part.max[coordinate] - anchor
		for span in [Vector2(lo, minf(hi, cut.span[0])), Vector2(maxf(lo, cut.span[1]), hi)]:
			if span.y - span.x <= .00001:
				continue
			var segment: Dictionary = part.duplicate()
			var minimum: Vector3 = part.min
			var maximum: Vector3 = part.max
			minimum[coordinate] = anchor + span.x
			maximum[coordinate] = anchor + span.y
			segment["min"] = minimum
			segment["max"] = maximum
			segment["depth"] = Vector2((minimum.x + maximum.x)*.5, (minimum.y + maximum.y)*.5).dot(Vector2(view.x, view.y))
			segment["wall_segment"] = {"axis": axis, "span": span}
			# The full draw rectangle/texture anchor remain unchanged. Only the
			# physical support and its shader mask are split for depth ordering.
			result.append(segment)
	return result

static func material(entry: Dictionary, texture: AtlasTexture, segment: Dictionary, definition: Resource) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SHADER
	var atlas_size := texture.atlas.get_size()
	var region := texture.region
	result.set_shader_parameter("atlas_region", Vector4(region.position.x/atlas_size.x,region.position.y/atlas_size.y,region.size.x/atlas_size.x,region.size.y/atlas_size.y))
	result.set_shader_parameter("logical_frame", Vector4(entry.offset[0],entry.offset[1],entry.size[0],entry.size[1]))
	var bounds: Dictionary = entry.bounds
	result.set_shader_parameter("support_min", Vector3(bounds.min[0],bounds.min[1],bounds.min[2]))
	result.set_shader_parameter("support_max", Vector3(bounds.max[0],bounds.max[1],bounds.max[2]))
	result.set_shader_parameter("projection_x", definition.get("projection_x"))
	result.set_shader_parameter("projection_y", definition.get("projection_y"))
	result.set_shader_parameter("view_direction", definition.get("view_direction"))
	result.set_shader_parameter("along_x", segment.axis == "h")
	result.set_shader_parameter("segment_span", segment.span)
	return result
