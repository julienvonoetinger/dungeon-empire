@tool
extends Node2D

## Prepared painted PNGs. Runtime only selects images and places them on the grid.
signal rebuilt

const KIT = preload("res://scripts/painted_cell_catalog.gd")
const GRID = preload("res://scripts/wireframe_cell_layout.gd")

@export var layout: DungeonLayout:
	set(value):
		if layout and layout.changed.is_connected(_request_rebuild):
			layout.changed.disconnect(_request_rebuild)
		layout = value
		if layout:
			layout.changed.connect(_request_rebuild)
		_request_rebuild()
@export_enum("Closed room", "North–south passage", "West–east passage") var open_axis: int = 0:
	set(value):
		open_axis = value
		_request_rebuild()
@export_flags("North", "East", "South", "West") var connections: int = 0:
	set(value):
		connections = value
		_request_rebuild()
@export_range(1, 8, 1) var corridor_length: int = 2:
	set(value):
		corridor_length = maxi(1, value)
		_request_rebuild()
@export_range(0, 8, 1) var vertical_corridor_length: int = 0:
	set(value):
		vertical_corridor_length = maxi(0, value)
		_request_rebuild()
@export var horizontal_attachment_rows := PackedInt32Array():
	set(value):
		horizontal_attachment_rows = value
		_request_rebuild()
@export var vertical_attachment_columns := PackedInt32Array():
	set(value):
		vertical_attachment_columns = value
		_request_rebuild()
@export var close_corridor_ends: bool = false:
	set(value):
		close_corridor_ends = value
		_request_rebuild()
@export var entrance_at_closed_ends: bool = false:
	set(value):
		entrance_at_closed_ends = value
		_request_rebuild()
## Logical cell -> door front direction: north/east/south/west. Straight passages only.
@export var door_cells: Dictionary[Vector2i, String] = {}:
	set(value):
		door_cells = value
		_request_rebuild()
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")

var _pieces: Array[Sprite2D] = []
var _plan: Dictionary = {}
var _frame := Rect2(0, 0, 256, 256)
var _pending := false
var _reload_editor_textures := false
var _refreshed_textures: Dictionary[String, Texture2D] = {}
var _missing_contexts: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	refresh_preview()


func _request_rebuild() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	call_deferred("refresh_preview", false)


func refresh_preview(reload_textures: bool = true) -> void:
	_pending = false
	if not is_inside_tree():
		return
	# A separate import process can update .ctex files while this editor still
	# holds older preloaded textures. Manual refresh must also refresh that cache.
	_reload_editor_textures = Engine.is_editor_hint() and reload_textures
	_refreshed_textures.clear()
	for sprite in _pieces:
		if is_instance_valid(sprite):
			remove_child(sprite)
			sprite.queue_free()
	_pieces.clear()
	_plan = GRID.build(layout, open_axis, connections, corridor_length,
		vertical_corridor_length, horizontal_attachment_rows,
		vertical_attachment_columns, close_corridor_ends)
	var cells: Dictionary = _plan.cells
	var ordered: Array = cells.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y if a.y != b.y else a.x < b.x)
	var specials: Dictionary = {}
	for cell: Vector2i in door_cells:
		var facing: String = door_cells[cell]
		if not cells.has(cell) or not KIT.DOOR_VARIANTS.has(facing):
			push_warning("Invalid door placement: %s at %s" % [facing, cell])
			continue
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if variant != KIT.DOOR_VARIANTS[facing]:
			push_warning("Door %s requires a connected straight passage at %s; found %s" % [facing, cell, variant])
			continue
		specials[cell] = "doors/" + facing
	for cell: Vector2i in ordered:
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if not specials.has(cell) and entrance_at_closed_ends and KIT.TERMINAL_DIRECTIONS.has(variant):
			specials[cell] = "entrances/" + KIT.TERMINAL_DIRECTIONS[variant]
	var prepared_images: Dictionary = {}
	var loaded_paths: Dictionary = {}
	for cell: Vector2i in ordered:
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if not specials.has(cell) and KIT.EMPTY_VARIANTS.has(variant):
			continue
		var context: String = GRID.context_key(cell, cells, _plan.openings, specials)
		var image_path: String = KIT.CONTEXT_PATHS.get(context, "")
		if not KIT.CONTEXT_PATHS.has(context):
			# Authoring a new special adjacency needs an offline export. Keep a
			# prepared generic image visible, and explicitly flag the missing join.
			var fallback: String = specials.get(cell, "cells/" + variant)
			image_path = KIT.FALLBACK_PATHS.get(fallback, "")
			if not _missing_contexts.has(context):
				push_warning("Prepared stone context missing at %s: %s. Export scene contexts and PNGs before reviewing this join." % [cell, context])
				_missing_contexts[context] = true
		if image_path.is_empty():
			push_error("Missing prepared painted cell image: %s at %s" % [variant, cell])
			continue
		if not loaded_paths.has(image_path):
			loaded_paths[image_path] = ResourceLoader.load(image_path, "Texture2D") as Texture2D
		if loaded_paths[image_path] == null:
			push_error("Could not load prepared painted cell: %s" % image_path)
			continue
		prepared_images[cell] = loaded_paths[image_path]
	var first := true
	for cell: Vector2i in ordered:
		var position_on_grid := Vector2(cell) * KIT.CELL_PIXELS
		var tile_bounds := Rect2(position_on_grid - KIT.WALL_ANCHOR, Vector2(304, 352))
		if str(specials.get(cell, "")).begins_with("doors/") and prepared_images.has(cell):
			var texture: Texture2D = prepared_images[cell]
			tile_bounds = Rect2(position_on_grid - KIT.DOOR_ANCHOR, texture.get_size() * KIT.TEXTURE_SCALE)
		_frame = tile_bounds if first else _frame.merge(tile_bounds)
		first = false
		_add_sprite(KIT.FLOOR, position_on_grid - KIT.FLOOR_ANCHOR, 0, "Floor_%d_%d" % [cell.x, cell.y])
	for cell: Vector2i in ordered:
		if not prepared_images.has(cell):
			continue
		var special: String = specials.get(cell, "")
		var is_door := special.begins_with("doors/")
		var anchor: Vector2 = KIT.DOOR_ANCHOR if is_door else KIT.WALL_ANCHOR
		var prefix := "Door" if is_door else ("Entrance" if not special.is_empty() else "Walls")
		var label: String = door_cells[cell] if is_door else GRID.variant(cell, cells, _plan.openings)
		_add_sprite(prepared_images[cell], Vector2(cell) * KIT.CELL_PIXELS - anchor,
			1, "%s_%d_%d_%s" % [prefix, cell.x, cell.y, label])
	if first:
		_frame = Rect2(0, 0, KIT.CELL_PIXELS, KIT.CELL_PIXELS)
	_frame = _frame.grow(24.0)
	_reload_editor_textures = false
	_refreshed_textures.clear()
	rebuilt.emit()


func _add_sprite(texture: Texture2D, at: Vector2, layer: int, label: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = label
	sprite.texture = _texture_for_preview(texture)
	sprite.centered = false
	sprite.position = at
	sprite.scale = Vector2.ONE * KIT.TEXTURE_SCALE
	sprite.z_index = layer
	add_child(sprite)
	_pieces.append(sprite)


func _texture_for_preview(texture: Texture2D) -> Texture2D:
	if not _reload_editor_textures or texture.resource_path.is_empty():
		return texture
	var path := texture.resource_path
	if not _refreshed_textures.has(path):
		# Each shared image is read only once per refresh, regardless of cell count.
		var refreshed := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE) as Texture2D
		if refreshed == null:
			push_warning("Could not reload preview texture: %s" % path)
		_refreshed_textures[path] = refreshed if refreshed != null else texture
	return _refreshed_textures[path]


func get_content_rect() -> Rect2:
	return _frame


func get_cap_rect() -> Rect2:
	return _frame


func get_connection_plan() -> Dictionary:
	return _plan
