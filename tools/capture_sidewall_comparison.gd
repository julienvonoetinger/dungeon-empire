extends SceneTree

class Comparison:
	extends Node2D
	var before: Texture2D
	var after: Texture2D
	var panel := 0
	func _draw() -> void:
		draw_rect(Rect2(0,0,568,844),Color("080e19"))
		draw_string(ThemeDB.fallback_font,Vector2(12,25),"AVANT",HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		draw_string(ThemeDB.fallback_font,Vector2(296,25),"APRES",HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		# Exactly the same Godot camera, viewport and native scale in both captures.
		draw_texture_rect_region(before,Rect2(8,40,272,804),Rect2(panel*272,0,272,804))
		draw_texture_rect_region(after,Rect2(292,40,272,804),Rect2(panel*272,0,272,804))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var east := "--east" in OS.get_cmdline_user_args()
	var before_path := "res://artifacts/east-before-detail.png" if east else "res://artifacts/sidewalls-before-detail.png"
	var output := "res://artifacts/east-wall-before-after.png" if east else "res://artifacts/sidewalls-before-after.png"
	var before := Image.load_from_file(before_path)
	var after := Image.load_from_file("res://artifacts/vertical-wall-details.png")
	if before == null or after == null or before.get_size() != Vector2i(816,804) or after.get_size() != Vector2i(816,804):
		push_error("Comparison requires the before and after native wall captures")
		quit(1)
		return
	if east:
		# These two captures were made before/after the right-wall correction,
		# with the same cameras. Preserve the user's approved left-wall pixels.
		var west := Rect2i(0,0,544,804)
		var east_region := Rect2i(544,0,272,804)
		if before.get_region(west).get_data() != after.get_region(west).get_data():
			push_error("The approved west-wall captures changed")
			quit(1)
			return
		if before.get_region(east_region).get_data() == after.get_region(east_region).get_data():
			push_error("The east-wall capture did not change")
			quit(1)
			return
		print("PASS: both approved west-wall panels are pixel-identical; the east panel changed")
	var board := SubViewport.new()
	board.size = Vector2i(568,844)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var comparison := Comparison.new()
	comparison.before = ImageTexture.create_from_image(before)
	comparison.after = ImageTexture.create_from_image(after)
	comparison.panel = 2 if east else 0
	board.add_child(comparison)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := board.get_texture().get_image().save_png(output)
	print("Sidewall comparison: ",error_string(result))
	board.queue_free()
	await process_frame
	quit(0 if result == OK else 1)
