extends Node

const FIXED_ZOOM := .75
const DRAG_THRESHOLD := 12.0
var session: IsometricGameSession
var view: Node2D
var camera: Camera2D
var _pointer := -2
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _dragged := false
var _touches := {}
var _last_core := Vector2i(-1,-1)
var _previous_quit_on_back := true
var _suppress_mouse_until := 0
var _palette_button: Button
var _palette_start := Vector2.ZERO
var _palette_dragged := false

func _ready() -> void:
	_previous_quit_on_back = get_tree().quit_on_go_back
	get_tree().quit_on_go_back = false
	get_window().go_back_requested.connect(_go_back)
	session = get_parent() as IsometricGameSession
	view = session.get_node("PlayArea/World/Dungeon")
	camera = session.get_node("PlayArea/World/Camera2D")
	_apply_presentation()
	get_tree().root.size_changed.connect(_apply_presentation)
	session.changed.connect(_changed)
	call_deferred("center_core")

## One cell keeps the physical size of the approved landscape reference
## (720 base units across the short side) in both orientations. In portrait,
## canvas_items/expand maps 1280 units to the width instead, drawing cells
## 1.78x smaller; this compensates that stretch only. It never depends on the
## dungeon's extent and the player still has no zoom control.
func presentation_scale() -> float:
	var visible := get_viewport().get_visible_rect().size
	var window := Vector2(get_window().size)
	if visible.x <= 0 or window.x <= 0: return 1.0
	return maxf(1.0, minf(window.x, window.y)*visible.x/(720.0*window.x))

func _apply_presentation() -> void:
	camera.zoom = Vector2.ONE * FIXED_ZOOM * presentation_scale()

func center_core() -> void:
	var cell := session.sim._core_origin()
	var point := Vector2(cell)+Vector2(.5,.5) if cell.x >= 0 else Vector2(8,8)
	camera.position = view.grid_to_local(point)

func _changed(_structure: bool) -> void:
	if session.paused or session.result_open: _pointer = -2
	var core := session.sim._core_origin()
	if core != _last_core:
		_last_core = core
		center_core()

func _input(event: InputEvent) -> void:
	# Releases/cancellations must also be seen when a Control consumes the event.
	if event is InputEventScreenTouch:
		_suppress_mouse_until = Time.get_ticks_msec() + 500
		if event.canceled:
			_pointer=-2
			_touches.erase(event.index)
			_cancel_palette()
			return
		if event.pressed:
			_touches[event.index] = true
			if _touches.size() > 1:
				_pointer = -2
				_cancel_palette()
		else:
			_touches.erase(event.index)
			if _pointer == event.index: call_deferred("_cancel_if_released", event.index)
	elif event is InputEventMouseButton and not event.pressed:
		if _pointer == -1: call_deferred("_cancel_if_released", -1)

func _cancel_if_released(pointer: int) -> void:
	if _pointer == pointer: _pointer = -2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		session.get_node("HUD").handle_back()
		get_viewport().set_input_as_handled()
		return
	if session.paused or session.result_open or session.confirmation_open or session.save_blocked: return
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and session.get_node("HUD").blocks_pointer(event.position):
		if not event.pressed: _pointer = -2
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touches.size() == 1: _begin(event.index,event.position)
		elif not event.pressed and _pointer == event.index: _finish(event.position)
	elif event is InputEventScreenDrag and _pointer == event.index:
		_move(event.position)
	elif event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		if not _touches.is_empty() or Time.get_ticks_msec() < _suppress_mouse_until: return
		if event.pressed:
			_begin(-1,event.position)
			_dragged = event.button_index == MOUSE_BUTTON_RIGHT
		elif _pointer == -1: _finish(event.position)
	elif event is InputEventMouseMotion and _pointer == -1:
		_move(event.position)

func _begin(pointer: int, point: Vector2) -> void:
	_pointer = pointer
	_start = point
	_last = point
	_dragged = false

func _move(point: Vector2) -> void:
	if point.distance_to(_start) >= _threshold(): _dragged = true
	if _dragged:
		camera.position -= (point-_last)/camera.zoom.x
		var grid_point: Vector2 = view.local_to_grid(camera.position)
		grid_point = grid_point.clamp(Vector2(-1,-1),Vector2(17,17))
		camera.position = view.grid_to_local(grid_point)
	_last = point

func _finish(point: Vector2) -> void:
	if point.distance_to(_start) >= _threshold(): _dragged = true
	if not _dragged and not session.get_node("HUD").blocks_pointer(point):
		var local_point: Vector2 = point - session.get_node("PlayArea").position
		var world_point: Vector2 = view.get_global_transform_with_canvas().affine_inverse() * local_point
		session.activate_cell(view.pick_cell(world_point))
	_pointer = -2

func _threshold() -> float:
	return DRAG_THRESHOLD * session.get_node("HUD").scale.x

func _palette_cell(point: Vector2) -> Vector2i:
	var local_point: Vector2 = point-session.get_node("PlayArea").position
	return view.pick_cell(view.get_global_transform_with_canvas().affine_inverse()*local_point)

func palette_event(button: Button, id: int, event: InputEvent) -> void:
	# Button GUI mouse capture also handles Godot's emulated single-touch mouse.
	if button.disabled or not session.can_edit(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2=button.get_global_transform_with_canvas()*event.position
		if event.pressed:
			button.set_meta("palette_dragging",false)
			if _touches.size()>1: button.set_meta("palette_dragging",true); return
			_palette_button=button; _palette_start=point; _palette_dragged=false
		elif _palette_button==button:
			var dragged := _palette_dragged
			_palette_button=null
			view.show_placement(Vector2i(-1,-1),false)
			if dragged:
				var lifted: Vector2=point-Vector2(0,52)*session.get_node("HUD").scale.x
				if not session.get_node("HUD").blocks_pointer(point) and not session.get_node("HUD").blocks_pointer(lifted):
					var cell := _palette_cell(lifted)
					session.get_node("HUD")._choose_tool(id)
					session.activate_cell(cell)
			call_deferred("_clear_palette_button",button)
	elif event is InputEventMouseMotion and _palette_button==button:
		var point: Vector2=button.get_global_transform_with_canvas()*event.position
		if point.distance_to(_palette_start)>=_threshold(): _palette_dragged=true
		if _palette_dragged:
			button.set_meta("palette_dragging",true)
			var lifted: Vector2=point-Vector2(0,52)*session.get_node("HUD").scale.x
			var cell := _palette_cell(lifted)
			var valid: bool=not session.get_node("HUD").blocks_pointer(point) and not session.get_node("HUD").blocks_pointer(lifted) and session.check_action(cell,id).get("valid",false)
			view.show_placement(cell,valid)

func _clear_palette_button(button: Button) -> void:
	if is_instance_valid(button): button.set_meta("palette_dragging",false)

func _cancel_palette() -> void:
	if is_instance_valid(_palette_button): _palette_button.set_meta("palette_dragging",true)
	_palette_button=null
	if is_instance_valid(view): view.show_placement(Vector2i(-1,-1),false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pointer = -2
		_touches.clear()
		_cancel_palette()

func _go_back() -> void:
	session.get_node("HUD").handle_back()

func _exit_tree() -> void:
	get_tree().quit_on_go_back = _previous_quit_on_back
