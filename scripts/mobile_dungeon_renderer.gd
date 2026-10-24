@tool
extends Node2D
## Places prepared atlas regions. Geometry/material rasterization stays offline.
const DEFINITION = preload("res://assets/dungeon/mobile-kit/catalog.tres")
const CATALOG_PATH := "res://assets/dungeon/mobile-kit/catalog.tres"
const ATLAS_PATH := "res://assets/dungeon/mobile-kit/atlas-256.png"
const CELL := 256.0
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var _definition: Resource
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
	return "%d/%d" % [FileAccess.get_modified_time(CATALOG_PATH), FileAccess.get_modified_time(ATLAS_PATH)]


func _assets_changed(paths: PackedStringArray) -> void:
	for path in paths:
		if path.begins_with("res://assets/dungeon/mobile-kit/"):
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
			push_error("Cannot load the prepared mobile atlas.")
			return false
		# The atlas dependency and its subresource regions must belong to one export.
		var atlas := ResourceLoader.load(ATLAS_PATH, "Texture2D", mode) as Texture2D
		var textures: Dictionary = _definition.get("textures")
		for texture: AtlasTexture in textures.values():
			texture.atlas = atlas
		_stamp = _asset_stamp()
	return true


func _part(id: String, at: Vector2) -> Dictionary:
	var entries: Dictionary = _definition.get("entries")
	var entry: Dictionary = entries[id]
	var bounds: Dictionary = entry.bounds
	var lo := Vector3(bounds.min[0] + at.x, bounds.min[1] + at.y, bounds.min[2])
	var hi := Vector3(bounds.max[0] + at.x, bounds.max[1] + at.y, bounds.max[2])
	return {"id": id, "at": at, "min": lo, "max": hi,
		"depth": Vector2((lo.x + hi.x) * .5, (lo.y + hi.y) * .5).dot(Vector2(.18, .9)),
		"rect": Rect2(at * CELL + Vector2(entry.offset[0], entry.offset[1]), Vector2(entry.size[0], entry.size[1]))}


func _draw_part(part: Dictionary, layer: int) -> void:
	var textures: Dictionary = _definition.get("textures")
	var sprite := Sprite2D.new()
	sprite.name = part.id.replace("-", "_")
	sprite.texture = textures[part.id]
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = part.rect.position
	sprite.z_index = layer
	_world.add_child(sprite)
	_frame = _frame.merge(part.rect)


func _behind(a: Dictionary, b: Dictionary) -> bool:
	# Physical non-intersecting supports, including height: an arch sits above
	# both rails, while the leaf lies between them. Screen overlap is checked first.
	const EPS := 0.00001
	return a.max.x <= b.min.x + EPS or a.max.y <= b.min.y + EPS or a.max.z <= b.min.z + EPS


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
	_frame = Rect2()
	var openings: Dictionary = plan.openings
	var edges: Array[Dictionary] = []
	var axes := {}
	var first := true
	for cell: Vector2i in cells:
		var floor_part := _part("floor", Vector2(cell))
		if first:
			_frame = floor_part.rect
			first = false
		_draw_part(floor_part, 0)
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
	for part in _ordered_parts(parts):
		_draw_part(part, 1)
		if pillar_details and part.id == "pillar":
			_draw_part(_part("pillar-top-carved", part.at), 1)
	_frame = _frame.grow(24.0)


func get_content_rect() -> Rect2:
	return _frame


func get_cap_rect() -> Rect2:
	return _frame
