extends SceneTree
const SCENE_PATH := "res://scenes/VulpinChestLockpick.tscn"
const OUT := "res://docs/reference/vulpin-review/v22-chest-lockpick/native-scene/"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("capture")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture " + name)

func check_locked_chest(stage: Node2D, context: String) -> void:
	var count := 0
	for node in stage._world.get_children():
		if not node is Sprite2D: continue
		var id := str(node.get_meta("prepared_id", ""))
		if not id.begins_with("prop-chest"): continue
		check(not id.begins_with("prop-chest-open"), "No unlocked art, including shadow: " + context)
		if id.ends_with("-shadow"): continue
		count += 1
		check(node.visible, "Closed chest visible: " + context)
	check(count == 1, "One locked painting: " + context)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280,900)
	var preview = load(SCENE_PATH).instantiate()
	root.add_child(preview)
	await settle()
	check(preview.animation_time > 0, "Live autoplay")
	preview.set_playing(false)
	var before: float = preview.animation_time
	await create_timer(.15).timeout
	check(preview.animation_time == before, "Pause freezes clock")
	check(preview.stages.size() == 4, "Four chest orientations")
	for i in 8:
		preview.seek_time(i / 8.0)
		for stage in preview.stages:
			check_locked_chest(stage, stage.facing + " pose " + str(i))
			check(stage.actor.frame == i, "Shared held pose")
			check(stage.registration_error() < .01, "Projected fixed tool tip at lock: " + stage.facing)
			var actor_in_front: bool = stage.actor.get_index() > stage.chest.node.get_index()
			check(actor_in_front == (stage.facing in ["nw","ne"]), "Native actor/chest ordering: " + stage.facing)
			var frames: SpriteFrames = stage.actor.sprite_frames
			check(frames.get_animation_loop(stage.actor.animation), "Attempt loops")
			check(frames.get_frame_count(stage.actor.animation) == 8, "Eight held poses")
		await shot("pose-%02d" % i)
	preview.next_pose()
	check(preview.stages[0].actor.frame == 0 and not preview._playing, "Step wraps and pauses")
	preview.set_process(false)
	preview.restart_attempt()
	check(preview.animation_time == 0 and preview._playing, "Restart begins loop")
	preview.set_speed_index(3)
	preview._process(.25)
	check(is_equal_approx(preview.animation_time,.5), "Double speed")
	preview.set_speed_index(0)
	preview._process(.25)
	check(is_equal_approx(preview.animation_time,.625), "Half speed")
	preview.set_speed_index(1)
	preview.set_playing(false)
	for elapsed in [1.0,12.125,100.5]:
		preview.seek_time(elapsed)
		for stage in preview.stages:
			check_locked_chest(stage, "Repeated attempt")
			check(stage.actor.frame == floori(elapsed * 8) % 8, "Continuous repeated timing")
	preview.set_guides(true)
	await shot("contact-guides")
	preview.set_ghost(true)
	await shot("ghost-contact-guides")
	preview.set_guides(false)
	for i in 8:
		preview.seek_time(i / 8.0)
		await shot("ghost-pose-%02d" % i)
	preview.set_ghost(false)
	preview.seek_time(0)
	for viewport_size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size = viewport_size
		await shot("layout-%dx%d" % [viewport_size.x,viewport_size.y])
		for node in preview.find_children("*", "BaseButton", true, false):
			check(preview.get_global_rect().encloses(node.get_global_rect()), "Control fits viewport")
	var file := FileAccess.open(OUT + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"directions":4,"poses":8,
		"limits":"Native review only. Locked chest stays closed throughout the attempt. Contact and separation use calibrated proxies, not reconstructed painted chest geometry."}, "\t"))
	file.close()
	print("VULPIN_CHEST_LOCKPICK_SCENE checks=",checks," failures=",failures.size())
	preview.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
