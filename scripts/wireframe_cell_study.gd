@tool
extends Node2D

## Complete cell textures. Runtime only selects an image and places it on the grid.
signal rebuilt

const KIT = preload("res://scripts/wireframe_cell_catalog.gd")
const GRID = preload("res://scripts/wireframe_cell_layout.gd")
const ENTRANCES = preload("res://scripts/wireframe_entrance_catalog.gd")

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
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")

var _pieces: Array[Sprite2D] = []
var _plan: Dictionary = {}
var _frame := Rect2(0, 0, 256, 256)
var _pending := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	refresh_preview()


func _request_rebuild() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	call_deferred("refresh_preview")


func refresh_preview() -> void:
	_pending = false
	if not is_inside_tree():
		return
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
	var first := true
	for cell: Vector2i in ordered:
		var position_on_grid := Vector2(cell) * KIT.CELL_PIXELS
		var tile_bounds := Rect2(position_on_grid - KIT.WALL_ANCHOR, Vector2(304, 352))
		_frame = tile_bounds if first else _frame.merge(tile_bounds)
		first = false
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if not (entrance_at_closed_ends and ENTRANCES.TERMINALS.has(variant)):
			_add_sprite(KIT.FLOOR, position_on_grid - KIT.FLOOR_ANCHOR, 0, "Floor_%d_%d" % [cell.x, cell.y])
	for cell: Vector2i in ordered:
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if entrance_at_closed_ends and ENTRANCES.TERMINALS.has(variant):
			_add_sprite(ENTRANCES.TERMINALS[variant], Vector2(cell) * KIT.CELL_PIXELS - ENTRANCES.ANCHOR,
				1, "Entrance_%d_%d_%s" % [cell.x, cell.y, variant])
		elif KIT.WALLS.has(variant):
			_add_sprite(KIT.WALLS[variant], Vector2(cell) * KIT.CELL_PIXELS - KIT.WALL_ANCHOR,
				1, "Walls_%d_%d_%s" % [cell.x, cell.y, variant])
		elif not KIT.EMPTY_VARIANTS.has(variant):
			push_error("Missing prepared wireframe cell image: %s at %s" % [variant, cell])
	if first:
		_frame = Rect2(0, 0, KIT.CELL_PIXELS, KIT.CELL_PIXELS)
	_frame = _frame.grow(24.0)
	rebuilt.emit()


func _add_sprite(texture: Texture2D, at: Vector2, layer: int, label: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = label
	sprite.texture = texture
	sprite.centered = false
	sprite.position = at
	sprite.z_index = layer
	add_child(sprite)
	_pieces.append(sprite)


func get_content_rect() -> Rect2:
	return _frame


func get_cap_rect() -> Rect2:
	return _frame


func get_connection_plan() -> Dictionary:
	return _plan
