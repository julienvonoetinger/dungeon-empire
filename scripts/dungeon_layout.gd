@tool
class_name DungeonLayout
extends Resource

## Fixed floor map. Dots are empty; digits select one of the eight floor sprites.
@export var cell_size: int = 54
@export var margin: int = 90
@export var rows: PackedStringArray = []


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
