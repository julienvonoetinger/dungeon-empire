extends "res://tests/labyrinth_integration_test.gd"

func _run() -> void:
	await process_frame
	game.set_process(false)
	_build_labyrinth()
	for point in [SPIKE, SNARE, VOID]:
		await _snapshot("meshy_%s_armed" % _label(point), point)
		if OS.get_cmdline_user_args().has("--states"):
			var trap = game.dungeon._cells[point].get_node("StoneTrap")
			for state in ["sprung", "broken"]:
				if ResourceLoader.exists("res://assets/models/traps/stone_v2/%s_%s.glb" % [_label(point), state]):
					trap.set_state(state)
					await _snapshot("meshy_%s_%s" % [_label(point), state], point)
			trap.set_state("armed")
	game.queue_free()
	await process_frame
	quit()
