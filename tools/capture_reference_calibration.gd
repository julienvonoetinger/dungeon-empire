extends SceneTree

class DoorComparison:
	extends Node2D
	var original: Texture2D
	var before: Texture2D
	var after: Texture2D
	var after_label := "ETUDE — NOUVELLE PORTE"
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 348), Color("080e19"))
		var font := ThemeDB.fallback_font
		var labels := ["ORIGINAL", "AVANT", after_label]
		var textures := [original, before, after]
		for i in range(3):
			var x := 10 + 424 * i
			draw_string(font, Vector2(x, 24), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
			var source := Rect2(55, 110, 410, 300) if i == 0 else Rect2(95, 5, 410, 300)
			draw_texture_rect_region(textures[i], Rect2(x, 38, 410, 300), source)

class Comparison:
	extends Node2D
	var original: Texture2D
	var study: Texture2D
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1160, 1160), Color("080e19"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(12, 26), "REFERENCE ORIGINALE — ENTREE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, Vector2(592, 26), "ETUDE GODOT — ENTREE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_texture_rect_region(original, Rect2(12, 40, 560, 510), Rect2(0, 120, 560, 510))
		draw_texture_rect_region(study, Rect2(592, 40, 560, 510), Rect2(20, 20, 560, 510))
		draw_string(font, Vector2(12, 584), "REFERENCE ORIGINALE — ANGLE EST", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, Vector2(592, 584), "ETUDE GODOT — ANGLE EST", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_texture_rect_region(original, Rect2(12, 600, 560, 560), Rect2(1048, 90, 560, 560))
		draw_texture_rect_region(study, Rect2(592, 600, 560, 560), Rect2(360, 30, 560, 560))

func _initialize() -> void:
	_run.call_deferred()

func _alpha_at(sprite: Sprite2D, pixels: Image, at: Vector2) -> float:
	var pixel := Vector2i(sprite.to_local(at))
	if not Rect2i(Vector2i.ZERO, pixels.get_size()).has_point(pixel):
		return 0.0
	return pixels.get_pixelv(pixel).a

func _check_entry(scene: Node) -> bool:
	# Focused regression for the reported doorway, not an artistic quality score.
	var masonry: Sprite2D = scene.get_node("EntryMasonry")
	var corner: Sprite2D = scene.get_node("EastCorner")
	var door: Sprite2D = scene.get_node("Entrance")
	var floor_sprite: Sprite2D = scene.get_node("Floor")
	var masonry_pixels := masonry.texture.get_image()
	var door_pixels := door.texture.get_image()
	var floor_pixels := floor_sprite.texture.get_image()
	# Measure the outside of both authored jamb feet below the ordinary wall.
	# Torch spacing must follow the visible doorway, not an obsolete x=300 axis.
	var jamb_left := INF
	var jamb_right := -INF
	for x in range(180, 441):
		if _alpha_at(masonry, masonry_pixels, Vector2(x, 230)) > 0.5:
			jamb_left = minf(jamb_left, x)
			jamb_right = maxf(jamb_right, x)
	var west: Sprite2D = scene.get_node("TorchWest")
	var east: Sprite2D = scene.get_node("TorchEast")
	var west_gap := jamb_left - west.position.x
	var east_gap := east.position.x - jamb_right
	if not is_finite(jamb_left) or west_gap <= 0 or east_gap <= 0 or absf(west_gap - east_gap) > 2.0:
		push_error("Unequal torch spacing from the arch: west=" + str(west_gap) + ", east=" + str(east_gap))
		return false
	if west.position.y != east.position.y or west.scale != east.scale or west.texture != east.texture:
		push_error("Both torches must retain the same height, scale and artwork")
		return false
	for torch in [west, east]:
		var matching_light := false
		for child in scene.get_children():
			if child is PointLight2D and child.position.is_equal_approx(torch.position + Vector2(0, -48.75)):
				matching_light = true
		if not matching_light:
			push_error("Torch light does not follow its fixture: " + str(torch.name))
			return false
	print("Torch spacing: OK (west gap ", west_gap, ", east gap ", east_gap, ")")
	# The original single-leaf door is taller than it is wide. The rejected
	# masonry v1 aperture was nearly square; measure the authored alpha hole.
	var opening_width := 0
	var opening_height := 0
	for x in range(235, 380):
		if _alpha_at(masonry, masonry_pixels, Vector2(x, 160)) < 0.01:
			opening_width += 1
	for y in range(65, 215):
		if _alpha_at(masonry, masonry_pixels, Vector2(307, y)) < 0.01:
			opening_height += 1
	var opening_ratio := float(opening_width) / maxf(1.0, opening_height)
	if opening_ratio < 0.70 or opening_ratio > 0.90:
		push_error("Door aperture must retain upright proportions: " + str(opening_width) + " x " + str(opening_height))
		return false
	for point in [Vector2(270,160), Vector2(335,160), Vector2(270,195), Vector2(335,195), Vector2(304,110)]:
		if _alpha_at(masonry, masonry_pixels, point) > 0.01:
			push_error("Masonry behind the recessed leaf at " + str(point))
			return false
		if _alpha_at(door, door_pixels, point) < 0.95:
			push_error("Door does not cover its opening at " + str(point))
			return false
	# The projecting jambs now belong to the masonry, ahead of its y=225 wall foot.
	for point in [Vector2(225,240), Vector2(390,240)]:
		if _alpha_at(masonry, masonry_pixels, point) < 0.95 or _alpha_at(floor_sprite, floor_pixels, point) < 0.95:
			push_error("Jamb must project onto continuous floor at " + str(point))
			return false
	if door.z_index >= masonry.z_index:
		push_error("The wooden leaf must remain behind the wall reveals and threshold")
		return false
	for sprite in [masonry, corner, door, floor_sprite]:
		if sprite.region_enabled or sprite.material != null or not is_equal_approx(sprite.scale.x, sprite.scale.y):
			push_error("Study must preserve the complete native PNG: " + str(sprite.name))
			return false
	print("Entry integration regression: OK (unified masonry, recessed leaf, projected feet, aperture ", opening_width, " x ", opening_height, ")")
	return true

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(920, 640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene = load("res://scenes/ReferenceCalibration.tscn").instantiate()
	viewport.add_child(scene)
	# A saved PNG alone does not prove the assets loaded: fail on missing textures.
	for child in scene.get_children():
		if child is Sprite2D and child.texture == null:
			push_error("Missing study texture: " + str(child.name))
			quit(1)
			return
	if not _check_entry(scene):
		quit(1)
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://artifacts/reference-calibration.png")
	print("Reference calibration capture: ", error_string(result))
	var board := SubViewport.new()
	board.size = Vector2i(1160, 1160)
	board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board)
	var comparison := Comparison.new()
	comparison.original = load("res://assets/dungeon/perspective/reference-atlas.png")
	comparison.study = viewport.get_texture()
	board.add_child(comparison)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var comparison_result := board.get_texture().get_image().save_png("res://artifacts/reference-calibration-comparison.png")
	print("Reference calibration comparison: ", error_string(comparison_result))
	var closeup := SubViewport.new()
	closeup.size = Vector2i(1840, 1280)
	closeup.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(closeup)
	closeup.add_child(load("res://scenes/ReferenceCalibration.tscn").instantiate())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var closeup_result := closeup.get_texture().get_image().save_png("res://artifacts/reference-calibration-2x.png")
	print("Reference calibration 2x: ", error_string(closeup_result))
	var door_result: Error = OK
	if FileAccess.file_exists("res://artifacts/door-perspective-before.png"):
		var door_board := SubViewport.new()
		door_board.size = Vector2i(1280, 348)
		door_board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(door_board)
		var door_comparison := DoorComparison.new()
		door_comparison.original = comparison.original
		door_comparison.before = ImageTexture.create_from_image(Image.load_from_file("res://artifacts/door-perspective-before.png"))
		door_comparison.after = viewport.get_texture()
		door_board.add_child(door_comparison)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		door_result = door_board.get_texture().get_image().save_png("res://artifacts/door-perspective-comparison.png")
		print("Door perspective comparison: ", error_string(door_result))
		door_board.queue_free()
	var integration_result: Error = OK
	if FileAccess.file_exists("res://artifacts/door-integration-before.png"):
		var integration_board := SubViewport.new()
		integration_board.size = Vector2i(1280, 348)
		integration_board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(integration_board)
		var integration_comparison := DoorComparison.new()
		integration_comparison.original = comparison.original
		integration_comparison.before = ImageTexture.create_from_image(Image.load_from_file("res://artifacts/door-integration-before.png"))
		integration_comparison.after = viewport.get_texture()
		integration_comparison.after_label = "APRES — RENDU GODOT"
		integration_board.add_child(integration_comparison)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		integration_result = integration_board.get_texture().get_image().save_png("res://artifacts/door-integration-comparison.png")
		print("Door integration comparison: ", error_string(integration_result))
		integration_board.queue_free()
	var masonry_result: Error = OK
	if FileAccess.file_exists("res://artifacts/door-masonry-before.png"):
		var masonry_board := SubViewport.new()
		masonry_board.size = Vector2i(1280, 348)
		masonry_board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(masonry_board)
		var masonry_comparison := DoorComparison.new()
		masonry_comparison.original = comparison.original
		masonry_comparison.before = ImageTexture.create_from_image(Image.load_from_file("res://artifacts/door-masonry-before.png"))
		masonry_comparison.after = viewport.get_texture()
		masonry_comparison.after_label = "APRES — MACONNERIE COMMUNE"
		masonry_board.add_child(masonry_comparison)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		masonry_result = masonry_board.get_texture().get_image().save_png("res://artifacts/door-masonry-comparison.png")
		print("Door masonry comparison: ", error_string(masonry_result))
		masonry_board.queue_free()
	var proportions_result: Error = OK
	if FileAccess.file_exists("res://artifacts/door-proportions-before.png"):
		var proportions_board := SubViewport.new()
		proportions_board.size = Vector2i(1280, 348)
		proportions_board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(proportions_board)
		var proportions_comparison := DoorComparison.new()
		proportions_comparison.original = comparison.original
		proportions_comparison.before = ImageTexture.create_from_image(Image.load_from_file("res://artifacts/door-proportions-before.png"))
		proportions_comparison.after = viewport.get_texture()
		proportions_comparison.after_label = "APRES — PROPORTIONS CORRIGEES"
		proportions_board.add_child(proportions_comparison)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		proportions_result = proportions_board.get_texture().get_image().save_png("res://artifacts/door-proportions-comparison.png")
		print("Door proportions comparison: ", error_string(proportions_result))
		proportions_board.queue_free()
	var torch_result: Error = OK
	if FileAccess.file_exists("res://artifacts/torch-spacing-before.png"):
		var torch_board := SubViewport.new()
		torch_board.size = Vector2i(1280, 348)
		torch_board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(torch_board)
		var torch_comparison := DoorComparison.new()
		torch_comparison.original = comparison.original
		torch_comparison.before = ImageTexture.create_from_image(Image.load_from_file("res://artifacts/torch-spacing-before.png"))
		torch_comparison.after = viewport.get_texture()
		torch_comparison.after_label = "APRES — TORCHES RECENTREES"
		torch_board.add_child(torch_comparison)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		torch_result = torch_board.get_texture().get_image().save_png("res://artifacts/torch-spacing-comparison.png")
		print("Torch spacing comparison: ", error_string(torch_result))
		torch_board.queue_free()
	var style_result: Error = OK
	if FileAccess.file_exists("res://artifacts/door-style-before.png"):
		var style_board := SubViewport.new()
		style_board.size = Vector2i(1280, 348)
		style_board.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(style_board)
		var style_comparison := DoorComparison.new()
		style_comparison.original = comparison.original
		style_comparison.before = ImageTexture.create_from_image(Image.load_from_file("res://artifacts/door-style-before.png"))
		style_comparison.after = viewport.get_texture()
		style_comparison.after_label = "APRES — BOIS ET FER REPEINTS"
		style_board.add_child(style_comparison)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		style_result = style_board.get_texture().get_image().save_png("res://artifacts/door-style-comparison.png")
		print("Door style comparison: ", error_string(style_result))
		style_board.queue_free()
	# Hide only the wooden leaf: arch, reveals and threshold stay in the wall.
	scene.get_node("Entrance").hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var opening_result := viewport.get_texture().get_image().save_png("res://artifacts/door-integration-opening.png")
	print("Door opening capture: ", error_string(opening_result))
	scene.get_node("Entrance").show()
	closeup.queue_free()
	board.queue_free()
	viewport.queue_free()
	await process_frame
	quit(0 if result == OK and comparison_result == OK and closeup_result == OK and door_result == OK and integration_result == OK and masonry_result == OK and proportions_result == OK and torch_result == OK and style_result == OK and opening_result == OK else 1)
