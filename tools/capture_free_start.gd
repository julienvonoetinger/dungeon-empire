extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(960, 540)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	assert(not game._has_core() and not game._has_entrance(), "New mobile dungeon must start unbuilt")
	for i in 12:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/free-start-preview.png") == OK)
	var ghost: Sprite3D = game.dungeon._mobile_core_preview
	# The artwork's ground-footprint center is at 64% of its image height.
	assert(is_equal_approx(ghost.offset.y / ghost.texture.get_height(), 0.14), "Preview must anchor its footprint, not its bottom edge")
	assert(not ghost.no_depth_test, "Room preview walls must occlude the Core normally")
	assert(game.dungeon.get_node("CoreRoomPreview/Walls").get_child_count() == 4, "Preview must enclose the floor on four sides")
	for zoom in [1.5, 2.5]:
		game.cam_zoom = zoom
		game._sync_world()
		for i in 4:
			await process_frame
		assert(root.get_texture().get_image().save_png("res://artifacts/core-anchor-zoom-%s.png" % zoom) == OK)
	game.cam_zoom = 2.0
	game._sync_world()
	game.mobile_ui.paused = false
	game.mobile_ui._tap(game._cell_pos(Vector2i(4, 8)))
	game.mobile_ui.paused = true
	assert(game.mobile_ui.selected == Vector2i(4, 8), "Screen picking must move the Core preview to the tapped cells")
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/free-start-moved.png") == OK)
	assert(game.mobile_ui.preview.valid)
	var ghost_position := ghost.global_position
	var ghost_offset := ghost.offset
	game.mobile_ui.confirm.pressed.emit()
	assert(game._core_origin() == Vector2i(4, 8))
	assert(not game._has_entrance() and game._storage_capacity() == 0)
	var monument: Sprite3D = game.dungeon._core_spin.get_node("CoreMonument")
	assert(monument.global_position.is_equal_approx(ghost_position) and monument.offset.is_equal_approx(ghost_offset), "Confirmation must not move the Core artwork")
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/free-start-anchored.png") == OK)
	game.dungeon.set_mobile_walls_visible(false)
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/free-start-anchored-no-walls.png") == OK)
	game.queue_free()
	await process_frame
	print("OK: free start, movable preview, chosen Core and no auto structures")
	quit()
