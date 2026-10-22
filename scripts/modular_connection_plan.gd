extends RefCounted

## Logical occupancy -> exposed edges -> runs and oriented turns.
## Rendering ports are independent of scene names and authored world positions.
const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
const WALL_PROFILE := preload("res://scripts/modular_wall_profile.gd")
const STEP := WALL_PROFILE.CELL_PITCH

static func build(size: Vector2i, length: int, connections: int, vertical_length: int = 0) -> Dictionary:
	var vertical := vertical_length if vertical_length > 0 else length
	var cells: Dictionary = {}
	for y in range(size.y):
		for x in range(size.x):
			cells[Vector2i(x, y)] = true
	var cx := size.x / 2
	var cy := size.y / 2
	var open_edges: Dictionary = {}
	for index in range(1, length + 1):
		if connections & WEST:
			cells[Vector2i(-index, cy)] = true
		if connections & EAST:
			cells[Vector2i(size.x + index - 1, cy)] = true
	for index in range(1, vertical + 1):
		if connections & NORTH:
			cells[Vector2i(cx, -index)] = true
		if connections & SOUTH:
			cells[Vector2i(cx, size.y + index - 1)] = true
	if connections & NORTH:
		open_edges[_edge_key(Vector2i(cx, -vertical), NORTH)] = true
	if connections & SOUTH:
		open_edges[_edge_key(Vector2i(cx, size.y + vertical - 1), SOUTH)] = true
	if connections & WEST:
		open_edges[_edge_key(Vector2i(-length, cy), WEST)] = true
	if connections & EAST:
		open_edges[_edge_key(Vector2i(size.x + length - 1, cy), EAST)] = true
	var result := from_cells(cells, open_edges, size, length, connections)
	result["vertical_length"] = vertical
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
	return {"cells": cells, "turns": turns, "runs": runs, "size": size, "length": length, "connections": connections}

static func _edge_key(cell: Vector2i, side: int) -> String:
	return "%s:%d" % [cell, side]

static func _segment_key(edge: Dictionary) -> String:
	return "%s:%s:%d" % [edge.a, edge.b, edge.side]
