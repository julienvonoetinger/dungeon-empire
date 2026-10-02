extends SceneTree

func _initialize() -> void:
	var session = load("res://scripts/mobile/mobile_session.gd").new()
	if not session.has_method("memory_diagnostics"):
		printerr("FAIL: mobile memory diagnostics missing")
		session.free()
		quit(1)
		return
	assert(session.memory_diagnostics(10.0, false).is_empty())
	var sample: Dictionary = session.memory_diagnostics(0.0, true)
	assert(sample.has("video_bytes") and sample.has("system_available_bytes"))
	assert(sample.has("resources") and sample.has("fps") and sample.has("renderer"))
	assert(JSON.parse_string(JSON.stringify(sample)) is Dictionary)
	assert(session.memory_diagnostics(1.0, true).is_empty())
	assert(not session.memory_diagnostics(1.0, true).is_empty())
	assert(session.memory_diagnostics(0.0, true).is_empty())
	session.free()
	print("Mobile diagnostics test passed")
	quit()
