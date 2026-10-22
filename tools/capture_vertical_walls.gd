extends SceneTree

class Details:
	extends Node2D
	var views: Array[SubViewport] = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,816,804),Color("080e19"))
		var labels := ["OUEST / ENTREE", "OUEST / SALLE BASSE", "EST / SALLE DROITE"]
		for i in range(views.size()):
			var x := 8+i*272
			draw_string(ThemeDB.fallback_font,Vector2(x,24),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
			draw_texture(views[i].get_texture(),Vector2(x,36))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var views: Array[SubViewport] = []
	for center: Vector2 in [Vector2(250,720),Vector2(250,1530),Vector2(2740,720)]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(260,760)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
		viewport.add_child(scene)
		await process_frame
		var camera: Camera2D = scene.get_node("Camera2D")
		camera.position = center
		camera.zoom = Vector2.ONE
		camera.force_update_scroll()
		views.append(viewport)
	await process_frame
	await RenderingServer.frame_post_draw
	var board := SubViewport.new()
	board.size = Vector2i(816,804)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var details := Details.new()
	details.views = views
	board.add_child(details)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := board.get_texture().get_image().save_png("res://artifacts/vertical-wall-details.png")
	print("Vertical wall details: ",error_string(result))
	for viewport in views:
		viewport.queue_free()
	board.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
