extends SceneTree

const OUTPUT_PATH := "res://artifacts/dungeon_baseline.png"

# One-shot: render the starting dungeon with a deterministic camera and seed.

func _initialize() -> void:
	seed(4242)
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://Main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	call_deferred("_capture", main)

func _capture(main: Control) -> void:
	await process_frame
	await process_frame
	await process_frame
	if main.has_method("_ensure_dungeon"):
		main._ensure_dungeon()
	main.set_process(false)
	main.cam_zoom = 2.5
	# Stable overview of the complete starting dungeon.
	main.cam_yaw = 45.0
	main._cam_custom = true
	var dungeon: Node = main.dungeon
	if dungeon != null:
		dungeon.sync(main)
		dungeon._yaw = main.cam_yaw
		var min_cell := Vector2i(main.COLS, main.ROWS)
		var max_cell := Vector2i.ZERO
		for y in main.ROWS:
			for x in main.COLS:
				if int(main.grid[y][x]) == main.Tile.ROCK:
					continue
				min_cell.x = mini(min_cell.x, x)
				min_cell.y = mini(min_cell.y, y)
				max_cell.x = maxi(max_cell.x, x)
				max_cell.y = maxi(max_cell.y, y)
		var center := (Vector3(min_cell.x, 0.0, min_cell.y) + Vector3(max_cell.x + 1, 0.0, max_cell.y + 1)) * 0.5
		var span := float(maxi(max_cell.x - min_cell.x + 1, max_cell.y - min_cell.y + 1))
		dungeon._look = center
		dungeon.camera.size = maxf(6.0, span * 1.55)
		var b: Basis = dungeon._cam_basis()
		dungeon.camera.transform = Transform3D(b, dungeon._look + b.z * dungeon.CAM_DIST)
		if dungeon._dig_bound != null:
			dungeon._dig_bound.visible = false
		if dungeon._expand_root != null:
			dungeon._expand_root.visible = false
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	var img: Image
	if main._world_port != null:
		img = main._world_port.get_texture().get_image()
	else:
		img = root.get_texture().get_image()
	if img != null:
		var error := img.save_png(OUTPUT_PATH)
		if error != OK:
			printerr("capture failed: could not save %s (error %d)" % [OUTPUT_PATH, error])
			quit(1)
			return
		print("saved ", OUTPUT_PATH, " ", img.get_width(), "x", img.get_height())
	else:
		printerr("capture failed: no image")
		quit(1)
		return
	quit()
