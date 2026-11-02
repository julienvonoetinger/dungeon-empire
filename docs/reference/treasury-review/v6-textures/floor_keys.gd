extends SceneTree
## Resolve the four foundation tiles through the production game's selection code.
const Floors = preload("res://scripts/dungeon_floor_variants.gd")
func _initialize() -> void:
	var ids := {}
	for y in 2:
		for x in 2:
			ids["%d,%d" % [x,y]] = Floors.select(Vector2i(6+x,6+y),17)
	var out := FileAccess.open("res://docs/reference/treasury-review/v6-textures/floor-keys.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(ids,"\t")+"\n")
	out.close()
	quit()
