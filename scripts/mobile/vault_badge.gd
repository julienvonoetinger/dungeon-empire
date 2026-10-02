extends Control

var amount := -1
var ratio := 0.0
var icon: Texture2D
var unit := " or"
var empty_caption := "Vide"
var frame := preload("res://scripts/mobile/hud_frame.gd").new()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(116, 42)

func set_amount(value: int, capacity: int) -> void:
	var next_ratio := clampf(float(value) / maxf(capacity, 1.0), 0.0, 1.0)
	if amount == value and is_equal_approx(ratio, next_ratio):
		return
	amount = value
	ratio = next_ratio
	queue_redraw()

func _draw() -> void:
	frame.draw(get_canvas_item(), Rect2(20, 5, 96, 32))
	_draw_ring(Color("e9b94f"))
	var caption := str(amount) + unit if amount > 0 else empty_caption
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font, Vector2(44 + (68 - text_width) / 2, 27), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff0d0") if amount > 0 else Color("b4b4b4"))

func _draw_ring(color: Color) -> void:
	var center := Vector2(21, 21)
	draw_circle(center, 19, Color("0b1012"))
	draw_arc(center, 19, 0, TAU, 64, Color("636568"), 3, true)
	if ratio > 0.0:
		draw_arc(center, 19, -PI / 2, -PI / 2 + TAU * ratio, 64, color, 3, true)
	if icon != null:
		draw_texture_rect(icon, Rect2(7, 7, 28, 28), false, Color.WHITE if amount > 0 else Color("8a8a8a"))
