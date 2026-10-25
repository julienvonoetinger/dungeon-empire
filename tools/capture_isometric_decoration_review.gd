extends SceneTree
const REVIEW = preload("res://tools/isometric_decoration_review.gd")
const OUT := "res://docs/reference/isometric-decoration-review/v1/captures/"

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := REVIEW.new()
	viewport.add_child(scene)
	await process_frame
	for motif in ["bare","mixed","crack-short","crack-branch","chip-worn","crack-corrupt"]:
		scene.study.decoration_enabled = motif != "bare"
		scene.study.motif_override = "" if motif in ["bare","mixed"] else motif
		scene.study.refresh_preview(false)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(OUT+motif+".png")
		if error != OK:
			push_error("Cannot save decoration capture: "+motif)
			quit(1)
			return
		print("Captured ",motif)
	quit()
