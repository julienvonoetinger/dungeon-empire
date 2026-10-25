@tool
extends "res://scripts/mobile_dungeon_renderer.gd"

## Prepared isometric wireframes. Runtime selects images and places them on the grid.
signal rebuilt

const DOOR_VARIANTS := {"north":"w10_p00_e00", "south":"w10_p00_e00", "east":"w05_p00_e00", "west":"w05_p00_e00"}
const TERMINAL_DIRECTIONS := {"w14_p00_e00":"north", "w13_p00_e00":"east", "w11_p00_e00":"south", "w07_p00_e00":"west"}
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
## Ground centres in cell units. Whole supports must remain on floor, outside doors/stairs.
@export var heart_positions := PackedVector2Array():
	set(value):
		heart_positions = value
		_request_rebuild()
## Cells whose north/west boundary is a solid wall. Other faces need separate art.
@export var torch_north_cells: Array[Vector2i] = []:
	set(value):
		torch_north_cells = value
		_request_rebuild()
@export var torch_west_cells: Array[Vector2i] = []:
	set(value):
		torch_west_cells = value
		_request_rebuild()
@export var torch_lights_enabled := true:
	set(value):
		torch_lights_enabled = value
		_request_rebuild()
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")

@export var pillar_details := true:
	set(value):
		pillar_details = value
		_request_rebuild()

## Optional selected wall families, explicitly enabled by production layouts.
@export var wall_variants := false:
	set(value):
		wall_variants = value
		_request_rebuild()
@export var wall_variant_seed := 17:
	set(value):
		wall_variant_seed = value
		_request_rebuild()
@export var wall_corruption := true:
	set(value):
		wall_corruption = value
		_request_rebuild()

var _plan: Dictionary = {}
var _pending := false

func _ready() -> void:
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
	_plan = GRID.build(layout, open_axis, connections, corridor_length,
		vertical_corridor_length, horizontal_attachment_rows,
		vertical_attachment_columns, close_corridor_ends)
	var cells: Dictionary = _plan.cells
	var specials: Dictionary = {}
	for cell: Vector2i in door_cells:
		var facing: String = door_cells[cell]
		if not cells.has(cell) or not DOOR_VARIANTS.has(facing):
			push_warning("Invalid door placement: %s at %s" % [facing, cell])
			continue
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if variant != DOOR_VARIANTS[facing]:
			push_warning("Door %s requires a connected straight passage at %s; found %s" % [facing, cell, variant])
			continue
		specials[cell] = "doors/" + facing
	for cell: Vector2i in cells:
		var variant: String = GRID.variant(cell, cells, _plan.openings)
		if not specials.has(cell) and entrance_at_closed_ends and TERMINAL_DIRECTIONS.has(variant):
			specials[cell] = "entrances/" + TERMINAL_DIRECTIONS[variant]
	_plan["specials"] = specials
	_plan["hearts"] = heart_positions
	_plan["torch_north_cells"] = torch_north_cells
	_plan["torch_west_cells"] = torch_west_cells
	_plan["torch_lights_enabled"] = torch_lights_enabled
	_plan["wall_variants"] = wall_variants
	_plan["wall_variant_seed"] = wall_variant_seed
	_plan["wall_corruption"] = wall_corruption
	render_plan(_plan, specials, pillar_details, reload_textures)
	rebuilt.emit()

func get_connection_plan() -> Dictionary:
	return _plan
