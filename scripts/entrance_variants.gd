@tool
extends Node2D

## Four complete prepared entrance sprites, including their floor.
const LABELS := ["OUVERTURE NORD", "OUVERTURE EST", "OUVERTURE SUD", "OUVERTURE OUEST"]
const TEXTURES := [
	preload("res://assets/dungeon/painted-cells/entrances/north.png"),
	preload("res://assets/dungeon/painted-cells/entrances/east.png"),
	preload("res://assets/dungeon/painted-cells/entrances/south.png"),
	preload("res://assets/dungeon/painted-cells/entrances/west.png"),
]
const PANEL_SIZE := Vector2(560, 470)
const COMPOSITION := Vector2(1120, 940)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for side in range(4):
		var panel := Vector2(side % 2, floori(side / 2.0)) * PANEL_SIZE
		var sprite := Sprite2D.new()
		sprite.texture = TEXTURES[side]
		sprite.centered = false
		sprite.scale = Vector2.ONE * 0.25
		sprite.position = panel + Vector2(128, 80)
		add_child(sprite)
		var label := Label.new()
		label.text = LABELS[side]
		label.position = panel + Vector2(0, 22)
		label.size.x = PANEL_SIZE.x
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 23)
		label.modulate = Color("b6c6df")
		add_child(label)
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(_fit)
		_fit()


func _fit() -> void:
	var available := get_viewport_rect().size
	var zoom := minf(available.x / COMPOSITION.x, available.y / COMPOSITION.y)
	scale = Vector2.ONE * zoom
	position = (available - COMPOSITION * zoom) * 0.5
