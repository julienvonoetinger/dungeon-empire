extends SceneTree
## Visual captures only, at the fixed gameplay scale.
const REVIEW = preload("res://tools/mobile_light_review.gd")
const OUTPUT := "res://docs/reference/mobile-light-review/captures/"

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := REVIEW.new()
	viewport.add_child(scene)
	await process_frame
	for enabled in [false,true]:
		scene.study.set_local_lights(enabled)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var file := "with-local-light.png" if enabled else "without-local-light.png"
		var error := viewport.get_texture().get_image().save_png(OUTPUT+file)
		if error != OK:
			push_error("Cannot save "+file)
			quit(1)
			return
		print("Captured ",file)
	quit()
