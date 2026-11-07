extends Node2D

## Provisional gameplay symbols and shared mobile status rings.
const Badge = preload("res://scripts/game/ui/world_badge.gd")
const GOLD_BAG = preload("res://assets/game/introduction/village-gold-bag.png")
const GOLD_BAG_HEIGHT := 78.0
var kind := "chest"
var caption := ""
var tint := Color("e5b85e")
var health := 1.0
var active := true
var jump_height := 0.0
var label: Label
var badge: Control
var badge_anchor_y := -26.0

func fit_badge(extent: float) -> void:
	if not badge: return
	badge.scale=Vector2.ONE*(extent/badge.size.x)
	badge.position=Vector2(-extent/2,badge_anchor_y-extent-5)

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
	if kind == "village_bag":
		var sprite := Sprite2D.new()
		sprite.texture = GOLD_BAG
		sprite.scale = Vector2.ONE * (GOLD_BAG_HEIGHT / GOLD_BAG.get_height())
		sprite.position.y = -36.
		add_child(sprite)
		badge_anchor_y = (sprite.transform * sprite.get_rect()).position.y
	if kind in ["chest","village_bag","trap","door"]:
		label.hide()
		badge=Badge.new()
		badge.name="StatusRing"
		# Information remains readable over nearby masonry; the prop keeps its depth.
		badge.z_index=10
		add_child(badge)
		fit_badge(Badge.SCREEN_DIAMETER)
		match kind:
			"chest", "village_bag": badge.configure("coins", Color("e9b94f"))
			"door": badge.configure("lock", Color("c66b50"))
			"trap": badge.configure("spike", Color("c66b50"), true)

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
	elif kind in ["chest","door","village_bag"]:
		pass
	elif kind == "trap":
		pass # The prepared inset tile owns the mechanism; retain only its ring.
	elif kind == "corpse":
		draw_line(Vector2(-15,-8), Vector2(15,8), color, 7, true)
		draw_line(Vector2(15,-8), Vector2(-15,8), color, 7, true)
	elif kind == "loot":
		draw_circle(Vector2(18,-4), 12, color)
		draw_circle(Vector2(18,-4), 7, color.darkened(.4), false, 2, true)
	else:
		draw_polyline(PackedVector2Array([Vector2(-37,0),Vector2(0,-18),Vector2(37,0),Vector2(0,18),Vector2(-37,0)]), color, 3, true)
