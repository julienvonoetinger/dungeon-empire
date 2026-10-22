extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var overlay := scene.get_node_or_null("ProbeOverlay")
	_check(overlay != null,"The main scene includes the switchable spatial probe inspector")
	if overlay != null:
		_check(overlay.has_method("set_active"),"The probe inspector script loads successfully")
	if overlay != null and overlay.has_method("set_active"):
		await _exercise(scene,overlay)
	scene.queue_free()
	await process_frame
	for failure in failures:
		push_error("FAIL: "+failure)
	if failures.is_empty():
		print("PASS: visible probes, live placement inspection and deliberate fault detection")
	quit(0 if failures.is_empty() else 1)

func _exercise(scene: Node2D,overlay: Node) -> void:
	var model = load("res://scripts/dungeon_probes.gd")
	var dungeon: Node2D = scene.get_node("Dungeon")
	_check(not overlay.active,"Probe overlay starts disabled")
	var baseline: Dictionary = model.inspect(dungeon)
	_check(baseline.elements.size() == 858,"Every sprite and light has an inspectable entry")
	_check(baseline.probes.size() == 644,"Fixed spatial samples include the 635 masonry and 9 heart checks")
	_check(baseline.failures.is_empty(),"The approved scene passes the spatial probes")
	var ids: Array = baseline.elements.map(func(e: Dictionary): return e.id)
	var unique := {}
	for id in ids:
		unique[id] = true
	_check(unique.size() == ids.size(),"Every element ID is unique")
	var sphere: Dictionary = _element(baseline,"Heart/HeartSprite")
	_check(sphere.texture == "res://assets/dungeon/alpha-kit/heart.png","Runtime atlas sprites retain their backing PNG path in the inspector")
	_check(sphere.get("source_region",Rect2()) == sphere.node.texture.region,"Inspector records the complete atlas region separately from local UVs")
	var heart_report: Dictionary = model.report(baseline).elements.filter(func(e: Dictionary): return e.id == "Heart/HeartSprite")[0]
	_check(heart_report.texture == sphere.node.texture.atlas.resource_path and heart_report.get("source_region",[]).size() == 4,"JSON exports backing PNG and numeric atlas region")
	_check(sphere.anchor == Vector2(2258,637),"Heart child origins include their inherited parent position")
	_check(sphere.bounds.has_point(Vector2(2368,691)),"The catalog bounds include the visible vortex")
	_check(model.pick(baseline.elements,Vector2(2368,691),"all").id == "Heart/HeartSprite","Picking prioritizes the actual heart contour above the floor")
	_check(model.pick(baseline.elements,Vector2(2368,691),"floor").kind == "floor","The category filter can inspect the substrate beneath the heart")
	_check(model.pick(baseline.elements,Vector2(2438,670),"all").kind == "floor","Picking ignores translucent glow bounds outside the actual heart contour")
	_check(model.pick(baseline.elements,Vector2.ZERO,"all").is_empty(),"Empty space does not pick a bounding-box neighbor")
	_check(model.pick(baseline.elements,Vector2(430,420)).id == "EntryTorchWest","Sprite support can be selected as an entrance element")
	_check(model.pick(baseline.elements,Vector2(373,310)).id != "EntryTorchWest","Transparent sprite margin does not intercept masonry selection")
	var torch: Sprite2D = dungeon.get_node("EntryTorchWest")
	torch.hide()
	_check(model.inspect(dungeon).failures.any(func(p: Dictionary): return p.id.begins_with("torch-foot/")),"A missing torch fails its independent foot probe")
	torch.show()
	torch.position.x += 50
	_check(model.inspect(dungeon).failures.any(func(p: Dictionary): return p.id.begins_with("torch-foot/")),"A displaced torch fails its independent foot probe")
	torch.position.x -= 50
	var wall: Sprite2D = model.pick(baseline.elements,Vector2(2810,560),"wall").node
	_check(wall != null,"Regression locates an east cap sprite")
	if wall != null:
		var old_position := wall.position
		wall.position.x += 100
		_check(not model.inspect(dungeon).failures.is_empty(),"Displaced east cap fails independent probes")
		wall.position = old_position
		var old_texture := wall.texture
		var wrong: AtlasTexture = old_texture.duplicate()
		wrong.region.position.x += 40
		wall.texture = wrong
		_check(not model.inspect(dungeon).failures.is_empty(),"Wrong atlas region fails declared complete sprite mapping")
		wall.texture = old_texture
		var original_scale := wall.scale
		wall.scale.x *= 1.3
		_check(not model.inspect(dungeon).failures.is_empty(),"Non-uniform scale is rejected")
		wall.scale = original_scale
		var old_offset := wall.offset
		wall.offset.x += 500
		_check(not model.inspect(dungeon).failures.is_empty(),"Sprite drawing offset affects alpha coverage")
		wall.offset = old_offset
	var floors: Array = dungeon.get_surface_pieces().filter(func(p): return p.get_meta("kind") == "floor")
	for part in floors: part.hide()
	_check(not model.inspect(dungeon).failures.is_empty(),"Missing floor and substrate fail coverage probes")
	for part in floors: part.show()
	var heart: Node2D = dungeon.get_node("Heart")
	heart.position.x += 80
	var displaced_heart: Dictionary = model.inspect(dungeon)
	_check(displaced_heart.failures.any(func(p: Dictionary): return p.id == "heart/anchor"),"Moving the heart fails its fixed expected anchor")
	heart.position.x -= 80
	# The inspector reports dungeon-local coordinates even if the whole dungeon moves.
	dungeon.position = Vector2(21,34)
	dungeon.scale = Vector2(1.2,1.2)
	dungeon.rotation = 0.2
	_check(model.inspect(dungeon).failures.is_empty(),"Dungeon parent transforms do not corrupt local probes")
	dungeon.position = Vector2.ZERO
	dungeon.scale = Vector2.ONE
	dungeon.rotation = 0.0
	overlay.set_active(true)
	_check(overlay.active,"The diagnostic view can be enabled")
	overlay.select_at(Vector2(2368,691))
	_check(overlay.selected_id == "Heart/HeartSprite","The displayed selection matches the picked contour")
	overlay.probe_toggle.button_pressed = false
	overlay.select_at(Vector2(2368,691))
	_check(overlay.selected_probe_id.is_empty(),"Hidden probes cannot appear as an invisible click selection")
	overlay.probe_toggle.button_pressed = true
	overlay.category = "floor"
	overlay.select_at(Vector2(2368,691))
	_check(not overlay.selected_probe_id.begins_with("heart/"),"Category-hidden probes do not intercept the selection")
	overlay.category = "all"
	overlay.select_at(Vector2(2368,691))
	dungeon.refresh_preview()
	await process_frame
	await process_frame
	await process_frame
	_check(overlay.selected_id == "Heart/HeartSprite","Selection survives dungeon regeneration by stable ID")
	_check(overlay.snapshot.elements.all(func(e: Dictionary): return is_instance_valid(e.node) and e.node.is_inside_tree()),"Automatic refresh replaces every stale generated-node reference")
	_check(model.inspect(dungeon).elements.map(func(e: Dictionary): return e.id) == ids,"Rebuilding retains repeatable element IDs")
	_check(model.inspect(dungeon).failures.is_empty(),"Restoring all deliberate faults restores passing probes")
	overlay.set_active(false)
	_check(not overlay.active,"The diagnostic view can be disabled")
	var report: Dictionary = model.report(baseline)
	_check(report.elements[0].anchor is Array,"JSON coordinates are numeric arrays")
	_check(report.probes[0].position is Array,"Probe report keeps numeric test positions")
	_check(JSON.parse_string(JSON.stringify(report)).elements.size() == 858,"The complete report survives JSON serialization")

func _element(snapshot: Dictionary,id: String) -> Dictionary:
	for entry: Dictionary in snapshot.elements:
		if entry.id == id:
			return entry
	return {}

func _check(condition: bool,message: String) -> void:
	if not condition:
		failures.append(message)
