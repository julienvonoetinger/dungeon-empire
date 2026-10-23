extends RefCounted

## Only logical grid rules; no stone lengths, pixel fitting or scene-specific joins.
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const CORNER_SIDES := [[3, 0], [0, 1], [1, 2], [2, 3]] # NW NE SE SW
const DIAGONALS := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]


static func context_key(cell: Vector2i, cells: Dictionary, openings: Dictionary,

		specials: Dictionary) -> String:
	var mask := 0
	var offsets: Array = DIRECTIONS + DIAGONALS
	for index in range(8):
		if cells.has(cell + offsets[index]):
			mask |= 1 << index
	var ends := int(openings.get(cell, 0)) & (15 ^ (mask & 15))
	var result := "n%03d_e%02d" % [mask, ends]
	var neighbourhood: Array = [Vector2i.ZERO] + offsets
	for index in range(neighbourhood.size()):
		var at: Vector2i = cell + neighbourhood[index]
		if specials.has(at):
			result += "|%d=%s" % [index, specials[at]]
	return result


static func attachment_indices(requested: PackedInt32Array, count: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	if requested.is_empty():
		result.append(count / 2)
	else:
		for index in requested:
			if index >= 0 and index < count and not result.has(index):
				result.append(index)
	result.sort()
	return result


static func build(layout: DungeonLayout, open_axis: int, connections: int,
		length: int, vertical_length: int, rows: PackedInt32Array,
		columns: PackedInt32Array, close_ends: bool) -> Dictionary:
	var cells: Dictionary = {}
	var source: Array[Vector2i] = layout.get_floor_cells() if layout else [Vector2i.ZERO]
	for cell in source:
		cells[cell] = true
	var dimensions := layout.get_grid_size() if layout else Vector2i.ONE
	var openings: Dictionary = {}
	if connections == 0:
		for cell: Vector2i in cells:
			if open_axis == 1:
				if cell.y == 0:
					add_opening(openings, cell, 1)
				if cell.y == dimensions.y - 1:
					add_opening(openings, cell, 4)
			elif open_axis == 2:
				if cell.x == 0:
					add_opening(openings, cell, 8)
				if cell.x == dimensions.x - 1:
					add_opening(openings, cell, 2)
	else:
		var horizontal := maxi(1, length)
		var vertical := vertical_length if vertical_length > 0 else horizontal
		for row in attachment_indices(rows, dimensions.y):
			for side in [1, 3]:
				if not (connections & (1 << side)):
					continue
				var root := Vector2i(dimensions.x - 1 if side == 1 else 0, row)
				if not cells.has(root):
					continue
				for index in range(1, horizontal + 1):
					cells[root + DIRECTIONS[side] * index] = true
				if not close_ends:
					add_opening(openings, root + DIRECTIONS[side] * horizontal, 1 << side)
		for column in attachment_indices(columns, dimensions.x):
			for side in [0, 2]:
				if not (connections & (1 << side)):
					continue
				var root := Vector2i(column, 0 if side == 0 else dimensions.y - 1)
				if not cells.has(root):
					continue
				for index in range(1, vertical + 1):
					cells[root + DIRECTIONS[side] * index] = true
				if not close_ends:
					add_opening(openings, root + DIRECTIONS[side] * vertical, 1 << side)
	return {"cells": cells, "openings": openings}


static func add_opening(openings: Dictionary, cell: Vector2i, bit: int) -> void:
	openings[cell] = int(openings.get(cell, 0)) | bit


static func variant(cell: Vector2i, cells: Dictionary, openings: Dictionary) -> String:
	var neighbours := 0
	for side in range(4):
		if cells.has(cell + DIRECTIONS[side]):
			neighbours |= 1 << side
	var ends := int(openings.get(cell, 0)) & (15 ^ neighbours)
	var walls := 15 ^ (neighbours | ends)
	var piers := 0
	for corner in range(4):
		var a: int = CORNER_SIDES[corner][0]
		var b: int = CORNER_SIDES[corner][1]
		if neighbours & (1 << a) and neighbours & (1 << b):
			if not cells.has(cell + DIRECTIONS[a] + DIRECTIONS[b]):
				piers |= 1 << corner
	return "w%02d_p%02d_e%02d" % [walls, piers, ends]
