extends "res://docs/reference/treasury-review/v11-couloir/renderer.gd"
const TreasuryArt = preload("res://scripts/game/treasure_room_art.gd")

func art_directory() -> String:
	return "res://docs/reference/treasury-review/v12-peint-directions/"

func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
	if not entrance.is_empty():
		var fit := TreasuryArt.placement({"origin":ROOM_ORIGIN,"side":entrance.side,"slot":entrance.slot}, parts)
		anchor = fit.anchor
		support_half = fit.half
	return super._ordered_parts(parts)

func _load_hoard() -> bool:
	if entrance.is_empty():
		tex = null
		return false
	if registrations.is_empty():
		registrations = JSON.parse_string(FileAccess.get_file_as_string(art_directory() + "sprites.json"))
	var side: String = entrance.side
	var paint: Dictionary = registrations[side]
	if not variants.has(side):
		var img := Image.load_from_file(art_directory() + str(paint.file))
		assert(img != null and not img.is_empty())
		img.generate_mipmaps()
		variants[side] = ImageTexture.create_from_image(img)
	tex = variants[side]
	ground_pin = Vector2(paint.pivot[0], paint.pivot[1])
	return true
