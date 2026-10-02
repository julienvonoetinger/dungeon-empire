extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(512, 512)
	var world = load("res://scripts/world/dungeon_world.gd").new()
	world.mobile_mode = true
	root.add_child(world)
	world.set_process(false)
	var holder := Node3D.new()
	world.add_child(holder)
	var game = load("res://tests/mobile_render_test.gd").FakeGame.new()
	world._build_core(holder, Vector2i.ZERO, game)
	var sprite: Sprite3D = world._core_spin.get_node("CoreMonument")
	var chest_mode := "--chest" in OS.get_cmdline_user_args()
	if chest_mode:
		world._rebuild_cell(Vector2i.ZERO, GameTypes.Tile.VAULT, game, {Vector2i.ZERO: 50}, false)
		sprite = world._cells[Vector2i.ZERO].get_node("MobileProp")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var copy := sprite.duplicate() as Sprite3D
	copy.position.x = 0
	copy.position.z = 0
	viewport.add_child(copy)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color.BLACK
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 1.0
	viewport.add_child(env)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.5
	viewport.add_child(camera)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor_mesh.mesh = plane
	floor_mesh.position.y = 0.175
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.GREEN
	floor_mesh.material_override = mat
	viewport.add_child(floor_mesh)
	var failures := 0
	if not chest_mode:
		floor_mesh.hide()
		camera.basis = Basis.from_euler(Vector3(deg_to_rad(-40), deg_to_rad(45), 0))
		camera.position = Vector3(0, 0.5, 0) + camera.basis.z * 10
		env.environment.ambient_light_energy = 0.2
		var torch := OmniLight3D.new()
		torch.position = Vector3(0, 3, 1)
		torch.omni_range = 6
		torch.light_energy = 3
		torch.light_color = Color("ffb96e")
		viewport.add_child(torch)
		var levels: Array[float] = []
		for enabled in [false, true]:
			torch.visible = enabled
			await process_frame
			await RenderingServer.frame_post_draw
			var lit_image := viewport.get_texture().get_image()
			var red := 0.0
			for y in 512:
				for x in 512:
					red += lit_image.get_pixel(x, y).r
			levels.append(red)
		print("Core torch response off=%.1f on=%.1f" % [levels[0], levels[1]])
		if levels[1] <= levels[0] * 1.1:
			printerr("FAIL: Core stone does not respond to torch lighting")
			failures += 1
		torch.free()
		env.environment.ambient_light_energy = 1.0
	for yaw in [45.0, 135.0, 225.0, 315.0]:
		camera.basis = Basis.from_euler(Vector3(deg_to_rad(-40), deg_to_rad(yaw), 0))
		camera.position = Vector3(0, 0.5, 0) + camera.basis.z * 10
		for hp in ([100, 0] if chest_mode else [100, 50, 0]):
			if chest_mode:
				world._rebuild_cell(Vector2i.ZERO, GameTypes.Tile.VAULT, game, {Vector2i.ZERO: hp}, false)
				sprite = world._cells[Vector2i.ZERO].get_node("MobileProp")
			else:
				world._sync_mobile_core_health(hp)
			copy.texture = sprite.texture
			# Measure geometry independently of lighting, emission and artwork brightness.
			var depth_material := sprite.material_override.duplicate() as ShaderMaterial
			var shader_code: String = depth_material.shader.code
			shader_code = shader_code.substr(0, shader_code.find("void fragment()"))
			shader_code = shader_code.replace("render_mode cull_disabled;", "render_mode unshaded, cull_disabled;")
			shader_code += "void fragment() { ALBEDO=vec3(1.0); ALPHA=texture(artwork,UV).a; ALPHA_SCISSOR_THRESHOLD=0.15; }"
			var depth_shader := Shader.new()
			depth_shader.code = shader_code
			depth_material.shader = depth_shader
			copy.material_override = depth_material
			floor_mesh.hide()
			await process_frame
			await RenderingServer.frame_post_draw
			var reference := viewport.get_texture().get_image()
			# The depth correction must not change the artwork's screen alignment.
			var grounded := copy.material_override
			var flat_material := depth_material.duplicate() as ShaderMaterial
			var flat_shader := Shader.new()
			flat_shader.code = shader_code.replace("point += toward_camera * max(0.0, (ground_height - point.y) / max(toward_camera.y, 0.01));", "")
			flat_material.shader = flat_shader
			copy.material_override = flat_material
			await process_frame
			await RenderingServer.frame_post_draw
			var original := viewport.get_texture().get_image()
			copy.material_override = grounded
			var silhouette_difference := 0
			for y in 512:
				for x in 512:
					var a := reference.get_pixel(x, y)
					var b := original.get_pixel(x, y)
					if (maxf(a.r, a.b) > 0.1) != (maxf(b.r, b.b) > 0.1):
						silhouette_difference += 1
			if silhouette_difference > 30:
				printerr("FAIL: silhouette moved by %d pixels" % silhouette_difference)
				failures += 1
			floor_mesh.show()
			await process_frame
			await RenderingServer.frame_post_draw
			var actual := viewport.get_texture().get_image()
			var clipped := 0
			for y in 512:
				for x in 512:
					var color := reference.get_pixel(x, y)
					var pixel := actual.get_pixel(x, y)
					if maxf(color.r, color.b) > 0.1 and pixel.g > 0.8 and pixel.r < 0.05 and pixel.b < 0.05:
						clipped += 1
			print("%s depth state=%d yaw=%d clipped_pixels=%d" % ["Chest" if chest_mode else "Core", hp, yaw, clipped])
			if clipped > 0:
				failures += 1
			if yaw == 45 and hp == 100:
				actual.save_png("res://artifacts/core-depth-probe.png")
	# Opaque geometry must still hide the Core when in front, not behind.
	var blocker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4, 4, 0.1)
	blocker.mesh = box
	blocker.material_override = mat
	viewport.add_child(blocker)
	blocker.basis = camera.basis
	for front in [false, true]:
		blocker.position = Vector3(0, 0.5, 0) + camera.basis.z * (2.0 if front else -2.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var capture := viewport.get_texture().get_image()
		var core_pixels := 0
		for y in 512:
			for x in 512:
				var pixel := capture.get_pixel(x, y)
				if maxf(pixel.r, pixel.b) > 0.1:
					core_pixels += 1
		if (front and core_pixels != 0) or (not front and core_pixels < 1000):
			printerr("FAIL: incorrect occlusion front=%s pixels=%d" % [front, core_pixels])
			failures += 1
	game.free()
	world.free()
	viewport.free()
	if failures:
		printerr("FAIL: floor clips Core artwork in %d views" % failures)
	else:
		print("OK: %s base remains above paving in all states and orientations" % ("Chest" if chest_mode else "Core"))
	quit(1 if failures else 0)
