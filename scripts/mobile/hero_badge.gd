extends "res://scripts/mobile/vault_badge.gd"

var name_label := Label.new()
var level_label := Label.new()
const LEVEL_WIDTH := 32.0

func _init() -> void:
	super._init()
	size = Vector2(42, 42)
	for label in [name_label, level_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("fff0d0"))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
	name_label.position = Vector2(46, 5)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func set_hero(hero: Dictionary, portrait: Texture2D) -> void:
	if icon != portrait:
		icon = portrait
		queue_redraw()
	var next_name := HeroRoster.display_name(hero)
	var next_level := str(maxi(1, int(hero.get("level", 1))))
	if name_label.text != next_name or level_label.text != next_level:
		name_label.text = next_name
		level_label.text = next_level
		var name_width := minf(145, ceilf(name_label.get_theme_font("font").get_string_size(next_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x))
		var level_width := ceilf(level_label.get_theme_font("font").get_string_size(next_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
		level_label.add_theme_font_size_override("font_size", mini(14, floori(14 * (LEVEL_WIDTH - 8) / maxf(1, level_width))))
		name_label.size = Vector2(name_width, 32)
		level_label.position = Vector2(name_label.position.x + name_width + 8, 5)
		level_label.size = Vector2(LEVEL_WIDTH, 32)
		size.x = level_label.position.x + LEVEL_WIDTH
		queue_redraw()
	set_amount(maxi(0, int(hero.get("hp", 0))), maxi(1, int(hero.get("max_hp", 1))))

func _draw() -> void:
	frame.draw(get_canvas_item(), Rect2(20, 5, size.x - 20, 32))
	var left := level_label.position.x
	var points := PackedVector2Array([Vector2(left, 5), Vector2(size.x - 6.4, 5),
		Vector2(size.x, 11.4), Vector2(size.x, 30.6), Vector2(size.x - 6.4, 37), Vector2(left, 37)])
	draw_colored_polygon(points, Color("887044"))
	points.append(points[0])
	draw_polyline(points, Color("b79958"), 1.0, true)
	_draw_ring(Color("64d5ae"))
