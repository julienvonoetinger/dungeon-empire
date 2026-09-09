extends "res://tests/labyrinth_integration_test.gd"

func _run() -> void:
	await process_frame
	game.set_process(false)
	_build_labyrinth()
	for state in [["closed", 60], ["damaged", 30], ["destroyed", 0]]:
		game.door_hp[DOOR] = state[1]
		game.dungeon.sync(game)
		await _snapshot("meshy_door_%s" % state[0], DOOR)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
