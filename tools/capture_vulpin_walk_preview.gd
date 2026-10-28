extends SceneTree
## Exercise and capture the isolated corridor scene, without a game or save.
const SCENE := preload("res://scenes/VulpinWalk.tscn")
var scene_resource: PackedScene = SCENE
var output_dir := "res://docs/reference/vulpin-review/v16-meshy-walk/native-corridors/"
var run_mode := false
var failures: Array[String] = []

func _initialize() -> void:
	run_mode = OS.get_cmdline_user_args().has("--run")
	if run_mode:
		scene_resource = load("res://scenes/VulpinRun.tscn")
		output_dir = "res://docs/reference/vulpin-review/v17-meshy-run/native-corridors/"
	call_deferred("capture")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw

func screenshot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(output_dir + name + ".png") == OK, "Capture " + name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280, 720)
	var preview := scene_resource.instantiate()
	root.add_child(preview)
	await settle()
	var sample_fps := 16.0 if run_mode else 10.0
	var normal_fps := 16.0 if run_mode else 15.0
	var normal_rate := 1.0 if run_mode else 1.5
	check(preview.pose_fps == sample_fps and preview.base_playback_rate == normal_rate, "Expected default gait cadence")
	check(preview.model_travel_units_per_second == (2.0 if run_mode else .65), "Expected gait stride")
	check(preview.actors.size() == 2 and preview.corridors.size() == 2, "Two corridor walkers")
	check(preview.walk_time > 0.0, "Autoplay advances shared clock")
	preview.set_playing(false)
	preview.set_walk_time(0.0)
	var start_position: Vector2 = preview.actors[0].position
	await create_timer(.2).timeout
	check(preview.walk_time == 0.0 and preview.actors[0].frame == 0 and preview.actors[0].position == start_position, "Pause freezes pose and travel")
	preview.next_pose()
	check(preview.actors[0].frame == 1 and preview.actors[0].position != start_position, "Single pose step also advances travel")
	preview.set_walk_time(7.0 / sample_fps)
	preview.next_pose()
	check(preview.actors[0].frame == 0, "Eight-frame wrap")
	# Deterministic clock checks complement actual live playback above/below.
	preview.set_process(false)
	preview.set_walk_time(0.0)
	preview.set_speed_index(0)
	preview.set_playing(true)
	preview._process(4.0 / normal_fps)
	var half_position: Vector2 = preview.actors[0].position
	check(is_equal_approx(preview.walk_time, 2.0 / sample_fps) and preview.actors[0].frame == 2, "Half rate advances time and pose")
	preview.set_walk_time(0.0)
	preview.set_speed_index(1)
	preview._process(4.0 / normal_fps)
	check(is_equal_approx(preview.walk_time, 4.0 / sample_fps) and preview.actors[0].frame == 4 and preview.actors[0].position.is_equal_approx(start_position + (half_position - start_position) * 2), "Normal rate synchronizes travel and cadence")
	preview.set_walk_time(0.0)
	preview.set_speed_index(3)
	preview._process(2.0 / normal_fps)
	check(is_equal_approx(preview.walk_time, 4.0 / sample_fps) and preview.actors[0].frame == 4 and preview.actors[0].position.is_equal_approx(start_position + (half_position - start_position) * 2), "Double rate synchronizes travel and poses")
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
			check(actor.sprite_frames.get_frame_count(actor.animation) == 8, "Eight poses " + str(actor.animation))
			var variable: float = corridor.hero_grid.x if index == 0 else corridor.hero_grid.y
			var fixed: float = corridor.hero_grid.y if index == 0 else corridor.hero_grid.x
			check(variable >= .55 - .00001 and variable <= 2.45 + .00001 and is_equal_approx(fixed, .5), "Walk stays on corridor centre line")
			if phase == 1.0:
				check(corridor.hero_grid.is_equal_approx(corridor.path_end), "Turn at far end")
			if phase == 2.0:
				check(corridor.hero_grid.is_equal_approx(corridor.path_start), "Return to start")
			# A foreground rail must be drawn after the actor where they overlap.
			for solid in corridor._solids:
				var behind: bool = corridor.hero_grid.x + .16 <= solid.min.x or corridor.hero_grid.y + .16 <= solid.min.y
				# Diagonally disjoint supports can be separated on opposite axes;
				# their large transparent sprite rectangles do not imply occlusion.
				var opposite: bool = solid.max.x <= corridor.hero_grid.x - .16 or solid.max.y <= corridor.hero_grid.y - .16
				if behind and not opposite and solid.rect.intersects(Rect2(actor.position - corridor.ANCHOR * corridor.HERO_SCALE, Vector2.ONE * 256 * corridor.HERO_SCALE)):
					check(actor.get_index() < solid.node.get_index(), "Foreground masonry occludes walker: axis=%d phase=%.2f id=%s min=%s max=%s hero=%s" % [index, phase, solid.id, solid.min, solid.max, corridor.hero_grid])
	check(seen.size() == 4, "All four facing directions encountered")
	preview.set_walk_time(duration * .5)
	check(preview.actors[0].animation == &"se" and preview.actors[1].animation == &"sw", "Outbound direction pair")
	await screenshot("outbound")
	preview.set_walk_time(duration * 1.5)
	check(preview.actors[0].animation == &"nw" and preview.actors[1].animation == &"ne", "Return direction pair")
	await screenshot("return")
	preview.set_walk_time(duration)
	await screenshot("far-end")
	preview.set_walk_time(0.0)
	await screenshot("near-end")
	if run_mode:
		preview.set_walk_time(3.0 / sample_fps)
		await screenshot("suspension")
		preview.set_walk_time(0.0)
	preview.set_process(true)
	preview.set_playing(true)
	await create_timer(.25).timeout
	check(preview.walk_time > .15 and preview.actors[0].position.distance_to(start_position) > 1.0, "Live playback resumes root movement")
	preview.set_playing(false)
	preview.set_walk_time(duration * .5)
	for viewport_size in [Vector2i(844, 390), Vector2i(720, 960)]:
		root.size = viewport_size
		await screenshot("layout-%dx%d" % [viewport_size.x, viewport_size.y])
		for node in preview.find_children("*", "BaseButton", true, false):
			check(preview.get_global_rect().encloses(node.get_global_rect()), "Button outside viewport at " + str(viewport_size))
		for corridor in preview.corridors:
			var stage: Control = corridor.get_parent()
			var fitted: Rect2 = corridor.transform * corridor.get_content_rect()
			check(Rect2(Vector2.ZERO, stage.size).grow(.1).encloses(fitted), "Whole corridor fits stage")
	var report := {"scene": scene_resource.resource_path, "corridors": 2, "poses_per_direction": 8,
		"directions": seen.keys(), "seconds_per_leg": duration / normal_rate,
		"normal_poses_per_second": normal_fps, "failures": failures,
		"checks": ["live autoplay", "pause freezes travel and pose", "single clock and rate", "double rate travel and poses", "four facing directions", "endpoints and repeated reversal", "centreline path", "foreground wall ordering", "three viewport sizes"]}
	var file := FileAccess.open(output_dir + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("VULPIN_", "RUN" if run_mode else "WALK", "_CORRIDORS: failures=", failures.size())
	preview.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
