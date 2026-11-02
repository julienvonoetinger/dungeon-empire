extends "res://scripts/mobile_dungeon_renderer.gd"
## Review-only prop. The ordinary floor, pillars and walls use the production renderer.
func art_directory() -> String:
	return "res://docs/reference/treasury-review/v9-sprite-unique/"

var anchor := Vector2(7,7)
var tex: Texture2D
var ground_pin := Vector2.ZERO
var support_half := Vector2(.72,.72)
var draw_count := 0

func _load_hoard() -> bool:
	if tex == null:
		var img := Image.load_from_file(art_directory()+"reserve.png")
		assert(img != null and not img.is_empty())
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
		var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art_directory()+"sprite.json"))
		ground_pin = Vector2(registration.pivot[0],registration.pivot[1])
	return true

func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
	draw_count = 0
	if not _load_hoard():
		return super._ordered_parts(parts)
	var eye: Vector3 = _definition.get("view_direction")
	var copy := parts.duplicate()
	copy.append({"id":"treasury-hoard","at":anchor,
		"min":Vector3(anchor.x-support_half.x,anchor.y-support_half.y,0),
		"max":Vector3(anchor.x+support_half.x,anchor.y+support_half.y,.65),
		"depth":anchor.dot(Vector2(eye.x,eye.y)),
		"rect":Rect2(grid_to_local(anchor)-ground_pin,tex.get_size())})
	return super._ordered_parts(copy)

func _draw_part(part: Dictionary, layer: int) -> void:
	if part.id!="treasury-hoard":
		super._draw_part(part,layer)
		return
	var s := Sprite2D.new()
	s.name="Treasure"
	s.texture=tex
	s.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.centered=false
	s.position=part.rect.position
	s.z_index=layer
	_world.add_child(s)
	draw_count+=1
