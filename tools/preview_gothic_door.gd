extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.hide()
	game.set_process(false)
	for y in game.ROWS:
		for x in game.COLS:
			game.grid[y][x] = GameTypes.Tile.ROCK
	for x in range(3, 9):
		game.grid[6][x] = GameTypes.Tile.FLOOR
	game.cam_zoom = 3.2
	game.cam_yaw = 135
	game.mobile_ui._center(Vector2i(5, 6))
	game._sync_world()
	var separate := "--separate" in OS.get_cmdline_user_args()
	var source := "door_gothic_frame_v1" if separate else "door_gothic_single_v1"
	var door: Node3D = load("res://assets/models/doors/%s.glb" % source).instantiate()
	var bounds: AABB = game.dungeon._model_aabb(door)
	print("Source bounds: ", bounds)
	for mesh in door.find_children("*", "MeshInstance3D", true, false):
		print("Source mesh: ", mesh.name, " surfaces=", mesh.mesh.get_surface_count())
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			print("Triangles: ", arrays[Mesh.ARRAY_INDEX].size() / 3)
			var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface).duplicate()
			material.metallic = 0.15
			material.roughness = 0.9
			mesh.set_surface_override_material(surface, material)
	var mount := Node3D.new()
	game.dungeon.add_child(mount)
	mount.position = Vector3(5.5, 0.175, 6.5)
	mount.rotation.y = PI / 2
	mount.add_child(door)
	# Uniform scale: this preview must expose proportions, not distort the asset.
	var scale_factor := 1.08 / bounds.size.y
	door.scale = Vector3.ONE * scale_factor
	door.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	var fitted: AABB = game.dungeon._model_aabb(door)
	assert(is_equal_approx(fitted.size.y, 1.08))
	assert(mount.position.y + fitted.end.y <= 1.26, "Arch stays just above the 1.10-unit walls")
	assert(is_equal_approx(door.scale.x, door.scale.y) and is_equal_approx(door.scale.y, door.scale.z))
	var hinge: Node3D
	if separate:
		var leaf: Node3D = load("res://assets/models/doors/door_gothic_leaf_v1.glb").instantiate()
		var leaf_bounds: AABB = game.dungeon._model_aabb(leaf)
		for mesh in leaf.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material: StandardMaterial3D = mesh.mesh.surface_get_material(surface).duplicate()
				material.metallic = 0.0
				material.roughness = 0.95
				mesh.set_surface_override_material(surface, material)
		var leaf_scale := minf(fitted.size.x * 0.62 / leaf_bounds.size.x, fitted.size.y * 0.85 / leaf_bounds.size.y)
		leaf.scale = Vector3.ONE * leaf_scale
		hinge = Node3D.new()
		hinge.name = "LeafHinge"
		hinge.position = Vector3(-leaf_bounds.size.x * leaf_scale * 0.5, 0.008, leaf_bounds.size.z * leaf_scale * 0.5)
		mount.add_child(hinge)
		hinge.add_child(leaf)
		leaf.position = Vector3(-leaf_bounds.position.x, -leaf_bounds.position.y, -leaf_bounds.end.z) * leaf_scale
		print("Separate leaf bounds: ", leaf_bounds, "; uniform scale: ", leaf_scale)
		assert(door.get_parent() == mount and leaf.get_parent() == hinge)
	var surfaces = preload("res://scripts/world/mobile_surfaces.gd")
	var masonry := surfaces._builder()
	var half_width := fitted.size.x * 0.5 - 0.01
	var courses := [0.0, 0.16, 0.37, 0.54, 0.76, 0.925]
	for side in [-1, 1]:
		var low := Vector2(half_width if side > 0 else -0.50, -0.14)
		var high := Vector2(0.50 if side > 0 else -half_width, 0.14)
		for row in 5:
			surfaces._stone(masonry, surfaces._outline(low, high, 0.012), courses[row] + 0.008,
				courses[row + 1] - 0.008, 0.012, surfaces.MASONRY_BODY)
		surfaces._stone(masonry, surfaces._outline(low, high, 0.016), 0.925, 1.10, 0.02, surfaces.MASONRY_CAP)
	var joins := MeshInstance3D.new()
	joins.name = "DoorWallConnections"
	joins.mesh = surfaces._finish(masonry, false)
	joins.position.y = -mount.position.y
	mount.add_child(joins)
	for shown in [true, false]:
		game.dungeon.set_mobile_walls_visible(shown)
		for i in 8:
			await process_frame
		var prefix := "meshy-gothic-assembly" if separate else "meshy-gothic-door"
		assert(root.get_texture().get_image().save_png("res://artifacts/%s-%s.png" % [prefix, shown]) == OK)
		if separate:
			var frame_transform := door.global_transform
			for step in 30:
				hinge.rotation.y = -PI * 0.5 * float(step + 1) / 30.0
				await process_frame
			assert(door.global_transform.is_equal_approx(frame_transform), "Frame must stay fixed during leaf rotation")
			for i in 4:
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/%s-open-%s.png" % [prefix, shown]) == OK)
			hinge.rotation.y = 0
	game.queue_free()
	await process_frame
	print("OK: Meshy door preview only; gameplay model unchanged")
	quit()
