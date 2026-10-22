extends SceneTree

class Details:
	extends Node2D
	var views: Array[SubViewport] = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1792,528),Color("080e19"))
		var labels := ["ENTREE / MEME ECHELLE", "SALLE HAUTE / MEME ECHELLE"]
		for i in range(views.size()):
			var x := 8+i*896
			draw_string(ThemeDB.fallback_font,Vector2(x,24),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
			draw_texture(views[i].get_texture(),Vector2(x,36))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var views: Array[SubViewport] = []
	for center in [Vector2(590,400),Vector2(1408,180)]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(880,480)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
		viewport.add_child(scene)
		await process_frame
		var camera: Camera2D = scene.get_node("Camera2D")
		camera.position = center
		camera.zoom = Vector2.ONE*1.1
		camera.force_update_scroll()
		views.append(viewport)
	await process_frame
	await RenderingServer.frame_post_draw
	var board := SubViewport.new()
	board.size = Vector2i(1792,528)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var details := Details.new()
	details.views = views
	board.add_child(details)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := board.get_texture().get_image().save_png("res://artifacts/wall-projection-comparison.png")
	print("Wall projection comparison: ",error_string(result))
	for viewport in views:
		viewport.queue_free()
	board.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
