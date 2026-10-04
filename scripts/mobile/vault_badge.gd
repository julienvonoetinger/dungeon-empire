extends Control

var amount := -1
var ratio := 0.0
var icon: Texture2D
var unit := " or"
var empty_caption := "Vide"
var frame := preload("res://scripts/mobile/hud_frame.gd").new()
var protection_tier := 0
var protected := false

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

func set_protection(tier: int, intact: bool) -> void:
	if protection_tier == tier and protected == intact:
		return
	protection_tier = tier
	protected = intact
	queue_redraw()

func _draw() -> void:
	frame.draw(get_canvas_item(), Rect2(20, 5, 96, 32))
	_draw_ring(Color("e9b94f"))
	var caption := str(amount) + unit if amount > 0 else empty_caption
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font, Vector2(44 + (68 - text_width) / 2, 27), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff0d0") if amount > 0 else Color("b4b4b4"))
	if protection_tier > 0:
		var color := (Color("ca85ef") if protection_tier == 2 else Color("e9b94f")) if protected else Color("8a8a8a")
		draw_circle(Vector2(34, 33), 9, Color("0b1012"))
		if protection_tier == 2:
			draw_polyline(PackedVector2Array([Vector2(34, 26), Vector2(39, 33), Vector2(34, 40), Vector2(29, 33), Vector2(34, 26)]), color, 2, true)
		else:
			draw_arc(Vector2(34 if protected else 37, 31), 4, PI, TAU, 12, color, 2, true)
			draw_rect(Rect2(29, 31, 10, 7), color, false, 2)

func _draw_ring(color: Color) -> void:
	var center := Vector2(21, 21)
	draw_circle(center, 19, Color("0b1012"))
	draw_arc(center, 19, 0, TAU, 64, Color("636568"), 3, true)
	if ratio > 0.0:
		draw_arc(center, 19, -PI / 2, -PI / 2 + TAU * ratio, 64, color, 3, true)
	if icon != null:
		var icon_size := icon.get_size()
		var fitted := icon_size * (28.0 / maxf(icon_size.x, icon_size.y))
		draw_texture_rect(icon, Rect2(center - fitted / 2.0, fitted), false, Color.WHITE if amount > 0 else Color("8a8a8a"))
