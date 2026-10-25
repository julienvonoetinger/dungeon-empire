extends RefCounted
## Shared stable surface keys/ranks used by wall variants; no damage placement.

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

