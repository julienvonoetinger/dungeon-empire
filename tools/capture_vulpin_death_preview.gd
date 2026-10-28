extends SceneTree
const SCENE := preload("res://scenes/VulpinDeath.tscn")
const OUT := "res://docs/reference/vulpin-review/v24-meshy-dead/native-scene/"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("capture")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for f in 5:
		await process_frame
	await RenderingServer.frame_post_draw

func screenshot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Save " + name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280, 900)
	var preview := SCENE.instantiate()
	root.add_child(preview)
	await settle()
	check(preview.fall_count == 1 and preview.fall_time > 0, "Autoplay")
	check(not preview.repeat_enabled, "Repeat off by default")
	check(is_equal_approx(preview.fall_duration, .55), "One-shot duration 550 ms at normal speed")
	preview.set_playing(false)
	for actor in preview.actors:
		var frames: SpriteFrames = actor.sprite_frames
		check(frames.get_frame_count(actor.animation) == 10, "Ten fall frames")
		check(not frames.get_animation_loop(actor.animation), "Fall not looping")
		var dead: StringName = StringName("dead-" + str(actor.animation))
		check(frames.get_frame_count(dead) == 1 and not frames.get_animation_loop(dead), "Static corpse")
		check(frames.get_frame_texture(dead, 0) == frames.get_frame_texture(actor.animation, 9), "Corpse shares final pixels")
		for frame in 10:
			check(frames.get_frame_texture(actor.animation, frame).get_size() == Vector2(384, 384), "Trimmed frame retains virtual canvas")
	for pose in 10:
		preview.seek_fall(preview._starts[pose])
		for actor in preview.actors:
			check(actor.frame == pose, "Synchronized pose %d" % pose)
		await screenshot("pose-%02d" % pose)
	preview.trigger_fall()
	preview.set_playing(true)
	await create_timer(.7).timeout
	check(not preview.active and preview.actors[0].frame == 9, "Live one-shot ends on corpse")
	var count: int = preview.fall_count
	await create_timer(.25).timeout
	check(preview.fall_count == count and preview.actors[0].frame == 9, "Corpse persists without restarting")
	preview.set_playing(false)
	preview.seek_fall(.4)
	var time: float = preview.fall_time
	await create_timer(.15).timeout
	check(preview.fall_time == time, "Pause")
	preview.seek_fall(.55)
	preview.next_pose()
	check(preview.actors[0].frame == 0, "Manual step wraps")
	preview.set_process(false)
	preview.trigger_fall()
	preview.set_speed_index(0)
	preview._process(.2)
	check(is_equal_approx(preview.fall_time, .1), "Half speed")
	preview.trigger_fall()
	preview.set_speed_index(3)
	preview._process(.275)
	check(not preview.active and preview.actors[0].frame == 9, "Double speed")
	preview.set_speed_index(1)
	preview.set_repeat_enabled(true)
	preview._process(1.21)
	check(preview.active and preview.actors[0].frame == 0, "Optional repeat")
	preview.set_repeat_enabled(false)
	preview.set_playing(false)
	preview.seek_fall(.55)
	for viewport_size in [Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = viewport_size
		await screenshot("layout-%dx%d" % [viewport_size.x, viewport_size.y])
		for node in preview.find_children("*", "BaseButton", true, false):
			check(preview.get_global_rect().encloses(node.get_global_rect()), "Control fits " + str(viewport_size))
	var report := {"scene": SCENE.resource_path, "checks": checks, "failures": failures,
		"poses": 10, "directions": 4, "duration_seconds": .55, "corpse_persists": true,
		"limits": "Desktop native review only; no phone or gameplay validation."}
	var file := FileAccess.open(OUT + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("VULPIN_DEATH_SCENE: checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
