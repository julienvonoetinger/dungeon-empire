extends SceneTree
## No game session or save; native corridor asset/playback verification.
var failures: Array[String] = []
var checks := 0
var output_dir := "res://artifacts/batrafian-gaits/"
var summaries: Array[Dictionary] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	for path in ["res://scenes/BatrafianWalk.tscn", "res://scenes/BatrafianRun.tscn"]:
		check(ResourceLoader.exists(path), "Missing batrafian gait scene: " + path)
	if not failures.is_empty():
		print("BATRAFIAN_GAITS: ", checks, " checks, ", failures.size(), " failures")
		quit(1)
		return
	call_deferred("capture")

func settle() -> void:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw

func screenshot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(output_dir + name + ".png") == OK, "Capture " + name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for gait in ["walk", "run"]:
		root.size = Vector2i(1280, 720)
		var scene_path := "res://scenes/BatrafianWalk.tscn" if gait == "walk" else "res://scenes/BatrafianRun.tscn"
		var preview = load(scene_path).instantiate()
		root.add_child(preview)
		await settle()
		var fps := 15.0 if gait == "walk" else 16.0
		var speed := 1.125 if gait == "walk" else 1.76
		check(preview.walk_time > 0.0, gait + " autoplay")
		check(preview.pose_fps == fps and preview.base_playback_rate == 1.0, gait + " cadence")
		check(is_equal_approx(preview.model_travel_units_per_second, speed), gait + " model stride")
		check(preview.actors.size() == 2 and preview.corridors.size() == 2, gait + " two corridors")
		preview.set_playing(false)
		preview.set_process(false)
		preview.set_walk_time(0.0)
		var start: Vector2 = preview.actors[0].position
		preview._process(.25)
		check(preview.walk_time == 0.0 and preview.actors[0].position == start, gait + " pause")
		preview.next_pose()
		check(preview.actors[0].frame == 1 and preview.actors[0].position != start, gait + " next pose travels")
		preview.set_walk_time(7.0 / fps)
		preview.next_pose()
		check(preview.actors[0].frame == 0, gait + " cycle wrap")
		preview.set_walk_time(0.0)
		preview.set_speed_index(1)
		preview.set_playing(true)
		preview._process(2.0 / fps)
		var normal: Vector2 = preview.actors[0].position
		check(preview.actors[0].frame == 2, gait + " normal frame clock")
		preview.set_walk_time(0.0)
		preview.set_speed_index(3)
		preview._process(2.0 / fps)
		check(preview.actors[0].frame == 4, gait + " double frame clock")
		check(preview.actors[0].position.is_equal_approx(start + (normal - start) * 2), gait + " double travel clock")
		preview.set_speed_index(1)
		preview.set_playing(false)
		var duration: float = preview.corridors[0].leg_duration()
		var seen := {}
		for phase in [0.0, .25, .5, .75, 1.0, 1.25, 1.5, 1.75, 2.0, 4.5]:
			preview.set_walk_time(duration * phase)
			for index in 2:
				var corridor = preview.corridors[index]
				var actor: AnimatedSprite2D = preview.actors[index]
				seen[actor.animation] = true
				check(actor.name == "Batrafian", gait + " actor identity")
				check(actor.offset.is_equal_approx(-corridor.frame_anchor) and actor.scale.is_equal_approx(Vector2.ONE * corridor.frame_scale), gait + " sprite registration")
				check(is_equal_approx(corridor.cells_per_second, speed * (256.0 / 2.6) * .70710678 / 128.0 * (.85 * 2.6 / 2.35)), gait + " camera-calibrated displacement")
				check(actor.sprite_frames.get_frame_count(actor.animation) == 8, gait + " eight poses")
				for pose in 8:
					var texture: AtlasTexture = actor.sprite_frames.get_frame_texture(actor.animation, pose)
					check(texture != null and texture.region.size == Vector2(256, 256) and texture.atlas.resource_path.contains("batrafian-" + gait), gait + " batrafian-only atlas")
				var fixed: float = corridor.hero_grid.y if index == 0 else corridor.hero_grid.x
				check(is_equal_approx(fixed, .5), gait + " centerline")
				if phase == 1.0:
					check(corridor.hero_grid.is_equal_approx(corridor.path_end), gait + " far turn")
				if phase == 2.0:
					check(corridor.hero_grid.is_equal_approx(corridor.path_start), gait + " returned")
				var extent: float = corridor.actor_half_extent
				for solid in corridor._solids:
					var behind: bool = corridor.hero_grid.x + extent <= solid.min.x or corridor.hero_grid.y + extent <= solid.min.y
					var opposite: bool = solid.max.x <= corridor.hero_grid.x - extent or solid.max.y <= corridor.hero_grid.y - extent
					if behind and not opposite and solid.rect.intersects(Rect2(actor.position - corridor.frame_anchor * corridor.frame_scale, Vector2.ONE * corridor.frame_size * corridor.frame_scale)):
						check(actor.get_index() < solid.node.get_index(), gait + " foreground rail order")
		check(seen.size() == 4, gait + " all four directions")
		preview.set_walk_time(duration * .5)
		await screenshot(gait + "-outbound")
		preview.set_walk_time(duration * 1.5)
		await screenshot(gait + "-return")
		preview.set_walk_time(3.0 / fps)
		await screenshot(gait + "-passing")
		for viewport_size in [Vector2i(844, 390), Vector2i(720, 960)]:
			root.size = viewport_size
			await screenshot(gait + "-%dx%d" % [viewport_size.x, viewport_size.y])
			for button in preview.find_children("*", "BaseButton", true, false):
				check(preview.get_global_rect().encloses(button.get_global_rect()), gait + " controls fit " + str(viewport_size))
			for corridor in preview.corridors:
				var stage: Control = corridor.get_parent()
				check(Rect2(Vector2.ZERO, stage.size).grow(.1).encloses(corridor.transform * corridor.get_content_rect()), gait + " whole corridor fits")
		preview.set_walk_time(0.0)
		preview.set_process(true)
		preview.set_playing(true)
		await create_timer(.25).timeout
		check(preview.walk_time > .15 and preview.actors[0].position.distance_to(start) > 1, gait + " live movement resumes")
		summaries.append({"gait": gait, "fps": fps, "model_speed": speed, "seconds_per_leg": duration, "directions": seen.keys()})
		preview.queue_free()
		await process_frame
	var file := FileAccess.open(output_dir + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "gaits": summaries}, "\t"))
	file.close()
	print("BATRAFIAN_GAITS: ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
