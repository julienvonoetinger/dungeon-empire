extends SceneTree
const OUT := "res://artifacts/paladin-attack/"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr(message)

func settle() -> void:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw

func finish() -> void:
	var report := FileAccess.open(OUT + "native-validation.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "failures": failures}, "\t"))
	print("PALADIN_ATTACK ", checks, " checks / ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var file := "res://scenes/PaladinAttack.tscn"
	check(ResourceLoader.exists(file), "Attack scene exists")
	if not ResourceLoader.exists(file):
		finish()
		return
	root.size = Vector2i(1280,720)
	var preview = load(file).instantiate()
	root.add_child(preview)
	await settle()
	check(preview.trigger_count == 1 and preview.action_time > 0, "Autoplay")
	preview.set_process(false)
	preview.set_repeat_enabled(false)
	check(preview.actors.size() == 4 and preview.targets.size() == 4, "Four target directions")
	check(is_equal_approx(preview.action_duration, .9), "900ms attack")
	check(is_equal_approx(preview.impact_time, .45), "Impact follows wind-up at 450ms")
	for i in 4:
		var actor: AnimatedSprite2D = preview.actors[i]
		check(not actor.sprite_frames.get_animation_loop(actor.animation), "One-shot resource")
		check(actor.position == Vector2.ZERO, "Fixed ground anchor")
		check(actor.sprite_frames.get_frame_count(actor.animation) == 10, "Ten whole poses")
		var first := actor.sprite_frames.get_frame_texture(actor.animation,0).get_image()
		var last := actor.sprite_frames.get_frame_texture(actor.animation,9).get_image()
		check(first.get_data() == last.get_data(), "Exact guard return " + str(i))
		for j in 10:
			check(actor.sprite_frames.get_frame_texture(actor.animation,j).get_size() == Vector2(320,320), "Frame dimensions")
		var target = preview.targets[i]
		check(target.impact_point.distance_to(target.top_center()) < .001, "Hammer meets target center " + str(i))
	for speed in [0,1,3]:
		preview.set_speed_index(speed)
		preview.trigger_action()
		check(preview.impact_count == 0, "Replay resets hit count")
		preview.set_playing(false)
		preview._process(1)
		check(preview.action_time == 0 and preview.impact_count == 0, "Pause before hit")
		preview.set_playing(true)
		preview._process(.44 / preview.playback_speed)
		check(preview.impact_count == 0, "No premature hit")
		preview._process(.02 / preview.playback_speed)
		check(preview.impact_count == 1, "Crossed impact once at speed " + str(speed))
		preview.set_playing(false)
		var stopped: float = preview.action_time
		preview._process(1)
		check(preview.action_time == stopped and preview.impact_count == 1, "Pause during hit")
		preview.set_playing(true)
		preview._process(2)
		check(not preview.active and preview.actors[0].frame == 9 and preview.impact_count == 1, "Completes with one impact")
		preview._process(2)
		check(preview.impact_count == 1, "No repeated hit while holding guard")
	preview.trigger_action()
	preview._process(3)
	check(preview.impact_count == 1, "Large delta cannot skip impact")
	preview.trigger_action()
	preview.set_playing(false)
	for i in 5:
		preview.next_pose()
	check(preview.actors[0].frame == 5 and preview.impact_count == 0, "Scrubbing previews contact without firing impacts")
	preview.set_playing(true)
	preview._process(.5)
	check(preview.impact_count == 0, "No late hit after manual seek beyond impact")
	preview.set_speed_index(1)
	preview.set_repeat_enabled(true)
	preview.trigger_action()
	preview._process(1)
	var count: int = preview.trigger_count
	preview._process(1)
	check(preview.trigger_count == count + 1 and preview.impact_count == 0, "Repeat starts fresh strike")
	preview.set_repeat_enabled(false)
	preview.set_process(true)
	preview.trigger_action()
	await create_timer(1.1).timeout
	check(not preview.active and preview.impact_count == 1, "Live playback completes")
	preview.set_process(false)
	preview.set_playing(false)
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size = size
		for pose_time in [.31,.45,.51,.9]:
			preview.seek_action(pose_time)
			await settle()
			for button in preview.find_children("*", "BaseButton", true, false):
				check(preview.get_global_rect().encloses(button.get_global_rect()), "Controls fit " + str(size))
				check(button.size.y >= 48, "48px controls")
			for actor in preview.actors:
				var stage: Control = actor.get_parent().get_parent()
				var image: Image = actor.sprite_frames.get_frame_texture(actor.animation,actor.frame).get_image()
				var ink: Rect2 = image.get_used_rect()
				var a: Vector2 = actor.get_global_transform() * (ink.position + actor.offset)
				var b: Vector2 = actor.get_global_transform() * (ink.end + actor.offset)
				check(stage.get_global_rect().grow(1).encloses(Rect2(a,b-a)), "Actor ink fits stage " + str(size))
			check(root.get_texture().get_image().save_png("%sattack-%dx%d-%d.png" % [OUT,size.x,size.y,int(pose_time*1000)]) == OK, "Native capture")
	root.size = Vector2i(1280,720)
	for i in 10:
		preview.seek_action(preview._starts[i])
		await settle()
		check(root.get_texture().get_image().save_png(OUT + "frame-%02d.png" % i) == OK, "Native animation frame")
	preview.queue_free()
	await process_frame
	finish()
