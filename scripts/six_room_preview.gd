extends Node2D

@onready var dungeon = $Dungeon
@onready var camera: Camera2D = $Camera2D
const FIXED_ZOOM := 0.75
var _active_touch := -1
var _positioned := false

func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	if dungeon.has_signal("rebuilt"):
		dungeon.rebuilt.connect(_fit)
	_fit()

func _fit() -> void:
	camera.zoom = Vector2.ONE * FIXED_ZOOM
	if not _positioned:
		camera.position = _initial_center()
		_positioned = true
	camera.force_update_scroll()


func _initial_center() -> Vector2:
	var center: Vector2 = dungeon.get_content_rect().get_center()
	var plan: Dictionary = dungeon.get_connection_plan()
	var distance := INF
	var result := center
	for cell: Vector2i in plan.cells:
		var point: Vector2 = dungeon.grid_to_local(Vector2(cell) + Vector2(.5, .5))
		if point.distance_squared_to(center) < distance:
			distance = point.distance_squared_to(center)
			result = point
	return result


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch == -1:
			_active_touch = event.index
		elif not event.pressed and event.index == _active_touch:
			_active_touch = -1
	elif event is InputEventScreenDrag and event.index == _active_touch:
		camera.position -= event.relative / FIXED_ZOOM
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and _active_touch == -1:
		camera.position -= event.relative / FIXED_ZOOM
	# Wheel and pinch never change the reference scale.


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed and event.index == _active_touch:
		_active_touch = -1
