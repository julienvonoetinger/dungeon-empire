@tool
extends Node2D
## Places prepared atlas regions. Geometry/material rasterization stays offline.
const DEFINITION = preload("res://assets/dungeon/isometric-kit/catalog.tres")
const CATALOG_PATH := "res://assets/dungeon/isometric-kit/catalog.tres"
const ATLAS_PATH := "res://assets/dungeon/isometric-kit/atlas-256.png"
const LIGHT_FALLOFF_PATH := "res://assets/dungeon/mobile-kit/light-falloff.png"
const SURFACE_DETAILS = preload("res://scripts/dungeon_surface_details.gd")
const CELL := 256.0
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _definition: Resource
var _light_falloff: Texture2D
var _local_lights_enabled := true
var _world: Node2D
var _frame := Rect2(0, 0, 256, 256)
var _editor_filesystem: Object
var _watch_pending := false
var _stamp := ""


func _watch_assets() -> void:
	set_process(Engine.is_editor_hint())
	if not Engine.is_editor_hint() or is_instance_valid(_editor_filesystem):
		return
	if Engine.has_singleton("EditorInterface"):
		_editor_filesystem = Engine.get_singleton("EditorInterface").get_resource_filesystem()
		for event in ["resources_reimported", "resources_reload"]:
			_editor_filesystem.connect(event, _assets_changed)
		_editor_filesystem.connect("filesystem_changed", _filesystem_changed)
		_watch_pending = _stamp != _asset_stamp()


func _exit_tree() -> void:
	if is_instance_valid(_editor_filesystem):
		for event in ["resources_reimported", "resources_reload"]:
			if _editor_filesystem.is_connected(event, _assets_changed):
				_editor_filesystem.disconnect(event, _assets_changed)
		if _editor_filesystem.is_connected("filesystem_changed", _filesystem_changed):
			_editor_filesystem.disconnect("filesystem_changed", _filesystem_changed)
	_editor_filesystem = null


func _asset_stamp() -> String:
	return "%d/%d/%d" % [FileAccess.get_modified_time(CATALOG_PATH), FileAccess.get_modified_time(ATLAS_PATH), FileAccess.get_modified_time(LIGHT_FALLOFF_PATH)]


func _assets_changed(paths: PackedStringArray) -> void:
	for path in paths:
		if path.begins_with("res://assets/dungeon/isometric-kit/") or path == LIGHT_FALLOFF_PATH:
			_watch_pending = true


func _filesystem_changed() -> void:
	if _stamp != _asset_stamp():
		_watch_pending = true


func _import_busy() -> bool:
	return is_instance_valid(_editor_filesystem) and (_editor_filesystem.is_scanning() or _editor_filesystem.is_importing())


func _process(_delta: float) -> void:
	_watch_assets()
	if _watch_pending and not _import_busy():
		_watch_pending = false
		if has_method("refresh_preview"):
			call("refresh_preview")


func _load_definition(reload_textures: bool) -> bool:
	_watch_assets()
	if _import_busy():
		_watch_pending = true
		return false
	if _definition == null or reload_textures:
		var mode := ResourceLoader.CACHE_MODE_REPLACE if Engine.is_editor_hint() else ResourceLoader.CACHE_MODE_REUSE
		_definition = ResourceLoader.load(CATALOG_PATH, "Resource", mode)
		if _definition == null:
			push_error("Cannot load the prepared dungeon atlas.")
			return false
		# The atlas dependency and its subresource regions must belong to one export.
		var atlas := ResourceLoader.load(ATLAS_PATH, "Texture2D", mode) as Texture2D
		var textures: Dictionary = _definition.get("textures")
		for texture: AtlasTexture in textures.values():
			texture.atlas = atlas
		_light_falloff = ResourceLoader.load(LIGHT_FALLOFF_PATH, "Texture2D", mode) as Texture2D
		_stamp = _asset_stamp()
	return true


func grid_to_local(point: Vector2, height := 0.0) -> Vector2:
	var definition: Resource = _definition if _definition != null else DEFINITION
	var world := Vector3(point.x, point.y, height)
	var px: Vector3 = definition.get("projection_x")
	var py: Vector3 = definition.get("projection_y")
	return Vector2(world.dot(px), world.dot(py)) * CELL


func local_to_grid(point: Vector2, height := 0.0) -> Vector2:
	# Inverse ground-plane projection, for cell selection in the isometric view.
	var definition: Resource = _definition if _definition != null else DEFINITION
	var px: Vector3 = definition.get("projection_x")
	var py: Vector3 = definition.get("projection_y")
	var p := point / CELL - Vector2(px.z, py.z) * height
	var determinant := px.x * py.y - px.y * py.x
	return Vector2(p.x * py.y - p.y * px.y, p.y * px.x - p.x * py.x) / determinant


func _part(id: String, at: Vector2) -> Dictionary:
	var entries: Dictionary = _definition.get("entries")
	var entry: Dictionary = entries[id]
	var bounds: Dictionary = entry.bounds
	var lo := Vector3(bounds.min[0] + at.x, bounds.min[1] + at.y, bounds.min[2])
	var hi := Vector3(bounds.max[0] + at.x, bounds.max[1] + at.y, bounds.max[2])
	var view: Vector3 = _definition.get("view_direction")
	return {"id": id, "at": at, "min": lo, "max": hi,
		"depth": Vector2((lo.x + hi.x) * .5, (lo.y + hi.y) * .5).dot(Vector2(view.x, view.y)),
		"rect": Rect2(grid_to_local(at) + Vector2(entry.offset[0], entry.offset[1]), Vector2(entry.size[0], entry.size[1]))}


func _draw_part(part: Dictionary, layer: int) -> void:
	var textures: Dictionary = _definition.get("textures")
	var sprite := Sprite2D.new()
	sprite.name = part.id.replace("-", "_")
	sprite.texture = textures[part.id]
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = part.rect.position
	# Entries retain their logical frame when a soft effect uses fewer pixels.
	sprite.scale = part.rect.size / sprite.texture.get_size()
	sprite.z_index = layer
	_world.add_child(sprite)
	_frame = _frame.merge(part.rect)
	var entries: Dictionary = _definition.get("entries")
	var entry: Dictionary = entries[part.id]
	if entry.get("ground_effect", false):
		# The prepared alpha darkens the receiving floor, including lit floor.
		sprite.light_mask = 0
		if part.has("shadow_source"):
			sprite.set_meta("shadow_source", part.shadow_source)
	if entry.has("light"):
		# The complete painted flame/metal already includes its own warm shading.
		sprite.light_mask = 0
		if _local_lights_enabled and _light_falloff != null:
			var settings: Dictionary = entry.light
			var light := PointLight2D.new()
			light.name = str(sprite.name) + "_light"
			light.texture = _light_falloff
			light.texture_scale = float(settings.radius) * 2 / _light_falloff.get_width()
			light.position = grid_to_local(part.at) + Vector2(settings.emission[0], settings.emission[1])
			light.color = Color(settings.color[0], settings.color[1], settings.color[2])
			light.energy = settings.energy
			light.blend_mode = Light2D.BLEND_MODE_ADD
			light.shadow_enabled = false
			_world.add_child(light)


func _behind(a: Dictionary, b: Dictionary) -> bool:
	# Physical non-intersecting supports, including height: an arch sits above
	# both rails, while the leaf lies between them. Screen overlap is checked first.
	const EPS := 0.00001
	return a.max.x <= b.min.x + EPS or a.max.y <= b.min.y + EPS or a.max.z <= b.min.z + EPS


func _draw_surface_detail(host: Dictionary, layer: int, selected: Dictionary) -> void:
	var kind := SURFACE_DETAILS.surface(str(host.id))
	var id: String = selected.get(SURFACE_DETAILS.key(kind, Vector2i(host.at)), "")
	if id.is_empty() or not _definition.get("entries").has(id):
		return
	# Prepared in the host plane, drawn immediately after it in the same layer.
	# It receives the same lights; later solids and ground shadows cover it.
	_draw_part(_part(id, host.at), layer)


func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
	parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(a.depth, b.depth):
			return a.depth < b.depth
		return a.min.z < b.min.z)
	var incoming: Array[int] = []
	var links: Array[Array] = []
	for i in parts.size():
		incoming.append(0)
		links.append([])
	for i in parts.size():
		for j in range(i + 1, parts.size()):
			if not parts[i].rect.intersects(parts[j].rect):
				continue
			var ab := _behind(parts[i], parts[j])
			var ba := _behind(parts[j], parts[i])
			if ab == ba:
				continue
			var before := i if ab else j
			var after := j if ab else i
			links[before].append(after)
			incoming[after] += 1
	var result: Array[Dictionary] = []
	var remaining := parts.size()
	while remaining > 0:
		var pick := incoming.find(0)
		if pick == -1:
			# Deterministic support order for a geometrically ambiguous overlap.
			# Actual covered layouts are inspected in the scene capture review.
			for i in incoming.size():
				if incoming[i] >= 0:
					pick = i
					break
		incoming[pick] = -1
		result.append(parts[pick])
		for successor: int in links[pick]:
			if incoming[successor] > 0:
				incoming[successor] -= 1
		remaining -= 1
	return result


func _heart_fits_floor(part: Dictionary, cells: Dictionary, specials: Dictionary) -> bool:
	# The standalone prop has no floor plan. In a dungeon, the entire support
	# must sit on floor without sharing a door or stair cell.
	if cells.is_empty():
		return true
	var first := Vector2i(floori(part.min.x + .00001), floori(part.min.y + .00001))
	var last := Vector2i(floori(part.max.x - .00001), floori(part.max.y - .00001))
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			if not cells.has(cell) or specials.has(cell):
				return false
	return true


func _append_torches(parts: Array[Dictionary], plan: Dictionary, specials: Dictionary) -> void:
	var cells: Dictionary = plan.cells
	var openings: Dictionary = plan.openings
	var seen := {}
	for mounting in [["torch_north_cells", "torch-horizontal", Vector2i.UP, 1], ["torch_west_cells", "torch-vertical", Vector2i.LEFT, 8]]:
		for cell: Vector2i in plan.get(mounting[0], []):
			var key := "%s:%d:%d" % [mounting[1], cell.x, cell.y]
			if seen.has(key):
				continue
			seen[key] = true
			if not plan.get("standalone_props", false):
				if not cells.has(cell) or cells.has(cell + mounting[2]) or int(openings.get(cell, 0)) & int(mounting[3]) or specials.has(cell):
					push_warning("Torch requires a visible solid wall outside door/stair cells: " + key)
					continue
			parts.append(_part(mounting[1], Vector2(cell)))


func _shadow_light_path_clear(from: Vector2, to: Vector2, cells: Dictionary, specials: Dictionary) -> bool:
	if cells.is_empty():
		return true
	# Split the ground segment at every grid crossing. Short crossings through
	# void must not be missed by a fixed-step ray sample.
	var delta := to - from
	var cuts: Array[float] = [0.0, 1.0]
	for axis in range(2):
		if absf(delta[axis]) < .00001:
			continue
		for boundary in range(floori(minf(from[axis], to[axis])) + 1, ceili(maxf(from[axis], to[axis]))):
			var t := (float(boundary) - from[axis]) / delta[axis]
			if t > 0.0 and t < 1.0:
				cuts.append(t)
	cuts.sort()
	for i in range(cuts.size() - 1):
		var point := from + delta * ((cuts[i] + cuts[i + 1]) * .5)
		var cell := Vector2i(floori(point.x), floori(point.y))
		if not cells.has(cell) or specials.has(cell):
			return false
	return true


func _ground_shadow(part: Dictionary, parts: Array[Dictionary], cells: Dictionary, specials: Dictionary) -> Dictionary:
	var entries: Dictionary = _definition.get("entries")
	var entry: Dictionary = entries[part.id]
	var fallback_id: String = entry.get("ground_shadow", "")
	if fallback_id.is_empty() or not entries.has(fallback_id):
		return {}
	var fallback := _part(fallback_id, part.at)
	var result: Dictionary = fallback if _heart_fits_floor(fallback, cells, specials) else {}
	# Historical catalogues keep their single prepared effect. Modern fallback
	# contains contact only, so disabling lights cannot leave a fictitious cast.
	if not entry.has("ground_shadow_directions") or not _local_lights_enabled or _light_falloff == null:
		return result
	var best_distance := INF
	var source_key := ""
	var away := Vector2.ZERO
	for source in parts:
		var settings: Dictionary = entries[source.id].get("light", {})
		if not settings.has("emitter_world") or float(settings.get("energy", 0.0)) <= 0.0:
			continue
		var emitter: Array = settings.emitter_world
		var origin: Vector2 = source.at + Vector2(emitter[0], emitter[1])
		var emission := grid_to_local(origin, float(emitter[2]))
		if emission.distance_to(grid_to_local(part.at)) >= float(settings.get("radius", 0.0)):
			continue
		var delta: Vector2 = part.at - origin
		# Quantized distance gives a stable equivalence class for near ties,
		# independent of the order of the authored torch arrays.
		var distance := snappedf(delta.length_squared() + float(emitter[2]) * float(emitter[2]), .00001)
		if delta.length_squared() < .00001 or not _shadow_light_path_clear(origin, part.at, cells, specials):
			continue
		var key := "%s@%s" % [source.id, source.at]
		if distance < best_distance or (distance == best_distance and key < source_key):
			best_distance = distance
			source_key = key
			away = delta.normalized()
	if source_key.is_empty():
		return result
	# Compare projected directions, but never rotate an isometric sprite in 2D.
	# Ground contact stays anchored to the same frozen support in every variant.
	var target := grid_to_local(away).normalized()
	var best_alignment := -INF
	var selected := ""
	for candidate: Dictionary in entry.ground_shadow_directions:
		var direction := grid_to_local(Vector2(candidate.away[0], candidate.away[1])).normalized()
		var alignment := direction.dot(target)
		if alignment > best_alignment:
			best_alignment = alignment
			selected = candidate.id
	if not selected.is_empty() and entries.has(selected):
		var cast := _part(selected, part.at)
		if _heart_fits_floor(cast, cells, specials):
			cast["shadow_source"] = source_key
			result = cast
	return result


func render_plan(plan: Dictionary, specials: Dictionary, pillar_details: bool, reload_textures := true) -> void:
	if not _load_definition(reload_textures):
		return
	# An open editor can hot-reload the old renderer without calling _ready again.
	# Retire only its unowned generated direct children; keep authored scene nodes.
	for child in get_children():
		if child is Sprite2D and child.owner == null:
			for prefix in ["Floor_", "Walls_", "Entrance_", "Door_"]:
				if str(child.name).begins_with(prefix):
					remove_child(child)
					child.queue_free()
					break
	_world = get_node_or_null("PreparedSprites") as Node2D
	if _world == null:
		_world = Node2D.new()
		_world.name = "PreparedSprites"
		add_child(_world)
	for child in _world.get_children():
		_world.remove_child(child)
		child.queue_free()
	var cells: Dictionary = plan.cells
	_local_lights_enabled = bool(plan.get("torch_lights_enabled", true))
	_frame = Rect2()
	var openings: Dictionary = plan.openings
	var edges: Array[Dictionary] = []
	var floors: Array[Dictionary] = []
	var axes := {}
	var first := true
	for cell: Vector2i in cells:
		var floor_part := _part("floor", Vector2(cell))
		if first:
			_frame = floor_part.rect
			first = false
		floors.append(floor_part)
		for side in range(4):
			if cells.has(cell + DIRECTIONS[side]) or int(openings.get(cell, 0)) & (1 << side):
				continue
			var horizontal := side % 2 == 0
			var start := cell + (Vector2i.RIGHT if side == 1 else Vector2i.DOWN if side == 2 else Vector2i.ZERO)
			var end := start + (Vector2i.RIGHT if horizontal else Vector2i.DOWN)
			edges.append({"a": start, "b": end, "h": horizontal})
			for point: Vector2i in [start, end]:
				axes[point] = int(axes.get(point, 0)) | (1 if horizontal else 2)
	var parts: Array[Dictionary] = []
	for edge in edges:
		var bits := (1 if axes[edge.a] == 3 else 0) | (2 if axes[edge.b] == 3 else 0)
		parts.append(_part("wall-%s-%d" % ["h" if edge.h else "v", bits], Vector2(edge.a)))
	for point: Vector2i in axes:
		if axes[point] == 3:
			parts.append(_part("pillar", Vector2(point)))
	for cell: Vector2i in specials:
		var special: String = specials[cell]
		var direction := special.get_slice("/", 1)
		if special.begins_with("doors/"):
			var leaf_id := "door-%s-leaf" % direction
			parts.append(_part(leaf_id, Vector2(cell)))
			parts.append(_part("door-%s-arch" % direction, Vector2(cell)))
			# Additional prepared masonry uses the same physical support ordering.
			# Historical review catalogues omit companions and retain two parts.
			var entries: Dictionary = _definition.get("entries")
			for companion: String in entries[leaf_id].get("companions", []):
				parts.append(_part(companion, Vector2(cell)))
		else:
			parts.append(_part("stair-%s" % direction, Vector2(cell)))
	for at: Vector2 in plan.get("hearts", PackedVector2Array()):
		var heart := _part("heart", at)
		if _heart_fits_floor(heart, cells, specials):
			parts.append(heart)
	_append_torches(parts, plan, specials)
	var details := {}
	if bool(plan.get("surface_details", false)):
		var hosts: Array[Dictionary] = []
		hosts.append_array(floors)
		hosts.append_array(parts)
		details = SURFACE_DETAILS.select(hosts, parts, specials, int(plan.get("surface_detail_seed", 17)))
	for floor_part in floors:
		_draw_part(floor_part, 0)
		_draw_surface_detail(floor_part, 0, details)
	# Ground shadows follow all floor tiles and precede every solid object.
	# Historical catalogues have no shadow entry. Require actual floor beneath
	# the whole receiving area so a ground-only shadow cannot spill into void.
	for part in parts:
		var shadow := _ground_shadow(part, parts, cells, specials)
		if not shadow.is_empty():
			_draw_part(shadow, 0)
	for part in _ordered_parts(parts):
		_draw_part(part, 1)
		_draw_surface_detail(part, 1, details)
		if pillar_details and part.id == "pillar" and _definition.get("entries").has("pillar-top-carved"):
			_draw_part(_part("pillar-top-carved", part.at), 1)
	_frame = _frame.grow(24.0)


func get_content_rect() -> Rect2:
	return _frame


func get_cap_rect() -> Rect2:
	return _frame
