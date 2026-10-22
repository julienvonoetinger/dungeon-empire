extends RefCounted

## Logical occupancy -> exposed edges -> runs and oriented turns.
## Rendering ports are independent of scene names and authored world positions.
const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
const WALL_PROFILE := preload("res://scripts/modular_wall_profile.gd")
const STEP := WALL_PROFILE.CELL_PITCH

static func build(size: Vector2i, length: int, connections: int, vertical_length: int = 0,
		horizontal_rows: PackedInt32Array = PackedInt32Array(),
		vertical_columns: PackedInt32Array = PackedInt32Array()) -> Dictionary:
	var vertical := vertical_length if vertical_length > 0 else length
	var cells: Dictionary = {}
	for y in range(size.y):
		for x in range(size.x):
			cells[Vector2i(x, y)] = true
	var attachment_rows := _attachment_indices(horizontal_rows,size.y)
	var attachment_columns := _attachment_indices(vertical_columns,size.x)
	var open_edges: Dictionary = {}
	for index in range(1, length + 1):
		for row in attachment_rows:
			if connections & WEST:
				cells[Vector2i(-index, row)] = true
			if connections & EAST:
				cells[Vector2i(size.x + index - 1, row)] = true
	for index in range(1, vertical + 1):
		for column in attachment_columns:
			if connections & NORTH:
				cells[Vector2i(column, -index)] = true
			if connections & SOUTH:
				cells[Vector2i(column, size.y + index - 1)] = true
	for column in attachment_columns:
		if connections & NORTH:
			open_edges[_edge_key(Vector2i(column, -vertical), NORTH)] = true
		if connections & SOUTH:
			open_edges[_edge_key(Vector2i(column, size.y + vertical - 1), SOUTH)] = true
	for row in attachment_rows:
		if connections & WEST:
			open_edges[_edge_key(Vector2i(-length, row), WEST)] = true
		if connections & EAST:
			open_edges[_edge_key(Vector2i(size.x + length - 1, row), EAST)] = true
	var effective_connections := connections
	if attachment_rows.is_empty():
		effective_connections &= ~(WEST | EAST)
	if attachment_columns.is_empty():
		effective_connections &= ~(NORTH | SOUTH)
	var result := from_cells(cells, open_edges, size, length, effective_connections)
	result["vertical_length"] = vertical
	result["horizontal_rows"] = attachment_rows
	result["vertical_columns"] = attachment_columns
	return result

static func _attachment_indices(requested: PackedInt32Array, size: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	if requested.is_empty():
		result.append(size / 2)
	else:
		for index in requested:
			if index >= 0 and index < size and not result.has(index):
				result.append(index)
		result.sort()
	return result

static func from_cells(cells: Dictionary, open_edges: Dictionary, size: Vector2i,
		length: int = 0, connections: int = 0) -> Dictionary:
	# Pure boundary resolver can be reused by a future player construction tool.
	# Current scene paving supports the central rectangle/cardinal connectors.
	var edges: Array[Dictionary] = []
	var adjacency: Dictionary = {}
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var sides := [NORTH, EAST, SOUTH, WEST]
	for cell: Vector2i in cells:
		for index in range(4):
			var side: int = sides[index]
			if cells.has(cell + directions[index]) or open_edges.has(_edge_key(cell, side)):
				continue
			var a := cell
			var b := cell + Vector2i.RIGHT
			if side == EAST:
				a = cell + Vector2i.RIGHT
				b = cell + Vector2i.ONE
			elif side == SOUTH:
				a = cell + Vector2i.DOWN
				b = cell + Vector2i.ONE
			elif side == WEST:
				b = cell + Vector2i.DOWN
			var edge := {"a": a, "b": b, "side": side}
			edges.append(edge)
			for point in [a, b]:
				if not adjacency.has(point):
					adjacency[point] = []
				adjacency[point].append(edge)
	var turns: Dictionary = {}
	for point: Vector2i in adjacency:
		var links: Array = adjacency[point]
		if links.size() != 2:
			continue
		var first: Dictionary = links[0]
		var second: Dictionary = links[1]
		if first.side == second.side:
			continue
		var mask := 0
		for index in range(4):
			var delta: Vector2i = [Vector2i(-1,-1), Vector2i(0,-1), Vector2i.ZERO, Vector2i(-1,0)][index]
			if cells.has(point + delta):
				mask |= 1 << index
		var id: String = {4:"nw", 8:"ne", 2:"sw", 1:"se", 14:"se", 13:"sw", 11:"nw", 7:"ne"}.get(mask, "")
		if id.is_empty():
			continue
		var anchor := Vector2(point) * STEP
		if id in ["ne", "se"]:
			anchor.x += WALL_PROFILE.BORDER
		if (mask in [1,2,7,11]):
			anchor.y += WALL_PROFILE.SOUTH_PROJECTION
		var compact: bool = mask in [7,11,13,14]
		if point.x == 0 and connections & WEST:
			compact = true
		if point.x == size.x and connections & EAST:
			compact = true
		turns[point] = {"id": id, "anchor": anchor, "compact": compact, "mask": mask}
	var runs: Array[Dictionary] = []
	var visited: Dictionary = {}
	for edge in edges:
		var initial_key := _segment_key(edge)
		if visited.has(initial_key):
			continue
		var a: Vector2i = edge.a
		var b: Vector2i = edge.b
		visited[initial_key] = true
		for endpoint in [0, 1]:
			var point := a if endpoint == 0 else b
			while not turns.has(point) and adjacency[point].size() == 2:
				var next: Dictionary = {}
				for candidate: Dictionary in adjacency[point]:
					if candidate.side == edge.side and not visited.has(_segment_key(candidate)):
						next = candidate
						break
				if next.is_empty():
					break
				visited[_segment_key(next)] = true
				point = next.b if next.a == point else next.a
			if endpoint == 0:
				a = point
			else:
				b = point
		if a.x > b.x or a.y > b.y:
			var swap := a
			a = b
			b = swap
		runs.append({"a": a, "b": b, "side": edge.side, "left_turn": turns.get(a, {}), "right_turn": turns.get(b, {})})
	var separators := _narrow_horizontal_separators(runs)
	return {"cells": cells, "turns": turns, "runs": runs, "separators": separators,
		"size": size, "length": length, "connections": connections}

static func _narrow_horizontal_separators(runs: Array[Dictionary]) -> Array[Dictionary]:
	# Opposing exposed edges enclose one empty row. When they terminate together
	# at a room, their projected caps collide: select one shared divider instead.
	# This local rule depends only on the contour, never the scene name/room size.
	var result: Array[Dictionary] = []
	for upper in runs:
		if upper.side != SOUTH:
			continue
		for lower in runs:
			if lower.side != NORTH or lower.a != upper.a + Vector2i.DOWN or lower.b != upper.b + Vector2i.DOWN:
				continue
			if upper.left_turn.is_empty() != lower.left_turn.is_empty() or upper.right_turn.is_empty() != lower.right_turn.is_empty():
				continue
			var closed_left: bool = not upper.left_turn.is_empty() and not lower.left_turn.is_empty()
			var closed_right: bool = not upper.right_turn.is_empty() and not lower.right_turn.is_empty()
			# One closed nose and one open continuation. Wider gaps and enclosed
			# islands keep their existing assembly until they have suitable art.
			if closed_left == closed_right:
				continue
			var end: Vector2i = upper.a if closed_left else upper.b
			var end_run: Dictionary = {}
			for candidate in runs:
				if candidate.side in [WEST,EAST] and candidate.a == end and candidate.b == end + Vector2i.DOWN:
					end_run = candidate
					break
			if end_run.is_empty():
				continue
			var index := result.size()
			for consumed in [upper,lower,end_run]:
				consumed["separator"] = index
			for turn in [end_run.left_turn,end_run.right_turn]:
				turn["separator"] = index
			result.append({"upper": upper,"lower": lower,"end": end,"closed_left": closed_left})
	return result

static func _edge_key(cell: Vector2i, side: int) -> String:
	return "%s:%d" % [cell, side]

static func _segment_key(edge: Dictionary) -> String:
	return "%s:%s:%d" % [edge.a, edge.b, edge.side]
