extends "res://tests/labyrinth_integration_test.gd"

func _run() -> void:
	await process_frame
	game.set_process(false)
	_build_labyrinth()
	await _snapshot("core_no_floor_rays", game._core_origin())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
