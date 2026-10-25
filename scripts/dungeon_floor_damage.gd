extends RefCounted
## Prepared host-specific patches only; evaluated during rebuild, never per frame.
const KEYS = preload("res://scripts/dungeon_surface_details.gd")
const IDS := {"floor-b1":"floor-b1-damage-a", "floor-b2":"floor-b2-damage-b", "floor-b3":"floor-b3-damage-c", "floor-b4":"floor-b4-damage-d"}


static func select(floors: Array[Dictionary], solids: Array[Dictionary], specials: Dictionary, seed: int, corruption: bool) -> Dictionary:
	var candidates := {}
	for floor_part in floors:
		var id := str(floor_part.id)
		if not IDS.has(id):
			continue
		var cell := Vector2i(floor_part.at)
		if specials.has(cell):
			continue
		var blocked := false
		for solid in solids:
			if solid.id != "heart":
				continue
			# Conservative XY support footprint, including fractional anchors.
			if floor_part.min.x < solid.max.x and floor_part.max.x > solid.min.x and floor_part.min.y < solid.max.y and floor_part.max.y > solid.min.y:
				blocked = true
				break
		if blocked:
			continue
		var is_corrupt := id == "floor-b3" or id == "floor-b4"
		if is_corrupt and not corruption:
			continue
		var rank := KEYS._rank("floor-damage", cell, seed, 65537)
		if rank % 100 >= (20 if is_corrupt else 42):
			continue
		candidates[cell] = {"id":IDS[id], "rank":rank, "key":KEYS.key("floor",cell)}
	var chosen := {}
	for cell: Vector2i in candidates:
		var candidate: Dictionary = candidates[cell]
		var keep := true
		for dy in range(-1,2):
			for dx in range(-1,2):
				if dx == 0 and dy == 0:
					continue
				var neighbour: Dictionary = candidates.get(cell+Vector2i(dx,dy),{})
				if not neighbour.is_empty() and (neighbour.rank < candidate.rank or (neighbour.rank == candidate.rank and neighbour.key < candidate.key)):
					keep = false
		if keep:
			chosen[cell] = candidate.id
	return chosen
