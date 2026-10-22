extends SceneTree

## Diagnostic only: left is the source, right is the independently rendered scene.
class Comparison:
	extends Node2D
	var source: Texture2D
	var rendered: Texture2D
	func _draw() -> void:
		draw_rect(Rect2(0,0,1144,554), Color("0c1019"))
		draw_string(ThemeDB.fallback_font, Vector2(12,25), "REFERENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(584,25), "RENDU GODOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		draw_texture_rect_region(source, Rect2(6,38,560,510), Rect2(0,120,560,510))
		draw_texture(rendered, Vector2(578,38))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene_view := SubViewport.new()
	scene_view.size = Vector2i(560,510)
	scene_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(scene_view)
	scene_view.add_child(load("res://scenes/PerspectiveRoom.tscn").instantiate())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var board := SubViewport.new()
	board.size = Vector2i(1144,554)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var comparison := Comparison.new()
	comparison.source = load("res://assets/dungeon/perspective/reference-atlas.png")
	comparison.rendered = scene_view.get_texture()
	board.add_child(comparison)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := board.get_texture().get_image().save_png("res://artifacts/reference-comparison.png")
	print("Comparison capture: ", error_string(result))
	scene_view.queue_free()
	board.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
