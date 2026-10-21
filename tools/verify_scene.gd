extends SceneTree

const SCENE_PATH := "res://scenes/DungeonPreview.tscn"
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_check(false, "The new 2D scene must exist")
		_finish()
		return
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		_check(false, "The 2D scene must load")
		_finish()
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var preview := scene.instantiate()
	viewport.add_child(preview)
	await process_frame
	await process_frame
	var dungeon = preview.get_node("Dungeon")
	var layout = dungeon.layout
	_check(layout.get_grid_size() == Vector2i(28, 18), "The approved layout is 28 x 18 cells")
	_check(layout.cell_size == 54 and layout.margin == 90, "Approved tile scale and margins")
	_check(dungeon.get_content_rect().size == Vector2(1692, 1152), "Approved composition dimensions")
	_check(not layout.has_floor(Vector2i(-1, 0)), "Outside the map is solid/empty")
	_check(not layout.has_floor(Vector2i(28, 18)), "Outside the far edge is solid/empty")
	var cells: Array[Vector2i] = layout.get_floor_cells()
	_check(cells.size() == 255, "The approved scene has exactly 255 floor tiles")
	var visited: Dictionary = {}
	var pending: Array[Vector2i] = [Vector2i(4, 5)]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		if visited.has(cell):
			continue
		visited[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if layout.has_floor(neighbor) and not visited.has(neighbor):
				pending.append(neighbor)
	_check(visited.size() == cells.size(), "Every floor cell is connected; no isolated chamber")
	for center in [Vector2i(4, 5), Vector2i(12, 1), Vector2i(23, 5), Vector2i(3, 13), Vector2i(12, 13), Vector2i(23, 13)]:
		_check(visited.has(center), "Room reachable at %s" % center)
	for x in range(8, 20):
		_check(layout.has_floor(Vector2i(x, 5)) and layout.has_floor(Vector2i(x, 6)), "Open two-cell main corridor at x=%d" % x)
	for y in range(7, 11):
		_check(layout.has_floor(Vector2i(12, y)) and layout.has_floor(Vector2i(13, y)), "Open vertical junction at y=%d" % y)
	for dimensions in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(800, 800), Vector2i(640, 360)]:
		viewport.size = dimensions
		await process_frame
		await process_frame
		var bounds: Rect2 = dungeon.get_content_rect()
		var transform: Transform2D = dungeon.get_global_transform_with_canvas()
		var start: Vector2 = transform * bounds.position
		var end: Vector2 = transform * bounds.end
		_check(start.x >= -1.0 and start.y >= -1.0 and end.x <= dimensions.x + 1.0 and end.y <= dimensions.y + 1.0,
			"Complete scene fits %s (start=%s, end=%s)" % [dimensions, start, end])
		_check(is_equal_approx(transform.x.length(), transform.y.length()), "Aspect ratio preserved at %s" % dimensions)
	viewport.queue_free()
	await process_frame
	_finish()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error("FAIL: " + failure)
	if failures.is_empty():
		print("PASS: 2D scene loads, rooms connect, corridors stay open, camera fits four viewport sizes")
	quit(0 if failures.is_empty() else 1)
