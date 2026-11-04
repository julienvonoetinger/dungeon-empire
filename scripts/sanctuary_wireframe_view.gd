extends Node2D

@export var terrain_bounds: Rect2

func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var screen := get_viewport_rect().size
	# Frame the clearing, with the approaching path in the lower third.
	var focus := Vector2(0, -65)
	var fit := minf(screen.x / 1440., screen.y / 1130.)
	if screen.y > screen.x:
		# Follow the approach to the altar; the outer cliffs can leave the frame.
		focus = Vector2(-12, 88)
		fit = screen.x / 660.
	var margin := (focus - terrain_bounds.position).min(terrain_bounds.end - focus)
	var cover := maxf(screen.x / (2.*margin.x), screen.y / (2.*margin.y))
	scale = Vector2.ONE * maxf(fit, cover)
	position = screen * .5 - focus * scale
