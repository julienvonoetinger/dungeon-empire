extends SceneTree

const OUTPUT_PATH := "res://artifacts/dig_markers.png"

func _initialize() -> void:
	seed(4242)
	root.size = Vector2i(1280, 720)
	var packed := load("res://Main.tscn") as PackedScene
	var main := packed.instantiate() as Control
	root.add_child(main)
	call_deferred("_capture", main)

func _capture(main: Control) -> void:
	await process_frame
	await process_frame
	await process_frame
	main._ensure_dungeon()
	main.set_process(false)
	main.cam_zoom = 2.5
	main.cam_yaw = 45.0
	main._cam_custom = true
	var dungeon: Node = main.dungeon
	dungeon.sync(main)
	dungeon._yaw = main.cam_yaw
	dungeon._look = Vector3(float(main.COLS) * 0.5, 0.0, float(main.ROWS) * 0.5)
	var basis: Basis = dungeon._cam_basis()
	dungeon.camera.transform = Transform3D(basis, dungeon._look + basis.z * dungeon.CAM_DIST)
	if dungeon._dig_bound != null:
		dungeon._dig_bound.visible = false
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	var image: Image = main._world_port.get_texture().get_image()
	if image == null or image.save_png(OUTPUT_PATH) != OK:
		printerr("capture failed")
		quit(1)
		return
	print("saved ", OUTPUT_PATH)
	quit()
