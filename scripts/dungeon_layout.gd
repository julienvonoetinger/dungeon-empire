@tool
class_name DungeonLayout
extends Resource

enum WallSide { NORTH, EAST, SOUTH, WEST }
const OUTWARD: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## Fixed logical map. Dots are empty; legacy digits 0–7 all mark occupied cells.
## The mobile renderer uses one common prepared floor, independent of the digit.
@export var cell_size: int = 54
@export var margin: int = 90
@export var rows: PackedStringArray = []
@export_group("Entrance")
@export var entrance_enabled: bool = false
@export var entrance_cell: Vector2i = Vector2i(3, 3)
@export var entrance_side: WallSide = WallSide.NORTH


func get_entrance_cells() -> Array[Vector2i]:
	var along := Vector2i.RIGHT if entrance_side in [WallSide.NORTH, WallSide.SOUTH] else Vector2i.DOWN
	return [entrance_cell, entrance_cell + along]


func has_valid_entrance() -> bool:
	if not entrance_enabled or entrance_side < 0 or entrance_side >= OUTWARD.size():
		return false
	var along := Vector2i.RIGHT if entrance_side in [WallSide.NORTH, WallSide.SOUTH] else Vector2i.DOWN
	# Require two floor cells and a straight wall on either side of the frame.
	for offset in range(-1, 3):
		var cell := entrance_cell + along * offset
		if not has_floor(cell) or has_floor(cell + OUTWARD[entrance_side]):
			return false
	return true


func is_entrance_edge(cell: Vector2i, side: WallSide) -> bool:
	return has_valid_entrance() and side == entrance_side and cell in get_entrance_cells()


func get_grid_size() -> Vector2i:
	return Vector2i(rows[0].length() if not rows.is_empty() else 0, rows.size())


func has_floor(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= rows.size():
		return false
	if cell.x < 0 or cell.x >= rows[cell.y].length():
		return false
	return rows[cell.y][cell.x] in "01234567"


func get_floor_variant(cell: Vector2i) -> int:
	return rows[cell.y][cell.x].to_int() if has_floor(cell) else -1


func get_floor_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var cell := Vector2i(x, y)
			if has_floor(cell):
				cells.append(cell)
	return cells


func get_pixel_size() -> Vector2:
	return Vector2(get_grid_size() * cell_size) + Vector2.ONE * margin * 2
