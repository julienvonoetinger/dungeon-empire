extends SceneTree

# One-shot: render the starting dungeon, frame the entrance, save a PNG.

func _initialize() -> void:
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
	main.cam_zoom = 4.8
	# Gameplay-like SW view onto the west-facing hillside mouth (cell 0,5).
	main.cam_yaw = 45.0
	main._cam_custom = true
	var dungeon: Node = main.dungeon
	if dungeon != null:
		dungeon.sync(main)
		dungeon._yaw = main.cam_yaw
		dungeon._look = Vector3(1.55, 0.62, 5.55)
		dungeon.camera.size = dungeon.ortho_size(main.cam_zoom)
		var b: Basis = dungeon._cam_basis()
		dungeon.camera.transform = Transform3D(b, dungeon._look + b.z * dungeon.CAM_DIST)
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
		img.save_png("res://assets/sprites/entrance_preview.png")
		print("saved entrance_preview.png ", img.get_width(), "x", img.get_height())
	else:
		print("capture failed: no image")
	quit()
