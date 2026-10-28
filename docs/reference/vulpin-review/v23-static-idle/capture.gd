extends SceneTree
const SCENE := preload("res://scenes/VulpinIdle.tscn")
const OUT := "res://docs/reference/vulpin-review/v23-static-idle/"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.add_child(SCENE.instantiate())
	for viewport_size in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = viewport_size
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(OUT + "idle-%dx%d.png" % [viewport_size.x, viewport_size.y])
		if result != OK:
			push_error("Idle capture failed: " + str(result))
			quit(1)
			return
	print("VULPIN_IDLE_CAPTURE: 3 native views saved")
	quit()
