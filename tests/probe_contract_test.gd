extends SceneTree

const MainScript := preload("res://scripts/Main.gd")
const VisualProbes := preload("res://tests/probes/dungeon_visual_probes.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = MainScript.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	game.dungeon.sync(game)

	var core_grid := VisualProbes.core_anchor_grid(game)
	_check(core_grid.size() == 64, "Core anchor probe must report the complete 8x8 placement grid")
	_check(core_grid.has(Vector2i(0, 0)) and core_grid.has(Vector2i(14, 14)),
		"Core anchor probe must include both board corners")
	var boundary := VisualProbes.dungeon_boundary(game)
	_check(not bool(boundary.get("no_depth_test", true)),
		"boundary probe must expose depth-tested rendering")
	_check(float(boundary.get("min_x", 1.0)) < 0.0 and float(boundary.get("max_x", 0.0)) > float(game.COLS),
		"boundary probe must expose an outside-board wrap")

	game.queue_free()
	await process_frame
	print("OK: dungeon visual probes expose fast rendering invariants")
	quit()


func _check(condition: bool, message: String) -> void:
	if not condition:
		printerr("FAIL: ", message)
		quit(1)
