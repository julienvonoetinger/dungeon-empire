class_name MobileInputRouter
extends RefCounted

signal tapped(position: Vector2)
signal panned(delta: Vector2)
signal pinched(position: Vector2, factor: float)
signal rotated(steps: int)
signal cancelled()
signal painted(from: Vector2, to: Vector2)

var painting_enabled := false

const DRAG_THRESHOLD: float = 12.0
const WHEEL_FACTOR: float = 1.1
const EMULATED_DEVICE: int = -1

var _touches: Dictionary = {}
var _mouse: Dictionary = {}
var _mouse_button: MouseButton = MOUSE_BUTTON_NONE

func handle_event(event: InputEvent, over_ui: bool = false) -> void:
	# Godot marks both touch-from-mouse and mouse-from-touch with device -1.
	if event.device == EMULATED_DEVICE:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event, over_ui)
	elif event is InputEventScreenDrag:
		_handle_drag(event, over_ui)
	elif event is InputEventMouseButton:
		if _touches.is_empty():
			_handle_mouse_button(event, over_ui)
	elif event is InputEventMouseMotion:
		if _touches.is_empty() and not _mouse.is_empty():
			_move_pointer(_mouse, event.position, over_ui)
	elif event is InputEventKey:
		if not event.pressed or event.echo:
			return
		if event.keycode == KEY_ESCAPE:
			cancel()
		elif not over_ui:
			if event.keycode == KEY_Q:
				rotated.emit(-1)
			elif event.keycode == KEY_E:
				rotated.emit(1)

# The owning Node calls this on focus loss or application interruption.
func cancel() -> void:
	_touches.clear()
	_mouse.clear()
	_mouse_button = MOUSE_BUTTON_NONE
	cancelled.emit()

func _pointer(position: Vector2, over_ui: bool) -> Dictionary:
	return {"start": position, "position": position, "ui": over_ui, "dragging": false, "paint": painting_enabled, "blocked": over_ui, "pinched": false}

func _world_fingers() -> Array:
	var fingers: Array = []
	for index in _touches:
		if not _touches[index].ui:
			fingers.append(index)
	return fingers

func _handle_touch(event: InputEventScreenTouch, over_ui: bool) -> void:
	if event.canceled:
		cancel()
		return
	if event.pressed:
		_mouse.clear()
		_mouse_button = MOUSE_BUTTON_NONE
		_touches[event.index] = _pointer(event.position, over_ui)
		var fingers := _world_fingers()
		if fingers.size() >= 2:
			# Every participant stays in drag mode even after the pinch ends.
			for index in fingers:
				_touches[index].dragging = true
				_touches[index].pinched = true
	elif _touches.has(event.index):
		var pointer: Dictionary = _touches[event.index]
		_touches.erase(event.index)
		_release_pointer(pointer, event.position, over_ui)

func _handle_drag(event: InputEventScreenDrag, over_ui: bool = false) -> void:
	if not _touches.has(event.index):
		return
	var pointer: Dictionary = _touches[event.index]
	if pointer.ui:
		pointer.position = event.position
		return
	var fingers := _world_fingers()
	if fingers.size() < 2:
		_move_pointer(pointer, event.position, over_ui)
		return
	var first: Dictionary = _touches[fingers[0]]
	var second: Dictionary = _touches[fingers[1]]
	var old_distance: float = first.position.distance_to(second.position)
	pointer.position = event.position
	if event.index != fingers[0] and event.index != fingers[1]:
		return
	var new_distance: float = first.position.distance_to(second.position)
	if old_distance > 0.0 and new_distance > 0.0:
		pinched.emit((first.position + second.position) * 0.5, new_distance / old_distance)

func _move_pointer(pointer: Dictionary, position: Vector2, over_ui: bool = false) -> void:
	var previous: Vector2 = pointer.position
	var delta: Vector2 = position - pointer.position
	pointer.position = position
	if pointer.ui:
		return
	if pointer.paint:
		if pointer.pinched:
			return
		if not pointer.dragging and position.distance_to(pointer.start) > DRAG_THRESHOLD:
			pointer.dragging = true
			previous = pointer.start
		if pointer.dragging and not over_ui and painting_enabled:
			painted.emit(position if pointer.blocked else previous, position)
		pointer.blocked = over_ui
		return
	if not pointer.dragging and position.distance_to(pointer.start) > DRAG_THRESHOLD:
		pointer.dragging = true
	if pointer.dragging and not delta.is_zero_approx():
		panned.emit(delta)

func _release_pointer(pointer: Dictionary, position: Vector2, over_ui: bool) -> void:
	if not pointer.ui and not over_ui and not pointer.dragging:
		if position.distance_to(pointer.start) <= DRAG_THRESHOLD:
			tapped.emit(position)

func _handle_mouse_button(event: InputEventMouseButton, over_ui: bool) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if event.pressed and not over_ui:
			var factor := WHEEL_FACTOR if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / WHEEL_FACTOR
			pinched.emit(event.position, factor)
		return
	if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if event.pressed:
		if _mouse_button != MOUSE_BUTTON_NONE:
			return
		_mouse_button = event.button_index
		_mouse = _pointer(event.position, over_ui)
		_mouse.paint = painting_enabled and event.button_index == MOUSE_BUTTON_LEFT
		_mouse.dragging = event.button_index == MOUSE_BUTTON_RIGHT
	elif event.button_index == _mouse_button:
		var pointer := _mouse
		_mouse = {}
		_mouse_button = MOUSE_BUTTON_NONE
		_release_pointer(pointer, event.position, over_ui)
