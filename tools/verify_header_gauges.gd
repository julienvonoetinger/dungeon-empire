extends SceneTree
## Pixel-level gauge containment at fractional mobile scales; no game or saves.
const HEADER = preload("res://scripts/game/ui/hud_master_header.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out := "res://artifacts/header-gauges-before/" if "--before" in OS.get_cmdline_user_args() else "res://artifacts/header-gauges-after/"
	DirAccess.make_dir_recursive_absolute(out)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var header := HEADER.new()
	viewport.add_child(header)
	var records: Array = []
	for scale_factor in [.75, 1.0, 1.25, 1.3, 1.5, 2.0, 2.625, 3.0]:
		viewport.oversampling_override = scale_factor
		header.size = Vector2(minf(760, 1150 / scale_factor), 96)
		header.position = Vector2(40, 300)
		header.scale = Vector2.ONE * scale_factor
		header._layout()
		for child in header.get_children():
			child.visible = child in [header.time_socket, header.gold_socket]
		for value in [0, 1, 54, 99, 100]:
			header.time_bar.value = value
			header.gold_bar.value = value
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var frame := viewport.get_texture().get_image()
			var allowed: Array[Rect2] = []
			for socket in [header.time_socket, header.gold_socket]:
				var transform: Transform2D = socket.get_global_transform_with_canvas()
				allowed.append((transform * Rect2(Vector2.ZERO, socket.size)).grow(3 * scale_factor))
			var leaked := 0
			var gold_pixels := 0
			for y in frame.get_height():
				for x in frame.get_width():
					var pixel := frame.get_pixel(x, y)
					if pixel.a > .5 and pixel.r > .5 and pixel.g > .4 and pixel.b < pixel.g * .8:
						gold_pixels += 1
					if pixel.a > .1 and not allowed[0].has_point(Vector2(x,y)) and not allowed[1].has_point(Vector2(x,y)):
						leaked += 1
			if leaked > 0:
				failures.append("scale=%s fill=%d: %d pixels outside gauge rails" % [scale_factor, value, leaked])
			if (value == 0 and gold_pixels > 0) or (value >= 54 and gold_pixels == 0):
				failures.append("scale=%s fill=%d: unexpected gold fill (%d pixels)" % [scale_factor, value, gold_pixels])
			if leaked > 0 or value == 54:
				frame.save_png(out + "%s-%d.png" % [scale_factor, value])
			records.append({"scale":scale_factor,"fill":value,"leaked_pixels":leaked,"gold_pixels":gold_pixels})
	FileAccess.open(out + "results.json", FileAccess.WRITE).store_string(JSON.stringify(records, "\t"))
	for failure in failures: push_error(failure)
	print("Header gauge containment: ", records.size(), " cases; ", failures.size(), " failures")
	viewport.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
