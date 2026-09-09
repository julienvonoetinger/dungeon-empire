extends SceneTree

func _initialize() -> void:
	root.size = Vector2i(1280, 800)
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	load("res://assets/rendering/dungeon_render_profile.tres").apply_to_environment(environment.environment)
	scene.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.8
	light.shadow_enabled = true
	scene.add_child(light)
	var floor_renderer = load("res://scripts/world/floor_renderer.gd").new()
	scene.add_child(floor_renderer)
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	floor_renderer.sync_cells(cells, 1.0)
	var wall := (load("res://assets/models/environment/wall_straight_controlled.glb") as PackedScene).instantiate()
	scene.add_child(wall)
	load("res://scripts/world/model_fit.gd").fit_footprint(wall, 2.0, 0.0)
	wall.position += Vector3(1, 0, -0.25)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.8
	camera.position = Vector3(4, 3.5, 5)
	camera.transform = camera.transform.looking_at(Vector3(1, 0.35, 0.7))
	camera.current = true
	call_deferred("_capture")

func _capture() -> void:
	for frame in 5:
		await process_frame
	RenderingServer.force_draw()
	await process_frame
	var result := root.get_texture().get_image().save_png("res://artifacts/stone_kit.png")
	print("Stone kit capture: ", error_string(result))
	quit(result)
