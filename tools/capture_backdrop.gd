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
	game.mobile_ui.modal.hide()
	for i in 4:
		await process_frame
	var instances := 0
	for batch in game.dungeon._mobile_backdrop.get_children():
		if not batch is MultiMeshInstance3D:
			continue
		instances += batch.multimesh.instance_count
		assert(batch.multimesh.buffer.size() == batch.multimesh.instance_count * 12)
		for index in batch.multimesh.instance_count:
			var bounds: AABB = batch.multimesh.get_instance_transform(index) * batch.multimesh.mesh.get_aabb()
			assert(not (bounds.position.x < 15.9999 and bounds.end.x > 0.0001 and bounds.position.z < 15.9999 and bounds.end.z > 0.0001), "decor must not enter playable cells")
	assert(instances == 2880)
	for yaw in [45, 135, 225, 315]:
		for sign_x in [-1, 1]:
			game.cam_yaw = yaw
			game.cam_zoom = 0.1
			game.cam_pan = Vector2(sign_x * 100000, -100000)
			for i in 8:
				await process_frame
			var picture := root.get_texture().get_image()
			assert(picture.save_png("res://artifacts/backdrop-edge-%d-%d.png" % [yaw, sign_x]) == OK)
			var covered := 0
			for y in range(100, 360, 20):
				for x in range(20, 850, 20):
					var color := picture.get_pixel(x, y)
					if color.r + color.g + color.b > 0.08:
						covered += 1
			assert(covered > 450, "rock must cover visible game area at camera extremes")
	game.cam_yaw = 45
	game.cam_zoom = 1.2
	game.mobile_ui._center_core()
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/backdrop-overview.png") == OK)
	root.size = Vector2i(540, 960)
	game.mobile_ui._center_core()
	for i in 8:
		await process_frame
	assert(root.get_texture().get_image().save_png("res://artifacts/backdrop-portrait.png") == OK)
	print("OK: Vulkan backdrop extremes four angles, pixel coverage, overview and portrait")
	game.queue_free()
	await process_frame
	quit()
