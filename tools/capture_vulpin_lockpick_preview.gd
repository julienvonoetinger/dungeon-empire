extends SceneTree
const SCENE_PATH := "res://scenes/VulpinLockpick.tscn"
const OUT := "res://docs/reference/vulpin-review/v20-door-lockpick/native-scene/"
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("capture")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture " + name)

func capture() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		push_error("Missing four-door lockpick review scene")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280, 900)
	var preview = load(SCENE_PATH).instantiate()
	root.add_child(preview)
	await settle()
	check(preview.animation_time > 0, "Autoplay")
	preview.set_playing(false)
	var before: float = preview.animation_time
	await create_timer(.15).timeout
	check(preview.animation_time == before, "Pause")
	check(preview.stages.size() == 4, "Four real door stages")
	check(preview._distance.value == 0, "Distance starts at calibrated zero")
	preview.seek_time(0)
	for i in 8:
		preview.seek_time(i / 8.0)
		for stage in preview.stages:
			check(stage.actor.frame == i, "Synchronized pose")
			check(stage.registration_error() < .01, "Tool is at lock " + stage.facing)
			check(stage.solid_count() > 2, "Native door/wall parts")
			check(stage.actor.sprite_frames.get_animation_loop(stage.actor.animation), "Loop resource")
		await shot("pose-%02d" % i)
	preview.next_pose()
	check(preview.stages[0].actor.frame == 0, "Step wraps")
	preview.set_distance(.08)
	for stage in preview.stages: check(stage.registration_error() > 8, "Distance control moves actor")
	await shot("distance-offset")
	preview.set_distance(0)
	preview.set_guides(true)
	preview.set_ghost(true)
	await shot("registration-guides")
	preview.set_guides(false)
	for i in 8:
		preview.seek_time(i / 8.0)
		await shot("ghost-pose-%02d" % i)
	preview.set_ghost(false)
	preview.set_guides(false)
	preview.set_process(false)
	preview.seek_time(0)
	preview.set_speed_index(3)
	preview.set_playing(true)
	preview._process(.25)
	check(is_equal_approx(preview.animation_time, .5), "Double speed")
	preview.set_speed_index(0)
	preview._process(.25)
	check(is_equal_approx(preview.animation_time, .625), "Half speed")
	preview.set_speed_index(1)
	preview.set_playing(false)
	preview.seek_time(1)
	check(preview.stages[0].actor.frame == 0, "Continuous loop wrap")
	for viewport_size in [Vector2i(1280,720), Vector2i(844,390), Vector2i(720,960)]:
		root.size = viewport_size
		await shot("layout-%dx%d" % [viewport_size.x, viewport_size.y])
		for node in preview.find_children("*", "BaseButton", true, false):
			check(preview.get_global_rect().encloses(node.get_global_rect()), "Control fits viewport")
	var file := FileAccess.open(OUT + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "directions": 4, "poses": 8,
		"checks": ["native door scenes", "32 tool/lock projections", "pause/step/loop", "speed", "distance", "guides/ghost", "four viewport sizes"]}, "\t"))
	file.close()
	print("VULPIN_LOCKPICK_SCENE failures=", failures.size())
	preview.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
