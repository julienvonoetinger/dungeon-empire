extends Node2D

## Deliberately provisional gameplay symbols, not replacement dungeon artwork.
var kind := "chest"
var caption := ""
var tint := Color("e5b85e")
var health := 1.0
var active := true
var jump_height := 0.0
var label: Label

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-85, -112 if kind == "hero" else -72)
	label.size = Vector2(170, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("f4e5bd"))
	label.add_theme_color_override("font_outline_color", Color("101522"))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func refresh(text_value: String, ratio := 1.0) -> void:
	caption = text_value
	health = clampf(ratio, 0, 1)
	if label: label.text = caption
	queue_redraw()

func _draw() -> void:
	var color := tint if active else Color("778295")
	if kind == "hero":
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, .5))
		draw_circle(Vector2.ZERO, 24, Color(0, 0, 0, .4))
		draw_set_transform(Vector2(0, -jump_height))
		draw_colored_polygon(PackedVector2Array([Vector2(-20,-13),Vector2(-14,-51),Vector2(14,-51),Vector2(20,-13),Vector2(0,-2)]), color.darkened(.3))
		draw_circle(Vector2(0, -66), 16, color)
		draw_circle(Vector2(0, -66), 16, Color("131a29"), false, 3, true)
		draw_line(Vector2(-24, -91), Vector2(24, -91), Color("161e2a"), 6)
		draw_line(Vector2(-24, -91), Vector2(-24 + 48 * health, -91), Color("80d6a0"), 4)
	elif kind == "chest":
		var top := PackedVector2Array([Vector2(-32,-26),Vector2(0,-42),Vector2(32,-26),Vector2(0,-10)])
		draw_colored_polygon(PackedVector2Array([Vector2(-32,-26),Vector2(0,-10),Vector2(32,-26),Vector2(32,0),Vector2(0,16),Vector2(-32,0)]), color.darkened(.55))
		draw_colored_polygon(top, color.darkened(.15))
		draw_polyline(PackedVector2Array([top[0],top[1],top[2],top[3],top[0]]), color, 3, true)
		draw_line(Vector2(0, -10), Vector2(0, 16), color, 4)
	elif kind == "trap":
		var diamond := PackedVector2Array([Vector2(-48,0),Vector2(0,-24),Vector2(48,0),Vector2(0,24),Vector2(-48,0)])
		draw_colored_polygon(diamond, Color(color, .18))
		draw_polyline(diamond, color, 2, true)
		for x in [-18,0,18]:
			draw_colored_polygon(PackedVector2Array([Vector2(x-7,7),Vector2(x,-18),Vector2(x+7,7)]), color)
	elif kind == "corpse":
		draw_line(Vector2(-15,-8), Vector2(15,8), color, 7, true)
		draw_line(Vector2(15,-8), Vector2(-15,8), color, 7, true)
	elif kind == "loot":
		draw_circle(Vector2(18,-4), 12, color)
		draw_circle(Vector2(18,-4), 7, color.darkened(.4), false, 2, true)
	else:
		draw_polyline(PackedVector2Array([Vector2(-37,0),Vector2(0,-18),Vector2(37,0),Vector2(0,18),Vector2(-37,0)]), color, 3, true)
