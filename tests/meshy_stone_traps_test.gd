extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var expected := {
		"spike": {"armed": "paver_v3/spike_armed.glb", "sprung": "paver_v3/spike_sprung.glb", "broken": "paver_v3/spike_broken.glb"},
		"snare": {"armed": "paver_v3/snare_armed.glb", "sprung": "paver_v3/snare_sprung.glb", "broken": "paver_v3/snare_broken.glb"},
		"void": {"armed": "paver_v3/void_armed.glb", "sprung": "paver_v3/void_sprung.glb", "broken": "paver_v3/void_broken.glb"},
	}
	for family in ["spike", "snare", "void"]:
		for state in ["armed", "sprung", "broken"]:
			var path: String = "res://assets/models/traps/" + str(expected[family][state])
			if not ResourceLoader.exists(path):
				printerr("FAIL: missing real Meshy model ", path)
				quit(1)
				return
	var script = load("res://scripts/world/meshy_stone_trap.gd")
	for family in ["spike", "snare", "void"]:
		var trap = script.new()
		root.add_child(trap)
		assert(trap.configure(family, "armed"))
		var rest: Transform3D = trap.model.transform
		for state in ["sprung", "broken", "armed"]:
			assert(trap.set_state(state))
			await process_frame
			assert(not trap.has_node("TrapFrame"), "%s must directly replace its 1x1 floor tile" % family)
			var suffix: String = expected[family][state]
			assert(trap.model.scene_file_path.ends_with(suffix))
			var bounds: AABB = trap.model_bounds()
			assert(bounds.has_volume(), "%s %s must remain visually distinct" % [family, state])
			assert(absf(bounds.position.x) < 0.002 and absf(bounds.end.x - 1.0) < 0.002,
				"%s %s must fill the cell width without a gutter" % [family, state])
			assert(absf(bounds.position.z) < 0.002 and absf(bounds.end.z - 1.0) < 0.002,
				"%s %s must fill the cell depth without a gutter" % [family, state])
			assert(absf(trap.measured_walking_height() - 0.175) < 0.006,
				"%s %s base surface must be flush with the 1x1 floor" % [family, state])
			if state == "armed":
				assert(trap.model.transform.is_equal_approx(rest), "repair must restore exactly the armed fit")
		trap.queue_free()
		await process_frame
	print("OK: nine detailed Meshy 1x1 replacements share a flush paver border, plus repair")
	quit()
