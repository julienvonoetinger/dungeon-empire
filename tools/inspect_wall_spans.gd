extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var d = scene.get_node("Dungeon")
	var lengths: Array = []
	for run in d._side_runs:
		var spans: Array[Vector2] = [Vector2(run.start,run.end)]
		for p in d.get_surface_pieces():
			if p.get_meta("kind") == "pier" and absf(p.position.x-run.core_x)<1:
				spans = d._without_span(spans,Vector2(p.position.y,p.position.y+p.get_meta("body_size").y))
		for s in spans: lengths.append(snappedf(s.y-s.x,0.01))
	lengths.sort()
	print(lengths)
	quit()
