extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var path := "res://scripts/mobile/mobile_camera_controller.gd"
	if not ResourceLoader.exists(path):
		check(false, "MobileCameraController must exist")
		quit(1)
		return
	var camera = load(path).new()
	check(camera.zoom == 2.0 and camera.yaw == 45.0, "default framing")
	check(camera.pan == Vector2.ZERO and not camera.follow_enabled, "default pan/follow")
	camera.zoom_by(1.5)
	check(is_equal_approx(camera.zoom, 3.0), "zoom is multiplicative")
	camera.zoom_by(100.0)
	check(camera.zoom == 4.0, "upper zoom bound")
	camera.zoom_by(0.001)
	check(camera.zoom == 1.2, "lower zoom bound")
	for factor in [0.0, -1.0, INF, NAN]:
		camera.zoom_by(factor)
		check(camera.zoom == 1.2, "invalid zoom factor ignored")
	camera.rotate_steps(1)
	check(camera.yaw == 135.0, "positive quarter turn")
	camera.rotate_steps(-2)
	check(camera.yaw == 315.0, "negative turns wrap")
	camera.rotate_steps(9)
	check(camera.yaw == 45.0, "multiple turns wrap")
	camera.follow_enabled = true
	camera.pan_by(Vector2(12, -7))
	camera.pan_by(Vector2(-2, 3))
	check(camera.pan == Vector2(10, -4), "pan accumulates input deltas")
	check(not camera.follow_enabled, "manual pan cancels follow")
	camera.follow_enabled = true
	camera.zoom_by(2.0)
	camera.rotate_steps(1)
	check(camera.follow_enabled, "zoom and rotation preserve follow")
	camera.reset()
	check(camera.zoom == 2.0 and camera.yaw == 45.0, "reset framing")
	check(camera.pan == Vector2.ZERO and not camera.follow_enabled, "reset pan/follow")
	print("mobile_camera_test: %d failures" % failures)
	quit(1 if failures else 0)
