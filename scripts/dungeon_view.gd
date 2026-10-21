@tool
class_name DungeonView
extends Node2D

## Sprites are the unchanged crops used to assemble the approved reference.
const FLOORS: Array[Texture2D] = [
	preload("res://assets/dungeon/floor_0.png"),
	preload("res://assets/dungeon/floor_1.png"),
	preload("res://assets/dungeon/floor_2.png"),
	preload("res://assets/dungeon/floor_3.png"),
	preload("res://assets/dungeon/floor_4.png"),
	preload("res://assets/dungeon/floor_5.png"),
	preload("res://assets/dungeon/floor_6.png"),
	preload("res://assets/dungeon/floor_7.png"),
]
const NORTH: Array[Texture2D] = [
	preload("res://assets/dungeon/wall_north_0.png"),
	preload("res://assets/dungeon/wall_north_1.png"),
]
const SOUTH: Array[Texture2D] = [
	preload("res://assets/dungeon/wall_south_0.png"),
	preload("res://assets/dungeon/wall_south_1.png"),
]
const WEST := preload("res://assets/dungeon/wall_west.png")
const EAST := preload("res://assets/dungeon/wall_east.png")
const PILLAR := preload("res://assets/dungeon/corner_pillar.png")
const INNER_CORNERS: Array[Texture2D] = [
	preload("res://assets/dungeon/corner_inner_nw.png"),
	preload("res://assets/dungeon/corner_inner_ne.png"),
	preload("res://assets/dungeon/corner_inner_sw.png"),
	preload("res://assets/dungeon/corner_inner_se.png"),
]
const BACKDROP := preload("res://assets/dungeon/backdrop.png")
const WALL_WIDTH := 52
const NORTH_HEIGHT := 44

@export var layout: DungeonLayout:
	set(value):
		layout = value
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func get_content_rect() -> Rect2:
	return Rect2(Vector2.ZERO, layout.get_pixel_size()) if layout else Rect2()


func _draw() -> void:
	if layout == null:
		return
	draw_texture_rect(BACKDROP, get_content_rect(), false)
	var cells := layout.get_floor_cells()
	for cell in cells:
		_draw_walls(cell)
	_draw_corners()
	# The opaque floors mask any overhanging wall pixels at tight junctions.
	# This preserves every corridor's full width, as in the approved assembly.
	for cell in cells:
		draw_texture(FLOORS[layout.get_floor_variant(cell)], _cell_position(cell))


func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell * layout.cell_size) + Vector2.ONE * layout.margin


func _draw_walls(cell: Vector2i) -> void:
	var origin := _cell_position(cell)
	if not layout.has_floor(cell + Vector2i.UP):
		draw_texture(NORTH[cell.x % 2], origin + Vector2(0, -NORTH_HEIGHT))
	if not layout.has_floor(cell + Vector2i.DOWN):
		draw_texture(SOUTH[cell.x % 2], origin + Vector2(0, layout.cell_size))
	if not layout.has_floor(cell + Vector2i.LEFT):
		draw_texture(WEST, origin + Vector2(-WALL_WIDTH, 0))
	if not layout.has_floor(cell + Vector2i.RIGHT):
		draw_texture(EAST, origin + Vector2(layout.cell_size, 0))


func _draw_corners() -> void:
	var grid := layout.get_grid_size()
	# Quadrant order: northwest, northeast, southwest, southeast.
	var outer_offsets: Array[Vector2] = [
		Vector2.ZERO, Vector2(-WALL_WIDTH, 0),
		Vector2(0, -NORTH_HEIGHT), Vector2(-WALL_WIDTH, -NORTH_HEIGHT),
	]
	var inner_offsets: Array[Vector2] = [
		Vector2(-WALL_WIDTH, -NORTH_HEIGHT), Vector2(0, -NORTH_HEIGHT),
		Vector2(-WALL_WIDTH, 0), Vector2.ZERO,
	]
	for y in range(grid.y + 1):
		for x in range(grid.x + 1):
			var vertex := Vector2i(x, y)
			var occupied: Array[bool] = [
				layout.has_floor(vertex + Vector2i(-1, -1)),
				layout.has_floor(vertex + Vector2i(0, -1)),
				layout.has_floor(vertex + Vector2i(-1, 0)),
				layout.has_floor(vertex),
			]
			var count := occupied.count(true)
			var origin := _cell_position(vertex)
			if count == 1:
				draw_texture(PILLAR, origin + outer_offsets[occupied.find(true)])
			elif count == 3:
				var empty := occupied.find(false)
				draw_texture(INNER_CORNERS[empty], origin + inner_offsets[empty])
