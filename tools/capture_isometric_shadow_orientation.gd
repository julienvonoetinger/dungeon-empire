extends SceneTree
## Visual review of runtime placement changes on one live scene, no assertions.
const OUT := "res://docs/reference/isometric-review/painted-v1/heart-shadow-v6/"

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT + "captures")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/MobileReference.tscn").instantiate()
	viewport.add_child(scene)
	var dungeon: Node2D = scene.get_node("Dungeon")
	var camera: Camera2D = scene.get_node("Camera2D")
	var cases := [
		{"id":"reference", "heart":Vector2(1.5,1), "north":[Vector2i(1,0)], "west":[Vector2i(0,1)], "lights":true},
		{"id":"heart-moved-left", "heart":Vector2(.9,1), "north":[Vector2i(1,0)], "west":[Vector2i(0,1)], "lights":true},
		{"id":"torch-moved", "heart":Vector2(1.5,1), "north":[Vector2i(0,0)], "west":[], "lights":true},
		{"id":"near-edge-contact", "heart":Vector2(.9,1), "north":[Vector2i(0,0)], "west":[], "lights":true},
		{"id":"lights-off", "heart":Vector2(1.5,1), "north":[Vector2i(1,0)], "west":[Vector2i(0,1)], "lights":false},
		{"id":"outside-light-range", "heart":Vector2(1.5,1), "north":[], "west":[Vector2i(0,1)], "lights":true},
		{"id":"no-torches", "heart":Vector2(1.5,1), "north":[], "west":[], "lights":true}
	]
	var observations := []
	for view in cases:
		var north: Array[Vector2i] = []
		var west: Array[Vector2i] = []
		north.assign(view.north)
		west.assign(view.west)
		dungeon.set("heart_positions", PackedVector2Array([view.heart]))
		dungeon.set("torch_north_cells", north)
		dungeon.set("torch_west_cells", west)
		dungeon.set("torch_lights_enabled", view.lights)
		# Use the normal deferred setters, not a special shadow-selection path.
		await process_frame
		await process_frame
		camera.position = dungeon.grid_to_local(view.heart)
		camera.zoom = Vector2.ONE * .75
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(OUT + "captures/" + view.id + ".png")
		if error != OK:
			push_error("Could not save orientation capture: " + view.id)
			quit(1)
			return
		var shadows := []
		for child in dungeon.get_node("PreparedSprites").get_children():
			if str(child.name).begins_with("heart_shadow"):
				shadows.append({"sprite":str(child.name), "source":child.get_meta("shadow_source", "contact-only")})
		observations.append({"id":view.id,"heart":[view.heart.x,view.heart.y],"lights":view.lights,"shadows":shadows})
		print("Captured ", view.id, ": ", shadows)
	var file := FileAccess.open(OUT + "observations.json", FileAccess.WRITE)
	if file == null:
		push_error("Could not write shadow observations")
		quit(1)
		return
	file.store_string(JSON.stringify(observations,"\t") + "\n")
	quit()
