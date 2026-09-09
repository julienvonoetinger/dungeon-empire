extends SceneTree

func _initialize() -> void:
	var game = load("res://scripts/Main.gd").new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.dungeon.sync(game)
	var core: Node3D = game.dungeon._core_spin
	var light: float = game.dungeon._core_fill_base
	game.core_hp = 90
	game.dungeon.sync(game)
	if game.dungeon._core_fill_base >= light:
		printerr("FAIL: same-band core damage must update its presentation")
		quit(1)
		return
	game.core_hp = 15
	game.dungeon.sync(game)
	if game.dungeon._core_spin != core:
		printerr("FAIL: HP thresholds must not recreate the anomaly or restart its orbit")
		quit(1)
		return
	game.core_hp = 0
	game.dungeon.sync(game)
	assert(not core.get_node("Void").visible)
	assert(game.dungeon._fill.light_energy == 0.0)
	game._new_map()
	game.dungeon.sync(game)
	assert(game.dungeon._core_spin.get_node("Void").visible)
	print("OK: core health synchronization, orbit continuity, defeat and new game")
	game.queue_free()
	await process_frame
	quit()
