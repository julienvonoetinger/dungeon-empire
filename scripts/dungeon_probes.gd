extends RefCounted

const FIXTURES := preload("res://scripts/probe_fixtures.gd")

## Read-only snapshots. All points and contours are in Dungeon-local pixels.
static func inspect(dungeon: Node2D) -> Dictionary:
	var elements: Array[Dictionary] = []
	_collect(dungeon,dungeon,elements,{})
	var probes: Array[Dictionary] = []
	var failures: Array[Dictionary] = []
	for definition: Dictionary in FIXTURES.definitions(dungeon):
		var probe := definition.duplicate(true)
		probe["ok"] = false
		probe["actual_id"] = ""
		probe["message"] = "Aucun contour visible à cette position"
		if probe.has("anchor_path"):
			var node := dungeon.get_node_or_null(probe.anchor_path) as Node2D
			if node != null:
				probe["actual_id"] = probe.anchor_path
				probe["actual_position"] = dungeon.to_local(node.global_position)
				probe.ok = node.is_visible_in_tree() and probe.actual_position.is_equal_approx(probe.position)
				probe.message = "Origine du cœur : %s ; attendue : %s"%[probe.actual_position,probe.position]
		else:
			# Geometry probes inspect the floor substrate independently of the heart
			# and translucent lighting sprites, as the existing GPU suite does.
			var element := _at(elements,probe.position,probe.group == "heart")
			if not element.is_empty():
				probe.actual_id = element.id
				probe.ok = element.kind in probe.expected_kinds
				probe.message = "%s trouvé ; attendu : %s"%[element.kind,", ".join(probe.expected_kinds)]
				if not element.native_mapping:
					probe.ok = false
					probe.message += " ; coordonnées ou transformation de texture non natives"
				elif probe.has("expected_uv"):
					var uv := _uv_at(element,probe.position)
					probe["actual_uv"] = uv
					probe.ok = probe.ok and uv.is_equal_approx(probe.expected_uv)
					probe.message += " ; UV %s / attendu %s"%[uv,probe.expected_uv]
				if probe.has("prefix"):
					probe.ok = probe.ok and str(element.id).begins_with(probe.prefix)
		probes.append(probe)
		if not probe.ok:
			failures.append(probe)
	return {"elements":elements,"probes":probes,"failures":failures}

static func _collect(dungeon: Node2D,parent: Node,elements: Array[Dictionary],alpha_cache: Dictionary) -> void:
	for child in parent.get_children():
		if child is Polygon2D or child is Sprite2D or child is PointLight2D:
			var transform: Transform2D = dungeon.global_transform.affine_inverse()*child.global_transform
			var polygon := PackedVector2Array()
			var source := PackedVector2Array()
			var kind: String = child.get_meta("kind","heart")
			var texture: Texture2D
			var alpha_image: Image
			var native_mapping := true
			if child is Polygon2D:
				# Polygon2D.offset moves its vertices, independently of Node2D.position.
				polygon = child.polygon.duplicate()
				for i in range(polygon.size()):
					polygon[i] += child.offset
				source = child.uv
				texture = child.texture
				native_mapping = _native_mapping(child,polygon,source)
			elif child is Sprite2D:
				polygon = _rect_polygon(child.get_rect())
				texture = child.texture
				kind = child.get_meta("kind","effect")
				if kind != "effect" and texture != null:
					# Plain single-frame sprites have texture-space UVs, even when
					# uniformly scaled in the scene. Cache alpha once per inspection,
					# shared by both torches; normal gameplay never reads it back.
					source = _rect_polygon(Rect2(Vector2.ZERO,texture.get_size()))
					native_mapping = not child.region_enabled and child.hframes == 1 and child.vframes == 1 and not child.flip_h and not child.flip_v and is_equal_approx(child.scale.x,child.scale.y) and child.material == null
					if child.has_meta("source_region"):
						native_mapping = native_mapping and texture is AtlasTexture and texture.region == child.get_meta("source_region") and texture.atlas.resource_path == child.get_meta("source_path")
					if not alpha_cache.has(texture):
						alpha_cache[texture] = texture.get_image()
					alpha_image = alpha_cache[texture]
			else:
				texture = child.texture
				var size: Vector2 = texture.get_size()*child.texture_scale if texture != null else Vector2.ZERO
				polygon = _rect_polygon(Rect2(child.offset-size*0.5,size))
				kind = "light"
			var contour: PackedVector2Array = transform*polygon
			var z := _effective_z(child)
			var texture_path := texture.resource_path if texture != null else ""
			var source_region := Rect2(Vector2.ZERO,texture.get_size()) if texture != null else Rect2()
			if texture is AtlasTexture:
				texture_path = texture.atlas.resource_path
				source_region = texture.region
			elements.append({"id":str(dungeon.get_path_to(child)),"kind":kind,
				"anchor":transform.origin,"contour":contour,"bounds":_bounds(contour),
				"z":z,"visible":child.is_visible_in_tree(),"polygon":polygon,
				"native_mapping":native_mapping,"alpha_image":alpha_image,
				"uv":source,"transform":transform,"node":child,
				"texture":texture_path,"source_region":source_region,
				"tint":child.self_modulate})
		_collect(dungeon,child,elements,alpha_cache)

static func _native_mapping(part: Polygon2D,polygon: PackedVector2Array,uv: PackedVector2Array) -> bool:
	if polygon.size() < 3 or uv.size() != polygon.size():
		return false
	if part.texture_offset != Vector2.ZERO or part.texture_scale != Vector2.ONE or not is_zero_approx(part.texture_rotation):
		return false
	var translation := polygon[0]-uv[0]
	for i in range(polygon.size()):
		if not (polygon[i]-uv[i]).is_equal_approx(translation):
			return false
	return true

static func _effective_z(item: CanvasItem) -> int:
	var z := item.z_index
	var parent := item.get_parent() as CanvasItem
	if item.z_as_relative and parent != null:
		z += _effective_z(parent)
	return z

static func pick(elements: Array,point: Vector2,category: String = "all") -> Dictionary:
	var result := {}
	for element: Dictionary in elements:
		if not element.visible or (category != "all" and element.kind != category):
			continue
		# Lights/effect rectangles are selectable explicitly, never mask solid art.
		if category == "all" and element.kind in ["light","effect"]:
			continue
		if _contains(element,point):
			if result.is_empty() or element.z >= result.z:
				result = element
	return result

static func _contains(element: Dictionary,point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point,element.contour):
		return false
	var alpha_image: Image = element.get("alpha_image")
	if alpha_image == null:
		return true
	var uv := Vector2i(_uv_at(element,point).floor())
	if uv.x < 0 or uv.y < 0 or uv.x >= alpha_image.get_width() or uv.y >= alpha_image.get_height():
		return false
	# A faint halo must not intercept clicks or hide a wall/floor probe.
	return alpha_image.get_pixelv(uv).a >= 0.5

static func _at(elements: Array,point: Vector2,include_heart: bool) -> Dictionary:
	var solids: Array = elements.filter(func(e: Dictionary):
		return not e.uv.is_empty() and (include_heart or e.kind != "heart"))
	return pick(solids,point)

static func _uv_at(element: Dictionary,point: Vector2) -> Vector2:
	var local: Vector2 = element.transform.affine_inverse()*point
	return element.uv[0]+local-element.polygon[0]

static func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

static func _bounds(contour: PackedVector2Array) -> Rect2:
	if contour.is_empty():
		return Rect2()
	var bounds := Rect2(contour[0],Vector2.ZERO)
	for point in contour:
		bounds = bounds.expand(point)
	return bounds

static func report(snapshot: Dictionary) -> Dictionary:
	var elements: Array = []
	for element: Dictionary in snapshot.elements:
		elements.append({"id":element.id,"kind":element.kind,"anchor":_xy(element.anchor),
			"bounds":[element.bounds.position.x,element.bounds.position.y,element.bounds.size.x,element.bounds.size.y],
			"z":element.z,"visible":element.visible,"texture":element.texture,"native_mapping":element.native_mapping,
			"source_region":[element.source_region.position.x,element.source_region.position.y,element.source_region.size.x,element.source_region.size.y],
			"contour":_points(element.contour),"uv":_points(element.uv),
			"tint":[element.tint.r,element.tint.g,element.tint.b,element.tint.a]})
	var probes: Array = []
	for probe: Dictionary in snapshot.probes:
		var record: Dictionary = probe.duplicate(true)
		for key in ["position","expected_uv","actual_uv","actual_position"]:
			if record.has(key):
				record[key] = _xy(record[key])
		probes.append(record)
	return {"coordinate_space":"Dungeon local pixels","scope":"Spatial checks; GPU pixels tested separately",
		"elements":elements,"probes":probes,"failed_count":snapshot.failures.size()}

static func _xy(point: Vector2) -> Array:
	return [point.x,point.y]

static func _points(points: PackedVector2Array) -> Array:
	var result: Array = []
	for point in points:
		result.append(_xy(point))
	return result
