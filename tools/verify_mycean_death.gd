extends SceneTree
const OUT := "res://artifacts/mycean-death/native/"
var failures: Array[String] = []
var checks := 0

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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for action in ["Death"]:
		var file: String = "res://scenes/Mycean" + action + ".tscn"
		check(ResourceLoader.exists(file), action + " scene exists")
		if not ResourceLoader.exists(file):
			continue
		root.size = Vector2i(1280, 720)
		var preview = load(file).instantiate()
		root.add_child(preview)
		await settle()
		check(preview.trigger_count == 1 and preview.action_time > 0, action + " autoplay")
		check(preview.actors.size() == 4, action + " four directions")
		preview.set_repeat_enabled(false)
		preview.trigger_action()
		preview.set_playing(false)
		var t: float = preview.action_time
		await create_timer(.15).timeout
		check(preview.action_time == t, action + " pause holds")
		preview.next_pose()
		check(preview.actors[0].frame == 1, action + " step")
		preview.set_process(false)
		for actor in preview.actors:
			check(actor.sprite_frames.get_frame_count(actor.animation) == 10, "Ten distinct poses")
			check(not actor.sprite_frames.get_animation_loop(actor.animation), action + " resource one-shot")
			check(actor.position == Vector2.ZERO, action + " root never slides")
			var expected_anchor := Vector2(160,199.224289)
			check(actor.offset.is_equal_approx(-expected_anchor), action + " registered ground anchor")
			for i in actor.sprite_frames.get_frame_count(actor.animation):
				var pixels := 320
				check(actor.sprite_frames.get_frame_texture(actor.animation,i).get_size() == Vector2(pixels,pixels), action + " frame bounds")
		var duration: float = preview.action_duration
		check(is_equal_approx(duration,.65), action + " specified duration")
		for speed in [0,1,3]:
			preview.set_speed_index(speed)
			preview.trigger_action()
			preview._process(.1)
			check(is_equal_approx(preview.action_time, .1 * [0.5,1.0,1.5,2.0][speed]), action + " rate " + str(speed))
			preview._process(duration * 3)
			check(not preview.active and preview.actors[0].frame == preview.phases.size()-1, action + " finishes")
			var count: int = preview.trigger_count
			preview._process(3)
			check(preview.trigger_count == count, action + " holds final state")
		preview.next_pose()
		check(preview.actors[0].frame == 0, action + " step wraps")
		preview.set_speed_index(1)
		preview.set_repeat_enabled(true)
		preview.set_playing(true)
		preview.seek_action(duration)
		var before: int = preview.trigger_count
		preview._process(.5)
		check(preview.trigger_count == before, action + " repeat waits")
		preview._process(1)
		check(preview.trigger_count == before + 1, action + " explicit repeat works")
		preview.set_repeat_enabled(false)
		preview.set_process(true)
		preview.trigger_action()
		await create_timer(duration+.15).timeout
		check(not preview.active, action + " live playback completes")
		preview.set_playing(false)
		for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
			root.size = size
			await settle()
			for pose in 10:
				preview.seek_action(preview._starts[pose])
				for actor in preview.actors:
					var texture: Texture2D = actor.sprite_frames.get_frame_texture(actor.animation, pose)
					var ink: Rect2i = texture.get_image().get_used_rect()
					var top_left: Vector2 = actor.to_global(actor.offset + Vector2(ink.position))
					var bottom_right: Vector2 = actor.to_global(actor.offset + Vector2(ink.end))
					var stage: Control = actor.get_parent().get_parent()
					check(stage.get_global_rect().grow(.1).encloses(Rect2(top_left,bottom_right-top_left)), "Visible sprite fits stage %s %s pose %d" % [size,actor.animation,pose])
			for fraction in [.28,.65,1.0]:
				preview.seek_action(duration*fraction)
				await settle()
				check(preview._grid.columns == (4 if size == Vector2i(844,390) else 2), action + " adaptive direction layout")
				for button in preview.find_children("*", "BaseButton", true, false):
					check(preview.get_global_rect().encloses(button.get_global_rect()), action + " control fits " + str(size))
					check(button.size.y >= 48, action + " usable control height")
				var capture := "%s%s-%dx%d-%d.png" % [OUT, action.to_lower(),size.x,size.y,int(fraction*100)]
				check(root.get_texture().get_image().save_png(capture) == OK, "saved native capture")
		preview.queue_free()
		await process_frame
	var report := FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("MYCEAN_DEATH ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
