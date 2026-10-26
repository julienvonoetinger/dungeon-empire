extends SceneTree
## Static native visual check. Does not create a game session or access saves.
const OUT := "res://docs/reference/door-redesign/seal-v1/painted-v3/native/"
var viewport: SubViewport
var records: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
	create_timer(20.0).timeout.connect(_timeout)
	_capture.call_deferred()

func _timeout() -> void:
	push_error("Seal capture did not complete within 20 seconds")
	quit(2)

func _save(label: String, dungeon: Node2D) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if viewport.get_texture().get_image().save_png(OUT + label + ".png") != OK:
		failed = true
		push_error("Could not save seal door capture " + label)
	var sprites: Array[Dictionary] = []
	var cut_rails := 0
	var prepared := dungeon.get_node_or_null("PreparedSprites")
	if prepared == null:
		failed = true
		push_error("Missing prepared sprites in seal capture")
		return
	for child in prepared.get_children():
		if child is Sprite2D and str(child.get_meta("prepared_id", "")).begins_with("wall-") and child.material != null:
			cut_rails += 1
		if child is Sprite2D and str(child.get_meta("prepared_id", "")).begins_with("door-"):
			sprites.append({"id": child.get_meta("prepared_id"), "position": [child.position.x, child.position.y], "z": child.z_index, "size": [child.texture.get_width(), child.texture.get_height()]})
	records.append({"capture": label, "door_parts": sprites, "cut_rails": cut_rails})
	print("Captured ", label, " (", sprites.size(), " door parts)")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/WireframeDoorCross.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var camera: Camera2D = scene.get_node("Camera2D")
	var dungeon: Node2D = scene.get_node("Dungeon")
	await _save("cross-native", dungeon)
	viewport.size = Vector2i(640, 520)
	for cell: Vector2i in dungeon.door_cells:
		var direction: String = dungeon.door_cells[cell]
		camera.position = dungeon.grid_to_local(Vector2(cell) + Vector2(.5, .5)) + Vector2(0, -40)
		camera.zoom = Vector2.ONE * 2.0
		camera.force_update_scroll()
		await _save("door-" + direction + "-detail", dungeon)
		if direction == "south" and "--contact-diagnostic" in OS.get_cmdline_user_args():
			var draw_order: Array[Dictionary] = []
			for child in dungeon.get_node("PreparedSprites").get_children():
				if child is Sprite2D:
					var segment: Dictionary = child.get_meta("wall_segment", {})
					draw_order.append({"id": child.get_meta("prepared_id", ""), "position": [child.position.x, child.position.y], "scale": [child.scale.x, child.scale.y], "layer": child.z_index, "cut": child.material != null, "span": [segment.span.x, segment.span.y] if not segment.is_empty() else []})
			var diagnostic := FileAccess.open(OUT + "draw-order.json", FileAccess.WRITE)
			diagnostic.store_string(JSON.stringify(draw_order, "\t"))
		camera.zoom = Vector2.ONE * .75
		camera.force_update_scroll()
		await _save("door-" + direction + "-native", dungeon)
	var original_doors: Dictionary[Vector2i, String] = dungeon.door_cells.duplicate()
	var no_doors: Dictionary[Vector2i, String] = {}
	dungeon.door_cells = no_doors
	await process_frame
	await _save("doors-removed", dungeon)
	if not dungeon._door_wall_junctions.is_empty():
		failed = true
		push_error("Removed doors left stale rail cutouts")
	dungeon.door_cells = original_doors
	await process_frame
	await _save("doors-restored", dungeon)
	viewport.remove_child(scene)
	scene.free()
	var file := FileAccess.open(OUT + "observations.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(records, "\t") + "\n")
	quit(1 if failed else 0)
