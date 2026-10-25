extends RefCounted
## Stable selection during rebuild only. Accent candidates exclude neighbours.
const DETAILS = preload("res://scripts/dungeon_surface_details.gd")


static func select(parts: Array[Dictionary], specials: Dictionary, seed: int, corruption: bool) -> Dictionary:
	var walls: Array[Dictionary] = []
	var blocked := {}
	for part in parts:
		if part.id == "torch-horizontal" or part.id == "torch-vertical":
			blocked[DETAILS.key("wall-h" if part.id == "torch-horizontal" else "wall-v", Vector2i(part.at))] = true
	for part in parts:
		var kind := DETAILS.surface(str(part.id))
		if kind != "wall-h" and kind != "wall-v":
			continue
		var at := Vector2i(part.at)
		var key := DETAILS.key(kind, at)
		var other := at + (Vector2i.UP if kind == "wall-h" else Vector2i.LEFT)
		if blocked.has(key) or specials.has(at) or specials.has(other):
			continue
		walls.append({"part": part, "kind": kind, "at": at, "key": key, "rank": DETAILS._rank(kind, at, seed, 104729)})
	walls.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.kind != b.kind:
			return a.kind < b.kind
		var horizontal: bool = a.kind == "wall-h"
		var line_a: int = a.at.y if horizontal else a.at.x
		var line_b: int = b.at.y if horizontal else b.at.x
		if line_a != line_b:
			return line_a < line_b
		return a.at.x < b.at.x if horizontal else a.at.y < b.at.y)
	var candidates := {}
	for wall in walls:
		if int(wall.rank) % 100 < 55:
			candidates[wall.key] = wall
	var chosen := {}
	var previous := {}
	for wall in walls:
		var axis := Vector2i.RIGHT if wall.kind == "wall-h" else Vector2i.DOWN
		var accent: bool = candidates.has(wall.key)
		if accent:
			for delta in [axis, -axis]:
				var adjacent: Dictionary = candidates.get(DETAILS.key(wall.kind, wall.at + delta), {})
				if not adjacent.is_empty() and (adjacent.rank < wall.rank or (adjacent.rank == wall.rank and adjacent.key < wall.key)):
					accent = false
		var roll := DETAILS._rank(wall.kind, wall.at, seed, 13007)
		var family := "f" if accent and roll % 100 < 35 else "c" if accent else "a"
		var index := DETAILS._rank(wall.kind, wall.at, seed, 7919) % (4 if family == "a" else 3)
		var neighbour: Dictionary = previous.get(DETAILS.key(wall.kind, wall.at - axis), {})
		if not neighbour.is_empty() and neighbour.family == family and neighbour.index == index:
			index = (index + 1 + roll % 2) % (4 if family == "a" else 3)
		previous[wall.key] = {"family": family, "index": index}
		if family == "f" and not corruption:
			continue
		# Periodic bare walls provide space between the more detailed variants.
		if family == "a" and index == 3:
			continue
		chosen[wall.key] = {"id": "%s-%s%d" % [wall.part.id, family, index + 1], "ornament": family == "f"}
	return chosen
