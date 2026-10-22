extends SceneTree

## GPU captures for visual review, without probes, assertions or scores.
func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_name := "3x3RoomFourCorridors"
	var suffix := ""
	var rows_override := PackedInt32Array()
	var has_rows_override := false
	var columns_override := PackedInt32Array()
	var has_columns_override := false
	var connections_override := -1
	for argument in args:
		if argument.begins_with("--scene="):
			scene_name = argument.trim_prefix("--scene=").validate_filename()
		elif argument.begins_with("--rows="):
			has_rows_override = true
			for row in argument.trim_prefix("--rows=").split(",",false):
				rows_override.append(row.to_int())
		elif argument.begins_with("--columns="):
			has_columns_override = true
			for column in argument.trim_prefix("--columns=").split(",",false):
				columns_override.append(column.to_int())
		elif argument.begins_with("--connections="):
			connections_override = argument.trim_prefix("--connections=").to_int()
		else:
			suffix = "-" + argument.validate_filename()
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://scenes/" + scene_name + ".tscn").instantiate()
	var dungeon = scene.get_node("Dungeon")
	if has_rows_override:
		dungeon.horizontal_attachment_rows = rows_override
	if has_columns_override:
		dungeon.vertical_attachment_columns = columns_override
	if connections_override >= 0:
		dungeon.connections = connections_override
	viewport.add_child(scene)
	var frame: Rect2 = dungeon.get_content_rect()
	viewport.size = Vector2i(frame.size)
	var prefix := "res://artifacts/" + scene_name + suffix
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(prefix + ".png")
	viewport.size = Vector2i(frame.size * 2)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(prefix + "-2x.png")
	var camera: Camera2D = scene.get_node("Camera2D")
	viewport.size = Vector2i(800, 900)
	await process_frame
	camera.zoom = Vector2.ONE * 4
	var centers: Dictionary = dungeon.get_junction_centers()
	for side in centers:
		camera.position = centers[side]
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(prefix + "-" + side + "-4x.png")
	# Visual regressions for the reported left join, floating facade and corner.
	viewport.size = Vector2i(800, 640)
	await process_frame
	camera.zoom = Vector2.ONE * 4
	var details: Dictionary = dungeon.get_regression_detail_centers()
	for detail in details:
		camera.position = details[detail]
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(prefix + "-" + detail + "-4x.png")
	var corners: Dictionary = dungeon.get_corner_detail_centers()
	for corner in corners:
		camera.position = corners[corner]
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(prefix + "-" + corner + "-4x.png")
	print("Visual captures: %s, horizontal_length=%d, vertical_length=%d, 1x/2x, junctions, details and %d corner/tip details at4x." % [scene_name,dungeon.corridor_length,dungeon._vertical_length(),corners.size()])
	viewport.queue_free()
	await process_frame
	await _corner_gallery(prefix,corners.keys())
	if scene_name == "3x3RoomFourCorridors" and suffix.is_empty():
		await _comparison()
	quit()

func _corner_gallery(prefix: String, names: Array) -> void:
	if names.is_empty():
		return
	var viewport := SubViewport.new()
	var panel := Vector2i(820,700)
	var columns := mini(4,names.size())
	viewport.size = Vector2i(panel.x * columns,panel.y * ceili(float(names.size()) / columns))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for index in range(names.size()):
		var origin := Vector2(index % columns,int(index / columns)) * Vector2(panel)
		var picture := Sprite2D.new()
		picture.texture = ImageTexture.create_from_image(Image.load_from_file(prefix + "-" + names[index] + "-4x.png"))
		picture.position = origin + Vector2(410,370)
		viewport.add_child(picture)
		var label := Label.new()
		label.text = names[index] + " — x4"
		label.position = origin + Vector2(12,8)
		label.add_theme_font_size_override("font_size",18)
		viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(prefix + "-corners-comparison.png")
	viewport.queue_free()
	await process_frame

func _comparison() -> void:
	var before_path := "res://artifacts/3x3RoomFourCorridors-before-fixes.png"
	if not FileAccess.file_exists(before_path):
		return
	var viewport := SubViewport.new()
	var paths := [before_path, "res://artifacts/3x3RoomFourCorridors.png"]
	var pictures: Array[Image] = []
	var panel := Vector2i.ZERO
	for path in paths:
		var picture := Image.load_from_file(path)
		pictures.append(picture)
		panel.x = maxi(panel.x, picture.get_width() + 40)
		panel.y = maxi(panel.y, picture.get_height() + 80)
	viewport.size = Vector2i(panel.x * 2, panel.y)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for index in range(2):
		# Display complete captures at identical pixel scale, without modifying
		# source images or turning a screenshot into production dungeon art.
		var picture := Sprite2D.new()
		picture.texture = ImageTexture.create_from_image(pictures[index])
		picture.position = Vector2(panel.x * (index + 0.5), 60 + pictures[index].get_height() * 0.5)
		viewport.add_child(picture)
		var label := Label.new()
		label.text = "Avant — raccords signalés" if index == 0 else "Après — angles en L, profil des murs partagé"
		label.position = Vector2(24 + panel.x * index, 16)
		label.add_theme_font_size_override("font_size", 22)
		viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://artifacts/3x3RoomFourCorridors-fixes-comparison.png")
	viewport.queue_free()
	await process_frame
