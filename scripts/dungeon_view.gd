@tool
class_name DungeonView
extends Node2D

## Floor, wall and corner sprites are unchanged crops of the approved reference.
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
const ENTRANCE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/dungeon/entrances/north.png"),
	preload("res://assets/dungeon/entrances/east.png"),
	preload("res://assets/dungeon/entrances/south.png"),
	preload("res://assets/dungeon/entrances/west.png"),
]
# Regions select the painted object without modifying the generated PNG alpha.
# Coordinates refer to original source images; import resizing is handled below.
const ENTRANCE_REGIONS: Array[Rect2] = [
	Rect2(289, 181, 797, 774), Rect2(195, 267, 366, 1538),
	Rect2(290, 226, 795, 732), Rect2(192, 274, 362, 1534),
]
const ENTRANCE_SOURCE_SIZES: Array[Vector2] = [
	Vector2(1374, 1145), Vector2(753, 2089),
	Vector2(1374, 1145), Vector2(754, 2086),
]

@export var layout: DungeonLayout:
	set(value):
		layout = value
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func get_content_rect() -> Rect2:
	if layout == null:
		return Rect2()
	var bounds := Rect2(Vector2.ZERO, layout.get_pixel_size())
	if layout.has_valid_entrance():
		bounds = bounds.merge(_get_entrance_rect())
	return bounds


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
	_draw_entrance()


func _cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell * layout.cell_size) + Vector2.ONE * layout.margin


func _draw_walls(cell: Vector2i) -> void:
	var origin := _cell_position(cell)
	if not layout.has_floor(cell + Vector2i.UP) and not layout.is_entrance_edge(cell, DungeonLayout.WallSide.NORTH):
		draw_texture(NORTH[cell.x % 2], origin + Vector2(0, -NORTH_HEIGHT))
	if not layout.has_floor(cell + Vector2i.DOWN) and not layout.is_entrance_edge(cell, DungeonLayout.WallSide.SOUTH):
		draw_texture(SOUTH[cell.x % 2], origin + Vector2(0, layout.cell_size))
	if not layout.has_floor(cell + Vector2i.LEFT) and not layout.is_entrance_edge(cell, DungeonLayout.WallSide.WEST):
		draw_texture(WEST, origin + Vector2(-WALL_WIDTH, 0))
	if not layout.has_floor(cell + Vector2i.RIGHT) and not layout.is_entrance_edge(cell, DungeonLayout.WallSide.EAST):
		draw_texture(EAST, origin + Vector2(layout.cell_size, 0))


func _draw_entrance() -> void:
	if not layout.has_valid_entrance():
		return
	var side := layout.entrance_side
	var tile := float(layout.cell_size)
	# Continue each adjacent floor tile into the wall gap to form the threshold.
	for cell in layout.get_entrance_cells():
		var origin := _cell_position(cell)
		var threshold: Rect2
		match side:
			DungeonLayout.WallSide.NORTH:
				threshold = Rect2(origin + Vector2(0, -NORTH_HEIGHT), Vector2(tile, NORTH_HEIGHT))
			DungeonLayout.WallSide.SOUTH:
				threshold = Rect2(origin + Vector2(0, tile), Vector2(tile, 50))
			DungeonLayout.WallSide.WEST:
				threshold = Rect2(origin + Vector2(-WALL_WIDTH, 0), Vector2(WALL_WIDTH, tile))
			DungeonLayout.WallSide.EAST:
				threshold = Rect2(origin + Vector2(tile, 0), Vector2(WALL_WIDTH, tile))
		draw_texture_rect(FLOORS[layout.get_floor_variant(cell)], threshold, false)
	var source := ENTRANCE_REGIONS[side]
	var texture := ENTRANCE_TEXTURES[side]
	var import_scale := Vector2(texture.get_size()) / ENTRANCE_SOURCE_SIZES[side]
	var region := Rect2(source.position * import_scale, source.size * import_scale)
	draw_texture_rect_region(texture, _get_entrance_rect(), region)


func _get_entrance_rect() -> Rect2:
	var side := layout.entrance_side
	var tile := float(layout.cell_size)
	var anchor := _cell_position(layout.entrance_cell)
	var source := ENTRANCE_REGIONS[side]
	var size: Vector2
	var position_in_map: Vector2
	if side in [DungeonLayout.WallSide.NORTH, DungeonLayout.WallSide.SOUTH]:
		size = Vector2(tile * 3, tile * 3 * source.size.y / source.size.x)
		var base_y := anchor.y + 18 if side == DungeonLayout.WallSide.NORTH else anchor.y + tile + 50
		position_in_map = Vector2(anchor.x - tile * 0.5, base_y - size.y)
	else:
		# Overhead side inserts: jamb caps at the two ends, door edge along the wall.
		size = Vector2(WALL_WIDTH, tile * 3)
		var center_x := anchor.x - WALL_WIDTH * 0.5 if side == DungeonLayout.WallSide.WEST else anchor.x + tile + WALL_WIDTH * 0.5
		position_in_map = Vector2(center_x - size.x * 0.5, anchor.y - tile * 0.5)
	return Rect2(position_in_map, size)


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
