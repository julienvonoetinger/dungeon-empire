extends "res://scripts/six_room_preview.gd"
## Uses the same optimized renderer and atlas as all other architecture scenes.
func _initial_center() -> Vector2:
	return dungeon.grid_to_local(Vector2(440, 260) / 256.0)
