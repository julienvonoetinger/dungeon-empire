extends "res://docs/reference/treasury-review/v5-wireframe/renderer.gd"
const ART := "res://docs/reference/treasury-review/v6-textures/sprites/"
func module_image(id: String) -> Image:
	return Image.load_from_file(ART+id+".png")

func _draw_part(part: Dictionary, layer: int) -> void:
	super._draw_part(part,layer)
	if layout.is_empty() or not str(part.id).begins_with("floor-b"):
		return
	var at := Vector2i(part.at)
	var local := at - Vector2i(START)
	if not Rect2i(0,0,2,2).has_point(local):
		return
	var sprite := _world.get_child(-1) as Sprite2D
	assert(sprite != null and sprite.get_meta("prepared_id")==part.id)
	var id := "sol-%s-%d-%d" % [layout.id,local.x,local.y]
	if not images.has(id):
		var img := module_image(id)
		assert(img != null and img.get_size()==Vector2i(sprite.texture.get_size()))
		img.generate_mipmaps()
		images[id] = ImageTexture.create_from_image(img)
	sprite.texture = images[id]
	sprite.set_meta("treasury_floor",at)
