extends SceneTree

class Comparison:
	extends Node2D
	var views: Array[SubViewport] = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1600,800),Color("080e19"))
		for i in range(views.size()):
			var x := 8+i*800
			draw_string(ThemeDB.fallback_font,Vector2(x,28),"BEFORE" if i == 0 else "STONE VARIATION",0,-1,20)
			draw_texture(views[i].get_texture(),Vector2(x,40))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var views: Array[SubViewport] = []
	for varied in [false,true]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(784,752)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
		scene.get_node("Dungeon").stone_variation = varied
		viewport.add_child(scene)
		await process_frame
		var camera: Camera2D = scene.get_node("Camera2D")
		camera.position = Vector2(540,1520)
		camera.zoom = Vector2.ONE
		camera.force_update_scroll()
		views.append(viewport)
	await process_frame
	await RenderingServer.frame_post_draw
	var board := SubViewport.new()
	board.size = Vector2i(1600,800)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var comparison := Comparison.new()
	comparison.views = views
	board.add_child(comparison)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := board.get_texture().get_image().save_png("res://artifacts/stone-variation-before-after.png")
	print("Stone variation comparison: ",error_string(result))
	for viewport in views:
		viewport.queue_free()
	board.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
