extends SceneTree

func _initialize() -> void:
	var badge = preload("res://scripts/mobile/hero_badge.gd").new()
	badge.set_hero({"id": 8, "kind": "thief", "name": "Neris 8", "level": 1}, null)
	assert(badge.name_label.text == "Neris", "Generated identity number is not a visible name")
	assert(badge.level_label.text == "1")
	badge.set_hero({"id": 8, "kind": "thief", "name": "Neris", "level": 3}, null)
	assert(badge.name_label.text == "Neris" and badge.level_label.text == "3")
	var width: float = badge.size.x
	for level in [9, 10, 99, 100, 9999]:
		badge.set_hero({"name": "Neris", "level": level}, null)
		assert(badge.size.x == width, "Level changes never resize the badge")
		assert(badge.level_label.text == str(level))
		var text_width: float = badge.level_label.get_theme_font("font").get_string_size(str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, badge.level_label.get_theme_font_size("font_size")).x
		assert(text_width <= badge.level_label.size.x - 6, "Level fits inside the golden compartment")
	badge.set_hero({"id": 8, "kind": "thief", "name": "Custom 8", "level": 1}, null)
	assert(badge.name_label.text == "Custom 8", "Do not truncate arbitrary names")
	badge.free()
	print("OK: hero display omits generated IDs and preserves names and levels")
	quit()
