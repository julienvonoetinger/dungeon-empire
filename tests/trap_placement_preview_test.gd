extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var ui = game.mobile_ui
	ui.paused = true
	ui.modal.hide()
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	ui.profile.testing_unlock_defenses = true
	var cell := Vector2i(10, 5)
	game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
	game.gold = 150
	assert(game._has_core())
	game.dungeon.mobile_walls_visible = false
	ui.category = 2
	ui.tray_collapsed = false
	game.cam_zoom = 1.8
	ui._center(cell)
	for tool in [GameTypes.Tool.TRAP_SPIKE, GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID]:
		ui.tool = tool
		ui.selected = cell
		ui._update_preview()
		game.dungeon.sync(game)
		var ghost: Node3D = game.dungeon.get_node_or_null("TrapPlacementPreview")
		assert(ghost != null and ghost.visible, "Placement uses a world-space trap preview")
		assert(ghost.get_node_or_null("Mechanism") != null and ghost.get_node_or_null("PreviewFloor") != null)
		assert(game.grid[cell.y][cell.x] == GameTypes.Tile.FLOOR and game.gold == 150, "Preview never commits")
		if "--capture" in OS.get_cmdline_user_args():
			ui._layout()
			ui._refresh()
			ui.queue_redraw()
			for frame in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/trap-preview-%d.png" % tool)
		for rotation in 4:
			ui._rotate(1)
			var corners: PackedVector2Array = ui._placement_corners(cell)
			for index in 4:
				var offset: Vector2i = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.ONE, Vector2i.DOWN][index]
				var p := Vector3(cell.x + offset.x, 0.185, cell.y + offset.y)
				var expected: Vector2 = game._to_world_screen(game.dungeon._world_to_screen(p, game._play_view(), game.cam_zoom))
				assert(corners[index].distance_to(expected) < 0.01)
	ui._cancel()
	game.dungeon.sync(game)
	assert(not game.dungeon.get_node("TrapPlacementPreview").visible, "Cancel hides preview")
	game.queue_free()
	await process_frame
	print("OK: three world trap previews, floor corners at four rotations, cancellation and no mutations")
	quit()
