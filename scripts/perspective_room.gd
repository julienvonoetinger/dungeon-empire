@tool
extends Node2D

## Fixed reference entrance reconstructed from individually movable elements.
## Only Camera2D scales the composition; each element retains native proportions.
const ATLAS := preload("res://assets/dungeon/perspective/reference-atlas.png")
const PIECES := preload("res://scripts/reference_pieces.gd")
var _pieces: Array[Polygon2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build()
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(_fit)
		_fit()

func _build() -> void:
	for part in _pieces:
		part.free()
	_pieces.clear()
	for definition: Dictionary in PIECES.build():
		var part := Polygon2D.new()
		part.name = definition.name
		part.texture = ATLAS
		part.uv = definition.source
		var anchor: Vector2 = definition.source[0]
		var local := PackedVector2Array()
		for point: Vector2 in definition.source:
			local.append(point - anchor)
		part.polygon = local
		part.position = anchor - Vector2(PIECES.FRAME.position)
		part.set_meta("kind", definition.kind)
		add_child(part)
		_pieces.append(part)

func get_source_frame() -> Rect2i:
	return PIECES.FRAME

func get_content_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(PIECES.FRAME.size))

func get_art_pieces() -> Array[Polygon2D]:
	return _pieces.duplicate()

func _fit() -> void:
	var camera := $Camera2D as Camera2D
	var available := get_viewport_rect().size
	var size := Vector2(PIECES.FRAME.size)
	camera.position = size * 0.5
	camera.zoom = Vector2.ONE * minf(available.x / size.x, available.y / size.y)
	camera.force_update_scroll()

func _draw() -> void:
	draw_rect(get_content_rect(), Color("080e19"))
