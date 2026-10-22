extends SceneTree

## Requires a real renderer. Verifies the actual scene, never an alternate test draw path.
const SCENE := "res://scenes/PerspectiveRoom.tscn"
const FRAME := Rect2i(0, 120, 560, 510)
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = FRAME.size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene = load(SCENE).instantiate()
	viewport.add_child(scene)
	await process_frame
	_check(scene.has_method("get_source_frame"), "Scene exposes the original reference frame")
	if not failures.is_empty():
		_finish()
		return
	_check(scene.get_source_frame() == FRAME, "Reference frame has the original entrance and corner")
	var pieces: Array = scene.get_art_pieces()
	_check(pieces.size() >= 25, "Architecture is assembled from independent elements")
	var coverage := PackedByteArray()
	coverage.resize(FRAME.size.x * FRAME.size.y)
	for piece: Polygon2D in pieces:
		_check(piece.scale == Vector2.ONE, "No individual stretching: " + str(piece.name))
		_check(piece.polygon.size() == piece.uv.size(), "Vertices and UV count agree: " + str(piece.name))
		for i in range(piece.polygon.size()):
			var source: Vector2 = piece.uv[i]
			var target: Vector2 = piece.polygon[i] + piece.position + Vector2(FRAME.position)
			_check(source.is_equal_approx(target), "Source proportions and placement: " + str(piece.name))
		var bounds := Rect2(piece.polygon[0] + piece.position, Vector2.ZERO)
		for point in piece.polygon:
			bounds = bounds.expand(point + piece.position)
		_check(bounds.size.x * bounds.size.y < FRAME.size.x * FRAME.size.y * 0.35,
			"No piece substitutes a whole reference image: " + str(piece.name))
		for y in range(maxi(0, int(bounds.position.y)), mini(FRAME.size.y, int(ceil(bounds.end.y)))):
			for x in range(maxi(0, int(bounds.position.x)), mini(FRAME.size.x, int(ceil(bounds.end.x)))):
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5) - piece.position, piece.polygon):
					coverage[y * FRAME.size.x + x] = 1
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := viewport.get_texture().get_image()
	capture.save_png("res://artifacts/reference-render.png")
	var reference := (load("res://assets/dungeon/perspective/reference-atlas.png") as Texture2D).get_image()
	var error_sum := 0.0
	var compared := 0
	var wrong := 0
	var missing := 0
	var all_error := 0.0
	for y in range(FRAME.size.y):
		for x in range(FRAME.size.x):
			var actual := capture.get_pixel(x, y)
			var expected := reference.get_pixel(x + FRAME.position.x, y + FRAME.position.y)
			var delta := maxf(absf(actual.r - expected.r), maxf(absf(actual.g - expected.g), absf(actual.b - expected.b))) * 255.0
			all_error += delta
			# Independent oracle: derive expected visible architecture from the
			# reference, not the implementation's own coverage polygons.
			# Empty blue haze in this source reaches 47/255; 48 separates it
			# from the visible masonry. Whole-frame error is reported separately.
			if maxf(expected.r, maxf(expected.g, expected.b)) < 48.0 / 255.0:
				continue
			if coverage[y * FRAME.size.x + x] == 0:
				missing += 1
			error_sum += delta
			compared += 1
			if delta > 3.0:
				wrong += 1
	var mean_error := error_sum / maxf(1, compared)
	var wrong_ratio := float(wrong) / maxf(1, compared)
	print("Reference comparison: %d elements, %d reference architecture pixels, mean max-channel error %.4f/255, %.4f%% pixels > 3/255, %d missing pixels, whole-frame error %.4f/255" % [pieces.size(), compared, mean_error, wrong_ratio * 100, missing, all_error / (FRAME.size.x * FRAME.size.y)])
	_check(compared > 180000, "The assembled architecture covers the expected portion of the frame")
	_check(mean_error < 0.3 and wrong_ratio < 0.001, "Rendered architecture matches reference within 3/255 on 99.9% of pixels")
	_check(missing < 150, "Reference architecture has no missing contour strips or joints")
	# Hiding one real element must alter only its own area. This catches a
	# complete screenshot underneath decorative or invisible component nodes.
	var door := scene.get_node("WoodenDoor") as Polygon2D
	door.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var without_door := viewport.get_texture().get_image()
	_check(without_door.get_pixel(234, 162).r < capture.get_pixel(234, 162).r - 0.15,
		"Removing the door removes its image")
	_check(without_door.get_pixel(350, 360).is_equal_approx(capture.get_pixel(350, 360)),
		"Removing the door preserves the neighboring floor")
	for piece: Polygon2D in pieces:
		piece.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var empty := viewport.get_texture().get_image()
	var leaked := 0
	for y in range(FRAME.size.y):
		for x in range(FRAME.size.x):
			var pixel := empty.get_pixel(x,y)
			if maxf(pixel.r, maxf(pixel.g,pixel.b)) > 26.0 / 255.0:
				leaked += 1
	_check(leaked == 0, "No full-scene illustration remains behind the separate elements")
	for piece: Polygon2D in pieces:
		piece.show()
	var report := {
		"source_frame": [FRAME.position.x, FRAME.position.y, FRAME.size.x, FRAME.size.y],
		"elements": pieces.size(), "reference_architecture_pixels": compared,
		"mean_max_channel_error_255": mean_error, "pixels_over_3_255": wrong,
		"missing_architecture_pixels": missing,
		"whole_frame_mean_max_channel_error_255": all_error / (FRAME.size.x * FRAME.size.y),
		"source_background_max_channel_threshold_255": 48,
		"hidden_elements_leaked_pixels": leaked,
	}
	for dimensions in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(640, 360)]:
		viewport.size = dimensions
		await process_frame
		await process_frame
		var transform: Transform2D = scene.get_global_transform_with_canvas()
		var start: Vector2 = transform * Vector2.ZERO
		var end: Vector2 = transform * Vector2(FRAME.size)
		_check(start.x >= -1 and start.y >= -1 and end.x <= dimensions.x + 1 and end.y <= dimensions.y + 1,
			"Whole reference composition fits " + str(dimensions))
		_check(is_equal_approx(transform.x.length(), transform.y.length()), "Uniform camera scale at " + str(dimensions))
	viewport.queue_free()
	await process_frame
	report["failures"] = failures
	var report_file := FileAccess.open("res://artifacts/reference-report.json", FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "\t"))
	_finish()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error("FAIL: " + failure)
	if failures.is_empty():
		print("PASS: reference geometry, actual GPU pixels and responsive framing")
	quit(0 if failures.is_empty() else 1)
