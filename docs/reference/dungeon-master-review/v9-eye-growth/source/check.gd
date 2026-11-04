extends SceneTree

var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path := "res://scenes/previews/EnergyMasterPreview.tscn"
	if "--missing" in OS.get_cmdline_user_args():
		path = "res://scenes/previews/MissingEnergyMasterNegativeControl.tscn"
	if not ResourceLoader.exists(path):
		check(false, "Isolated energy-master scene exists")
		quit(1)
		return
	var preview = load(path).instantiate()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	preview.set_time(2.5)
	check(not preview.entity.iris.is_visible_in_tree(), "Opening is a vortex without the iris")
	var black_meshes := 0
	for mesh in preview.entity.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_override is StandardMaterial3D:
			black_meshes += 1
	check(black_meshes == 1, "Exactly one opaque core throughout the emergence")
	check(preview.entity.core.position.is_equal_approx(Vector3(0,0,0.55)), "Eye has a fixed centre before growth")
	for opening_time in [0.0,0.5,1.5,2.5,3.0]:
		preview.set_time(opening_time)
		check(not preview.entity.core.is_visible_in_tree(), "No black pupil during vortex-only opening")
	preview.set_time(3.01)
	check(preview.entity.core.scale.x < 0.001, "Pupil starts growing from zero without a pop")
	preview.set_time(8.0)
	check(preview.entity.core.is_visible_in_tree() and is_equal_approx(preview.entity.core.scale.x,1.0), "Pupil fully forms after emergence")
	var emergence = preview.entity.get_node_or_null("EyeEmergence")
	check(emergence != null, "Eye emerges as a separate volume")
	check(preview.entity.get_node_or_null("BirthVortex") != null, "A birth vortex precedes the eye")
	if emergence != null:
		preview.set_time(4.0)
		var early_position: Vector3 = emergence.position
		var early_orbit_position: Vector3 = preview.entity.orbit.position
		var early_size: float = emergence.scale.x
		preview.set_time(8.0)
		check(emergence.position.is_equal_approx(early_position), "Eye grows in place without coming forward")
		check(preview.entity.orbit.position.is_equal_approx(early_orbit_position), "Orbit stays in place during growth")
		check(emergence.scale.x > early_size + 0.5, "Eye grows around its fixed centre")
	preview.gaze_button.button_pressed = true
	preview.set_time(2.5)
	check(not preview.entity.iris.is_visible_in_tree(), "Forced gaze cannot bypass vortex opening")
	check(not preview.entity.core.is_visible_in_tree(), "Forced gaze cannot reveal pupil early")
	preview.gaze_button.button_pressed = false
	preview.set_time(3.0)
	var previous_position: Vector3 = preview.entity.core.position
	var previous_scale: float = preview.entity.core.scale.x
	for frame in range(1,301):
		preview.set_time(3.0 + float(frame)/60.0)
		check(preview.entity.core.position.is_equal_approx(previous_position), "Core stays fixed throughout growth")
		check(preview.entity.core.position.is_equal_approx(preview.entity.birth_vortex.transform * Vector3(0,0,-0.95)), "Vortex and pupil share the same centre")
		check(absf(preview.entity.core.scale.x - previous_scale) < 0.0051, "Core growth stays continuous")
		check(preview.entity.core.position.is_equal_approx(preview.entity.eye_root.position), "Iris follows the single pupil")
		previous_position = preview.entity.core.position
		previous_scale = preview.entity.core.scale.x
	for angle in [-38.0,0.0,38.0]:
		preview.set_view_angle(angle)
		for moment in [2.5,3.5,4.5,5.5]:
			preview.set_time(moment)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			preview.viewport.get_texture().get_image().save_png("res://artifacts/energy-master/core-%d-%d.png" % [int(angle),int(moment*10)])
	preview.set_view_angle(0.0)
	for shot_time in [2.5,5.5,9.0]:
		preview.set_time(shot_time)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/energy-master/emergence-%02d.png" % int(shot_time))
	preview.set_time(9.0)
	preview.set_paused(true)
	preview._process(1.0)
	check(is_equal_approx(preview.clock, 9.0), "Pause holds preview time")
	preview.set_paused(false)
	preview._process(0.25)
	check(is_equal_approx(preview.clock, 9.25), "Resume advances single clock")
	preview.set_paused(true)
	for extent in [Vector2i(1280,720), Vector2i(390,844), Vector2i(844,390)]:
		root.size = extent
		await process_frame
		await process_frame
		preview.set_time(9.0)
		await RenderingServer.frame_post_draw
		check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(preview.controls.get_global_rect()), "Controls fit %s" % extent)
		check(preview.stage.size.x > 100 and preview.stage.size.y > 100, "Stage remains usable %s" % extent)
		root.get_texture().get_image().save_png("res://artifacts/energy-master/%dx%d.png" % [extent.x,extent.y])
	root.size = Vector2i(1280,720)
	await process_frame
	await process_frame
	preview.set_time(7.0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var first: Image = preview.viewport.get_texture().get_image()
	first.save_png("res://artifacts/energy-master/seek-first.png")
	preview.set_time(8.0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var second: Image = preview.viewport.get_texture().get_image()
	check(first.get_data() != second.get_data(), "Energy visibly changes over time")
	preview.set_time(7.0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	# Additive GPU blending can round a few channels by one byte when render
	# order changes. Reject any larger change, or differences in >0.01% bytes.
	var original := first.get_data()
	var returned: PackedByteArray = preview.viewport.get_texture().get_image().get_data()
	var changed := 0
	var max_difference := 0
	check(original.size() == returned.size(), "Seeking preserves render size")
	for index in mini(original.size(),returned.size()):
		var difference := absi(int(original[index])-int(returned[index]))
		if difference > 0: changed += 1
		max_difference = maxi(max_difference,difference)
	print("SEEK_GPU: changed_bytes=",changed," max_difference=",max_difference)
	check(max_difference <= 1 and changed <= original.size()/10000, "Seeking reproduces image within sparse GPU rounding")
	preview.viewport.get_texture().get_image().save_png("res://artifacts/energy-master/seek-return.png")
	preview.set_time(9.0)
	preview.set_view_angle(38.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/energy-master/orbit.png")
	print("ENERGY_MASTER_CHECK: failures=", failures)
	quit(0 if failures == 0 else 1)
