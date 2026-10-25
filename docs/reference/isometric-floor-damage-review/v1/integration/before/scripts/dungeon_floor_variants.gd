extends RefCounted
## All four prepared arrangements share complete stones across every boundary.
const KEYS = preload("res://scripts/dungeon_surface_details.gd")


static func select(cell: Vector2i, seed: int) -> String:
	# Two disjoint pairs alternate across each row. The hash chooses within the
	# pair, so horizontal neighbours never repeat without a short four-tile cycle.
	# Shift the pair phase per row/seed; posmod also covers negative coordinates.
	# Use upper hash bits: the low bit of FNV follows the input character parity.
	var phase := (KEYS._rank("floor-row", Vector2i(0, cell.y), seed, 104729) >> 11) & 1
	var pair := posmod(cell.x + phase, 2)
	var choice := (KEYS._rank("floor", cell, seed, 13007) >> 9) & 1
	return "floor-b%d" % (1 + pair * 2 + choice)
