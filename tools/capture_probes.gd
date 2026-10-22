extends SceneTree

const MODEL := preload("res://scripts/dungeon_probes.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600,1050)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(scene)
	await _frame()
	var baseline := viewport.get_texture().get_image()
	var overlay := scene.get_node("ProbeOverlay")
	var dungeon: Node2D = scene.get_node("Dungeon")
	_key(viewport,KEY_F3)
	await _frame()
	_check(overlay.active,"F3 enables the actual diagnostic overlay")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = dungeon.get_global_transform_with_canvas()*Vector2(2368,691)
	viewport.push_input(click,true)
	await _frame()
	_check(overlay.selected_id == "Heart/HeartSprite","A real viewport click selects the vortex in dungeon coordinates")
	_check(overlay.get_node("Toolbar").size.y < 180,"The toolbar stays compact rather than covering the map")
	_check(overlay.get_node("Details").get_global_rect().end.y <= viewport.size.y+1,"The selected element coordinates remain on screen")
	var annotated := viewport.get_texture().get_image()
	_check(annotated.get_data() != baseline.get_data(),"Visible markers and controls are rendered")
	_save(annotated,"dungeon-probes.png")
	var file := FileAccess.open("res://artifacts/dungeon-probes.json",FileAccess.WRITE)
	_check(file != null,"The spatial report can be written")
	if file != null:
		file.store_string(JSON.stringify(MODEL.report(overlay.snapshot),"\t"))
	_key(viewport,KEY_F3)
	await _frame()
	_check(not overlay.active,"F3 disables the diagnostic overlay")
	_check(viewport.get_texture().get_image().get_data() == baseline.get_data(),"Turning probes off restores the exact normal pixels")
	# A close-up uses the same overlay/camera transform as the full view.
	overlay.set_active(true)
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position = Vector2(2590,680)
	camera.zoom = Vector2.ONE*1.6
	camera.force_update_scroll()
	overlay.category = "wall"
	overlay.select_at(Vector2(2810,560))
	await _frame()
	_save(viewport.get_texture().get_image(),"probe-wall-detail.png")
	# A deliberately displaced stone must produce red failed points at the old
	# expected positions. This is a temporary test fixture, never a saved scene.
	var selected: Dictionary = overlay._selected()
	_check(not selected.is_empty(),"The close-up identifies the east wall stone")
	if not selected.is_empty():
		var node: Node2D = selected.node
		var original := node.position
		node.position.x += 100
		_key(viewport,KEY_R)
		await _frame()
		_check(not overlay.snapshot.failures.is_empty(),"Refresh shows failed probes for the deliberately displaced stone")
		var label_rects: Array[Rect2] = []
		for probe: Dictionary in overlay.snapshot.failures:
			var point: Vector2 = dungeon.get_global_transform_with_canvas()*probe.position
			var label: Rect2 = overlay.failure_label_rect(point,probe.id,label_rects)
			_check(label.has_area(),"Each nearby failed probe receives a visible label")
			_check(not label_rects.any(func(rect: Rect2): return rect.intersects(label)),"Failed probe labels never overlap")
			label_rects.append(label)
		_save(viewport.get_texture().get_image(),"probe-failure-example.png")
		node.position = original
		overlay.refresh()
	# Resizing must leave usable controls in the viewport.
	for dimensions in [Vector2i(720,1280),Vector2i(640,360)]:
		viewport.size = dimensions
		await _frame()
		await _frame()
		var toolbar := overlay.get_node("Toolbar") as Control
		_check(toolbar.position.x+toolbar.size.x <= dimensions.x+1,"Diagnostic toolbar fits " + str(dimensions))
		var detail := overlay.get_node("Details") as Control
		_check(detail.position.x+detail.size.x <= dimensions.x+1,"Selection panel fits " + str(dimensions))
	viewport.queue_free()
	await process_frame
	for failure in failures:
		push_error("FAIL: "+failure)
	if failures.is_empty():
		print("PASS: GPU probe overlays, F3/click/R input, failure markers and exact disabled pixels")
	quit(0 if failures.is_empty() else 1)

func _key(viewport: SubViewport,key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	viewport.push_input(event,true)

func _frame() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw

func _save(image: Image,name: String) -> void:
	_check(image.save_png("res://artifacts/"+name) == OK,"Capture written: "+name)

func _check(condition: bool,message: String) -> void:
	if not condition:
		failures.append(message)
