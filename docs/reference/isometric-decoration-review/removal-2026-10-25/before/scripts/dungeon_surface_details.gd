extends RefCounted
## Stable, sparse selection on existing hosts; no per-frame work or rasterization.

static func surface(id: String) -> String:
	if id == "floor":
		return "floor"
	if id.begins_with("wall-h-"):
		return "wall-h"
	if id.begins_with("wall-v-"):
		return "wall-v"
	return ""


static func key(kind: String, cell: Vector2i) -> String:
	return "%s:%d:%d" % [kind, cell.x, cell.y]


static func _rank(kind: String, cell: Vector2i, seed: int, salt: int) -> int:
	# Bounded integer arithmetic, independent of Dictionary order and global RNG.
	var value: int = 2166136261
	for byte in ("%s:%d:%d:%d:%d" % [kind, cell.x, cell.y, seed, salt]).to_utf8_buffer():
		value = ((value ^ int(byte)) * 16777619) & 0x7fffffff
	return value


static func select(hosts: Array[Dictionary], solids: Array[Dictionary], specials: Dictionary, seed: int) -> Dictionary:
	var blocked_walls := {}
	var heart_supports: Array[Rect2] = []
	for solid in solids:
		if solid.id == "heart":
			heart_supports.append(Rect2(Vector2(solid.min.x, solid.min.y), Vector2(solid.max.x-solid.min.x, solid.max.y-solid.min.y)))
		elif solid.id == "torch-horizontal":
			blocked_walls[key("wall-h", Vector2i(solid.at))] = true
		elif solid.id == "torch-vertical":
			blocked_walls[key("wall-v", Vector2i(solid.at))] = true
	var candidates := {}
	for host in hosts:
		var kind := surface(str(host.id))
		if kind.is_empty():
			continue
		var cell := Vector2i(host.at)
		var host_key := key(kind, cell)
		if specials.has(cell) or blocked_walls.has(host_key):
			continue
		if kind != "floor":
			var other := cell + (Vector2i.UP if kind == "wall-h" else Vector2i.LEFT)
			if specials.has(other):
				continue
		else:
			var under_heart := false
			for support in heart_supports:
				if Rect2(Vector2(cell), Vector2.ONE).intersects(support):
					under_heart = true
					break
			if under_heart:
				continue
		var rank := _rank(kind, cell, seed, 0)
		if rank % 10000 >= (2500 if kind == "floor" else 4000):
			continue
		candidates[host_key] = {"kind": kind, "cell": cell, "rank": rank}
	var chosen := {}
	for host_key: String in candidates:
		var candidate: Dictionary = candidates[host_key]
		var neighbours: Array[Vector2i] = []
		if candidate.kind == "floor":
			for y in range(-1, 2):
				for x in range(-1, 2):
					if x != 0 or y != 0:
						neighbours.append(Vector2i(x, y))
		else:
			var axis := Vector2i.RIGHT if candidate.kind == "wall-h" else Vector2i.DOWN
			neighbours = [axis, -axis]
		var keep := true
		for delta in neighbours:
			var neighbour_key := key(candidate.kind, candidate.cell + delta)
			if not candidates.has(neighbour_key):
				continue
			var neighbour: Dictionary = candidates[neighbour_key]
			if neighbour.rank < candidate.rank or (neighbour.rank == candidate.rank and neighbour_key < host_key):
				keep = false
				break
		if keep:
			var roll := _rank(candidate.kind, candidate.cell, seed, 7919) % 100
			var motif := "corner-split" if roll < 25 else "vertical-hairline" if roll < 50 else "edge-fork" if roll < 70 else "chip-worn" if roll < 95 else "crack-corrupt"
			chosen[host_key] = "detail-%s-%s" % [motif, candidate.kind]
	return chosen
