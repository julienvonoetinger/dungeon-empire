extends SceneTree

const OUTPUT_PATH := "res://artifacts/render_lab.png"
const CAPTURE_SIZE := Vector2i(1280, 720)

func _initialize() -> void:
	root.size = CAPTURE_SIZE
	var packed := load("res://scenes/render_lab/RenderLab.tscn") as PackedScene
	if packed == null:
		printerr("capture failed: RenderLab scene did not load")
		quit(1)
		return
	root.add_child(packed.instantiate())
	call_deferred("_capture")

func _capture() -> void:
	await process_frame
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.get_width() < CAPTURE_SIZE.x or image.get_height() < CAPTURE_SIZE.y:
		printerr("capture failed: expected at least %s" % CAPTURE_SIZE)
		quit(1)
		return
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		printerr("capture failed: could not save %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("saved %s %dx%d" % [OUTPUT_PATH, image.get_width(), image.get_height()])
	quit()
