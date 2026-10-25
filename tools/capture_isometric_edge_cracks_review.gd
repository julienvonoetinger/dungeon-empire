extends SceneTree
const REVIEW = preload("res://tools/isometric_edge_cracks_review.gd")
const OUT := "res://docs/reference/isometric-decoration-review/v2-edge-cracks/captures/"
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
	for proposed in [false,true]:
		scene.study.proposal = proposed
		scene.study.refresh_preview(false)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var label := "proposed" if proposed else "current"
		var error := viewport.get_texture().get_image().save_png(OUT+label+".png")
		if error != OK:
			push_error("Cannot save crack comparison: "+label)
			quit(1)
			return
		print("Captured ",label)
	quit()
