extends SceneTree
const SCENE := preload("res://scenes/VulpinHurt.tscn")
const OUT := "res://docs/reference/vulpin-review/v19-hurt-recoil/native-scene/"
var failures: Array[String] = []

func _initialize() -> void:
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
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture " + name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280, 720)
	var preview := SCENE.instantiate()
	root.add_child(preview)
	await settle()
	check(preview.hit_count == 1 and preview.reaction_time > 0.0, "Autoplay starts one reaction")
	check(is_equal_approx(preview.reaction_duration, .72), "720 ms one-shot")
	check(preview.actors.size() == 4, "Four directions")
	for actor in preview.actors:
		check(not actor.sprite_frames.get_animation_loop(actor.animation), "Resource does not loop")
		check(actor.sprite_frames.get_frame_count(actor.animation) == 8, "Eight reaction stages")
		var last: AtlasTexture = actor.sprite_frames.get_frame_texture(actor.animation, 7)
		check(last.region.position.x == 0, "Final frame reuses neutral pose")
	preview.set_repeat_enabled(false)
	preview.trigger_hit()
	preview.set_playing(false)
	var frozen_time: float = preview.reaction_time
	await create_timer(.2).timeout
	check(preview.reaction_time == frozen_time and preview.actors[0].frame == 0, "Pause freezes reaction")
	await screenshot("impact")
	preview.next_pose()
	check(preview.actors[0].frame == 1, "Step advances to recoil")
	await screenshot("recoil")
	preview.seek_reaction(.2)
	check(preview.actors[0].frame == 3, "Peak recoil has a dedicated hold")
	await screenshot("peak")
	preview.seek_reaction(.42)
	await screenshot("recovery")
	preview.set_process(false)
	preview.trigger_hit()
	preview._process(.8)
	check(not preview.active and preview.actors[0].frame == 7, "One-shot finishes at rest")
	var count: int = preview.hit_count
	preview._process(2.0)
	check(preview.hit_count == count and preview.actors[0].frame == 7, "No repeat when disabled")
	preview.set_playing(false)
	await screenshot("neutral")
	preview.next_pose()
	check(preview.actors[0].frame == 0, "Step wraps from rest to impact")
	preview.trigger_hit()
	preview._process(.15)
	check(preview.actors[0].frame == 2, "Reaction reaches deeper recoil")
	preview.trigger_hit()
	check(preview.reaction_time == 0.0 and preview.actors[0].frame == 0, "New hit restarts active reaction")
	preview.set_speed_index(0)
	preview._process(.2)
	check(is_equal_approx(preview.reaction_time, .1), "Half speed timing")
	preview.trigger_hit()
	preview.set_speed_index(3)
	preview._process(.36)
	check(not preview.active and preview.actors[0].frame == 7, "Double speed finishes in 360 ms")
	preview.set_speed_index(1)
	preview.set_repeat_enabled(true)
	count = preview.hit_count
	preview._process(.7)
	check(preview.hit_count == count, "Rest gap before repeat")
	preview._process(.11)
	check(preview.hit_count == count + 1 and preview.actors[0].frame == 0, "Repeat retriggers after gap")
	preview.set_repeat_enabled(false)
	preview.trigger_hit()
	preview.set_process(true)
	await create_timer(.85).timeout
	check(not preview.active and preview.actors[0].frame == 7, "Live clock completes the one-shot")
	preview.set_playing(false)
	preview.seek_reaction(.1)
	for actor in preview.actors:
		check(actor.frame == 1 and actor.position == Vector2.ZERO, "Synchronized pose without cell displacement")
	for viewport_size in [Vector2i(844, 390), Vector2i(720, 960)]:
		root.size = viewport_size
		await screenshot("layout-%dx%d" % [viewport_size.x, viewport_size.y])
		for node in preview.find_children("*", "BaseButton", true, false):
			check(preview.get_global_rect().encloses(node.get_global_rect()), "Button fits " + str(viewport_size))
	var report := {"scene": SCENE.resource_path, "directions": 4, "duration_seconds": .72,
		"failures": failures, "checks": ["one-shot resource and neutral finish", "autoplay", "pause", "step/wrap", "retrigger", "0.5x and 2x timing", "optional repeat and rest gap", "live playback", "fixed ground anchors", "three viewport sizes"]}
	var file := FileAccess.open(OUT + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("VULPIN_HURT_SCENE: failures=", failures.size())
	preview.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
