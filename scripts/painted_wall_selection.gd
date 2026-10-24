extends RefCounted

## Select a finished PNG style; never generate or alter image pixels in Godot.
static func _cell_hash(cell: Vector2i) -> int:
	var value: int = (cell.x * 92837111 ^ cell.y * 689287499 ^ 1597334677) & 0x7fffffff
	return ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff


static func style_for(cell: Vector2i) -> int:
	var value := _cell_hash(cell)
	var bucket := value % 16
	if bucket == 0:
		# Only the lowest-hash neighbouring candidate keeps its D2 accent.
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbour := cell + Vector2i(dx, dy)
				var other := _cell_hash(neighbour)
				if other % 16 == 0 and (other < value or (other == value and (dy < 0 or (dy == 0 and dx < 0)))):
					return 0
		return 3
	if bucket < 4:
		return 2
	if bucket < 8:
		return 1
	return 0
