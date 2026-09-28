extends SceneTree

var failures: int = 0
var events: Array = []
var router

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func touch(index: int, pressed: bool, position: Vector2, ui: bool = false, device: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	event.device = device
	event.canceled = canceled
	router.handle_event(event, ui)

func drag(index: int, position: Vector2, ui: bool = false) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	router.handle_event(event, ui)

func button(which: MouseButton, pressed: bool, position: Vector2 = Vector2.ZERO, ui: bool = false, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = which
	event.pressed = pressed
	event.position = position
	event.device = device
	router.handle_event(event, ui)

func motion(position: Vector2, ui: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	router.handle_event(event, ui)

func key(code: Key, pressed: bool = true, echo: bool = false, ui: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	router.handle_event(event, ui)

func fresh() -> void:
	router.cancel()
	events.clear()

func _initialize() -> void:
	var path := "res://scripts/mobile/mobile_input_router.gd"
	if not ResourceLoader.exists(path):
		check(false, "MobileInputRouter must exist")
		quit(1)
		return
	router = load(path).new()
	router.tapped.connect(func(p): events.append(["tap", p]))
	router.panned.connect(func(d): events.append(["pan", d]))
	router.pinched.connect(func(p, f): events.append(["pinch", p, f]))
	router.rotated.connect(func(s): events.append(["rotate", s]))
	router.cancelled.connect(func(): events.append(["cancel"]))
	touch(7, true, Vector2.ZERO)
	drag(7, Vector2(12, 0))
	check(events.is_empty(), "12 logical pixels is still a tap candidate")
	touch(7, false, Vector2(12, 0))
	check(events == [["tap", Vector2(12, 0)]], "tap occurs only on release")
	fresh()
	touch(3, true, Vector2.ZERO)
	drag(3, Vector2(13, 0))
	drag(3, Vector2(16, 2))
	touch(3, false, Vector2(16, 2))
	check(events == [["pan", Vector2(13, 0)], ["pan", Vector2(3, 2)]], "drag pans with incremental deltas, never taps")
	fresh()
	touch(1, true, Vector2.ZERO, true)
	drag(1, Vector2(100, 0))
	touch(9, true, Vector2(200, 0))
	drag(9, Vector2(220, 0))
	touch(9, false, Vector2(220, 0))
	touch(1, false, Vector2(100, 0))
	check(events == [["pan", Vector2(20, 0)]], "UI-started finger cannot pan or join world pinch")
	fresh()
	touch(5, true, Vector2.ZERO)
	touch(20, true, Vector2(100, 0))
	drag(20, Vector2(200, 0))
	check(events.size() == 1 and events[0] == ["pinch", Vector2(100, 0), 2.0], "pinch reports midpoint and distance ratio using touch indices")
	touch(20, false, Vector2(200, 0))
	drag(5, Vector2(3, 0))
	touch(5, false, Vector2(3, 0))
	check(events.size() == 2 and events[1] == ["pan", Vector2(3, 0)], "remaining finger pans without jump or tap")
	fresh()
	touch(0, true, Vector2.ZERO)
	touch(1, true, Vector2.ZERO)
	drag(1, Vector2(10, 0))
	drag(1, Vector2(20, 0))
	check(events == [["pinch", Vector2(10, 0), 2.0]], "zero-distance pinch safely establishes new baseline")
	fresh()
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(12, 0))
	check(events.is_empty(), "mouse uses touch threshold")
	button(MOUSE_BUTTON_LEFT, false, Vector2(12, 0))
	check(events == [["tap", Vector2(12, 0)]], "mouse tap on release")
	fresh()
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(20, 0))
	button(MOUSE_BUTTON_LEFT, false, Vector2(20, 0))
	button(MOUSE_BUTTON_RIGHT, true)
	motion(Vector2(1, 2))
	button(MOUSE_BUTTON_RIGHT, false, Vector2(1, 2))
	check(events == [["pan", Vector2(20, 0)], ["pan", Vector2(1, 2)]], "left drag and immediate right pan")
	fresh()
	button(MOUSE_BUTTON_LEFT, true, Vector2.ZERO, true)
	motion(Vector2(30, 0))
	button(MOUSE_BUTTON_LEFT, false, Vector2(30, 0))
	check(events.is_empty(), "UI mouse ownership persists")
	touch(0, true, Vector2.ZERO)
	button(MOUSE_BUTTON_LEFT, true)
	button(MOUSE_BUTTON_LEFT, false)
	touch(0, false, Vector2.ZERO)
	button(MOUSE_BUTTON_LEFT, true, Vector2.ZERO, false, -1)
	button(MOUSE_BUTTON_LEFT, false, Vector2.ZERO, false, -1)
	check(events == [["tap", Vector2.ZERO]], "touch and emulated mouse do not duplicate")
	fresh()
	button(MOUSE_BUTTON_LEFT, true)
	touch(0, true, Vector2.ZERO, false, -1)
	touch(0, false, Vector2.ZERO, false, -1)
	button(MOUSE_BUTTON_LEFT, false)
	check(events == [["tap", Vector2.ZERO]], "emulated touch does not duplicate real mouse")
	fresh()
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(30, 40))
	button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(30, 40))
	check(events.size() == 2 and events[0][0] == "pinch" and events[0][1] == Vector2(30, 40) and events[0][2] > 1.0 and is_equal_approx(events[0][2] * events[1][2], 1.0), "wheel emits reciprocal anchored zoom")
	fresh()
	key(KEY_Q)
	key(KEY_E)
	key(KEY_E, true, true)
	key(KEY_E, false)
	key(KEY_Q, true, false, true)
	check(events == [["rotate", -1], ["rotate", 1]], "rotation ignores repeat, release, and UI")
	fresh()
	touch(0, true, Vector2.ZERO)
	key(KEY_ESCAPE)
	drag(0, Vector2(30, 0))
	touch(0, false, Vector2.ZERO)
	check(events == [["cancel"]], "Escape clears pending gestures")
	fresh()
	button(MOUSE_BUTTON_LEFT, true)
	router.cancel()
	button(MOUSE_BUTTON_LEFT, false)
	touch(0, true, Vector2.ZERO)
	touch(0, false, Vector2.ZERO, false, 0, true)
	check(events == [["cancel"], ["cancel"]], "focus cancel and OS touch cancellation never tap")
	fresh()
	touch(0, true, Vector2.ZERO)
	touch(0, false, Vector2(30, 0))
	check(events.is_empty(), "large release displacement without drag event cannot tap")
	fresh()
	touch(0, true, Vector2.ZERO)
	drag(0, Vector2(20, 0), true)
	touch(0, false, Vector2(20, 0), true)
	check(events == [["pan", Vector2(20, 0)]], "world-owned drag continues over HUD")
	fresh()
	touch(0, true, Vector2.ZERO)
	touch(1, true, Vector2(100, 0))
	touch(2, true, Vector2(200, 0))
	drag(2, Vector2(300, 0))
	check(events.is_empty(), "third finger does not alter active pinch pair")
	touch(1, false, Vector2(100, 0))
	drag(2, Vector2(600, 0))
	check(events == [["pinch", Vector2(300, 0), 2.0]], "replacement pinch pair uses current positions")
	touch(0, false, Vector2.ZERO)
	touch(2, false, Vector2(600, 0))
	check(events.size() == 1, "all pinch participants suppress release taps")
	fresh()
	touch(0, true, Vector2.ZERO)
	touch(1, true, Vector2(100, 0))
	router.cancel()
	touch(0, false, Vector2.ZERO)
	touch(1, false, Vector2(100, 0))
	button(MOUSE_BUTTON_LEFT, true)
	button(MOUSE_BUTTON_LEFT, false)
	check(events == [["cancel"], ["tap", Vector2.ZERO]], "focus cancellation clears touch state and permits fresh mouse gesture")
	fresh()
	button(MOUSE_BUTTON_LEFT, true)
	touch(0, true, Vector2(10, 0))
	touch(0, false, Vector2(10, 0))
	button(MOUSE_BUTTON_LEFT, false)
	check(events == [["tap", Vector2(10, 0)]], "touch takeover discards pending mouse tap")
	fresh()
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2.ZERO, true)
	button(MOUSE_BUTTON_WHEEL_DOWN, false)
	drag(123, Vector2(50, 0))
	touch(123, false, Vector2(50, 0))
	check(events.is_empty(), "UI wheel, wheel release and orphan touch events ignored")
	print("mobile_input_test: %d failures" % failures)
	quit(1 if failures else 0)
