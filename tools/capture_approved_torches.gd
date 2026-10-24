extends SceneTree
## Visual captures only, using the production catalogue and renderer.
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
const OUT := "res://docs/reference/mobile-light-review/painted-v2/integration/captures/"
var viewport: SubViewport
var failed := false

func _initialize() -> void:
	_capture.call_deferred()

func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(OUT + name + ".png")
	if error != OK:
		failed = true
		push_error("Cannot save torch integration view: " + name)
	else:
		print("Captured ", name)

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var reference: Node2D = load("res://scenes/MobileReference.tscn").instantiate()
	viewport.add_child(reference)
	await _save("MobileReference-lit")
	var dungeon = reference.get_node("Dungeon")
	dungeon.torch_lights_enabled = false
	await process_frame
	await _save("MobileReference-unlit")
	dungeon.torch_lights_enabled = true
	await process_frame
	await _save("MobileReference-relit")
	viewport.remove_child(reference)
	reference.free()
	# Same geometry, placement and camera as the frozen appearance review.
	var scene := Node2D.new()
	viewport.add_child(scene)
	var study := RENDERER.new()
	scene.add_child(study)
	var camera := Camera2D.new()
	camera.position = Vector2(384,220)
	camera.zoom = Vector2.ONE * .75
	scene.add_child(camera)
	var cells := {}
	for y in 2:
		for x in 3:
			cells[Vector2i(x,y)] = true
	var plan := {"cells":cells, "openings":{}, "torch_north_cells":[Vector2i(1,0)], "torch_west_cells":[Vector2i(0,1)]}
	for lit in [false,true]:
		plan["torch_lights_enabled"] = lit
		study.render_plan(plan, {}, false)
		await _save("approved-room-lit" if lit else "approved-room-unlit")
	viewport.remove_child(scene)
	scene.free()
	for orientation in 2:
		var standalone: Node2D = load("res://scenes/DungeonTorch.tscn").instantiate()
		standalone.orientation = orientation
		viewport.add_child(standalone)
		var close_camera := Camera2D.new()
		close_camera.position = standalone.get_content_rect().get_center()
		close_camera.zoom = Vector2.ONE * .75
		standalone.add_child(close_camera)
		await _save("standalone-horizontal" if orientation == 0 else "standalone-vertical")
		viewport.remove_child(standalone)
		standalone.free()
	quit(1 if failed else 0)
