extends BaseButton
## Tap to turn the page or drag to read. The scrollbar and wheel stay native.
const TAP_SLOP := 8.
var reading_area: ScrollContainer
var _fingers := {}
var _start := Vector2.INF
var _initial_scroll := 0
var _dragging := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL
	accessibility_name = "Page suivante"
	visibility_changed.connect(reset_gesture)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)

func reset_gesture() -> void:
	_start = Vector2.INF
	_fingers.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: reset_gesture()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_fingers[event.index] = true
			if _fingers.size() == 1: _begin(event.position)
			else: _start = Vector2.INF
		elif _fingers.erase(event.index) and _fingers.is_empty():
			_finish(event.position,event.canceled)
	elif event is InputEventScreenDrag and _fingers.has(event.index):
		_check_motion(event.position)
	elif _fingers.is_empty():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not event.canceled: _begin(event.position)
			else: _finish(event.position,event.canceled)
		elif event is InputEventMouseMotion:
			_check_motion(event.position)

func _local_point(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point

func _can_tap(point: Vector2) -> bool:
	var scroll_bar := reading_area.get_v_scroll_bar()
	var bar_point := scroll_bar.get_global_transform_with_canvas().affine_inverse() * point
	if scroll_bar.is_visible_in_tree() and Rect2(Vector2.ZERO,scroll_bar.size).has_point(bar_point): return false
	return Rect2(Vector2.ZERO,size).has_point(_local_point(point))

func _begin(point: Vector2) -> void:
	_start = _local_point(point) if _can_tap(point) else Vector2.INF
	_initial_scroll = reading_area.scroll_vertical
	_dragging = false
	if _start.is_finite(): get_viewport().set_input_as_handled()

func _check_motion(point: Vector2) -> void:
	if not _start.is_finite(): return
	var offset := _local_point(point) - _start
	if offset.length() >= TAP_SLOP: _dragging = true
	if _dragging: reading_area.scroll_vertical = _initial_scroll - roundi(offset.y)
	get_viewport().set_input_as_handled()

func _finish(point: Vector2, canceled: bool) -> void:
	if not _start.is_finite(): return
	get_viewport().set_input_as_handled()
	if not canceled: _check_motion(point)
	var tapped := not canceled and not _dragging and _can_tap(point) and _initial_scroll == reading_area.scroll_vertical
	_start = Vector2.INF
	if tapped: pressed.emit()

func _draw() -> void:
	var center := size - Vector2(24,16)
	draw_set_transform(center)
	if has_focus():
		draw_style_box(get_theme_stylebox("focus","Button"),Rect2(-19,-14,38,27))
	var left := Vector2(-10,-7)
	var right := Vector2(10,-7)
	var tip := Vector2(0,5)
	var mid := Vector2(0,-4)
	draw_colored_polygon(PackedVector2Array([left,right,mid]),Color("f4e5ff"))
	draw_colored_polygon(PackedVector2Array([left,mid,tip]),Color("c7b2e7"))
	draw_colored_polygon(PackedVector2Array([mid,right,tip]),Color("8872b2"))
	draw_polyline(PackedVector2Array([Vector2(-5,4),Vector2(0,9),Vector2(5,4)]),Color("b7acd5"),1.5,true)
