extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var dungeon = scene.get_node("Dungeon")
	var parts: Array = dungeon.get_surface_pieces()
	var cores := parts.filter(func(p): return p.get_meta("wall_layer","") == "core")
	var edges := parts.filter(func(p): return p.get_meta("wall_layer","") == "exterior")
	check(not cores.is_empty(),"Side walls expose independent core sprites")
	check(not edges.is_empty(),"Exterior backing has separate sprites")
	for core in cores:
		check(is_equal_approx(core.get_meta("body_size").x,68),"Wall core is 68 px, without baked outside brick row")
		var core_body := Rect2(core.position,core.get_meta("body_size"))
		for pier in parts.filter(func(p): return p.get_meta("kind","") == "pier"):
			if absf(pier.get_meta("core_x",pier.position.x)-core.position.x) < 1:
				check(core_body.end.y <= pier.position.y+0.01 or core_body.position.y >= pier.position.y+pier.get_meta("body_size").y-0.01,"Core stones do not frame the column with a second bright outline")
	for edge in edges:
		var body := Rect2(edge.position,edge.get_meta("body_size"))
		var span: Vector2 = edge.get_meta("exposed_span")
		check(body.position.y >= span.x-0.01 and body.end.y <= span.y+0.01,"Complete edge stays inside exposed span")
		for wall in parts.filter(func(p): return p.get_meta("kind","") == "wall" and p.get_meta("wall_layer","").is_empty()):
			check(not body.grow(-0.01).intersects(Rect2(wall.position,wall.get_meta("body_size"))),"Exterior edge never crosses a horizontal facade")
		for pier in parts.filter(func(p): return p.get_meta("kind","") == "pier"):
			var pier_body := Rect2(pier.position,pier.get_meta("body_size"))
			if not str(pier.name).begins_with("SidePier") and absf(pier.position.x-edge.get_meta("core_x")) < 1:
				check(body.end.y <= pier_body.position.y+0.01 or body.position.y >= pier_body.end.y-0.01,"Outside edge stops at the adjacent corner pier")
	for point in [Vector2(177,300),Vector2(177,940),Vector2(1008,630)]:
		check(not edges.any(func(p): return Rect2(p.position,p.get_meta("body_size")).has_point(point)),"No outside ladder through facade/corner at "+str(point))
	var core_signature := cores.map(func(p): return [p.position,p.texture,p.scale])
	for edge in edges: edge.hide()
	check(cores.all(func(p): return p.visible),"Removing outer border preserves all wall cores")
	check(cores.map(func(p): return [p.position,p.texture,p.scale]) == core_signature,"Exterior visibility cannot change core placement")
	for edge in edges: edge.show()
	for failure in failures: push_error("FAIL: "+failure)
	print("Wall layers: ",cores.size()," cores / ",edges.size()," edges; ",failures.size()," failures")
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
