extends "res://docs/reference/treasury-review/v5-wireframe/capture.gd"
const Painted = preload("res://docs/reference/treasury-review/v6-textures/renderer.gd")
func make_view() -> Node2D:
	return Painted.new()
func review_directory() -> String:
	return "res://docs/reference/treasury-review/v6-textures/"
func save(title: String) -> void:
	if not title.ends_with("-kit"):
		var floor_tiles := {}
		for sprite in view._world.get_children():
			if sprite.has_meta("treasury_floor"):
				var at: Vector2i = sprite.get_meta("treasury_floor")
				check(sprite.z_index==0 and not floor_tiles.has(at),title+" one baked texture per floor cell at ground level")
				floor_tiles[at]=true
		for cell in ROOM:
			check(floor_tiles.has(cell),title+" uses the real painted floor tile at "+str(cell))
	await super.save(title)
