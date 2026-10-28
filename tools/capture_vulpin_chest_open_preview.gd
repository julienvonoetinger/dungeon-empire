extends SceneTree
const SCENE_PATH := "res://scenes/VulpinChestOpen.tscn"
const OUT := "res://docs/reference/vulpin-review/v21-chest-open/native-scene/"
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

func check_unlocked_chest(stage: Node2D, context: String) -> void:
	var chest_nodes: Array[Sprite2D] = []
	for node in stage._world.get_children():
		if not node is Sprite2D: continue
		var id := str(node.get_meta("prepared_id", ""))
		if id.begins_with("prop-chest") and not id.ends_with("-shadow"):
			chest_nodes.append(node)
	check(chest_nodes.size() == 1, "One unlocked chest painting: " + context)
	for node in chest_nodes:
		check(str(node.get_meta("prepared_id")).begins_with("prop-chest-open"), "No locked chest artwork: " + context)
		check(node.visible, "Ajar chest remains visible: " + context)

func shot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Capture " + name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280,900)
	var preview = load(SCENE_PATH).instantiate()
	root.add_child(preview)
	await settle()
	check(preview.animation_time > 0, "Autoplay")
	preview.set_playing(false)
	var before: float = preview.animation_time
	await create_timer(.15).timeout
	check(preview.animation_time == before, "Pause")
	check(preview.stages.size() == 4, "Four directional chest stages")
	for stage in preview.stages: check_unlocked_chest(stage, "initial " + stage.facing)
	check(is_equal_approx(preview.duration, 1.08), "One-shot duration")
	for i in 8:
		preview.seek_time(preview._starts[i])
		for stage in preview.stages:
			check_unlocked_chest(stage, stage.facing + " pose " + str(i))
			check(stage.actor.frame == i, "Synchronized pose")
			if i == 2: check(stage.registration_error() < .01, "Ajar grip projection " + stage.facing)
			var actor_in_front: bool = stage.actor.get_index() > stage.chest.node.get_index()
			check(actor_in_front == (stage.facing in ["nw","ne"]), "Physical chest ordering " + stage.facing)
			check(not stage.actor.sprite_frames.get_animation_loop(stage.actor.animation), "Non-loop resource")
		await shot("pose-%02d" % i)
	preview.set_repeat_enabled(false)
	preview.set_process(false)
	preview.seek_time(preview.duration)
	preview.set_playing(true)
	preview._process(3)
	check(not preview.active and preview.stages[0].actor.frame == 7, "Holds final gesture pose")
	for stage in preview.stages: check_unlocked_chest(stage, "completion " + stage.facing)
	preview.replay_opening()
	check(preview.active and preview.animation_time == 0, "Replay restarts")
	for stage in preview.stages: check_unlocked_chest(stage, "replay " + stage.facing)
	preview.set_speed_index(3)
	preview._process(.2)
	check(is_equal_approx(preview.animation_time,.4), "Double speed")
	preview.set_speed_index(0)
	preview._process(.2)
	check(is_equal_approx(preview.animation_time,.5), "Half speed")
	preview.set_speed_index(1)
	preview.seek_time(preview.duration)
	preview.next_pose()
	check(preview.stages[0].actor.frame == 0 and not preview._playing, "Step wraps and pauses")
	for stage in preview.stages: check_unlocked_chest(stage, "step wrap " + stage.facing)
	preview.seek_time(preview.duration)
	preview.set_repeat_enabled(true)
	preview.set_playing(true)
	preview._process(.4)
	check(not preview.active, "Repeat rests after gesture")
	for stage in preview.stages: check_unlocked_chest(stage, "rest " + stage.facing)
	preview._process(.41)
	check(preview.active, "Repeat resets gesture after rest")
	for stage in preview.stages: check_unlocked_chest(stage, "repeat " + stage.facing)
	preview.set_playing(false)
	preview.seek_time(preview._starts[2])
	preview.set_guides(true)
	await shot("grip-guides")
	preview.set_ghost(true)
	await shot("ghost-grip")
	preview.seek_time(preview._starts[4])
	await shot("ghost-open-grip")
	preview.set_ghost(false)
	await shot("open-grip-guides")
	preview.set_ghost(false)
	preview.set_guides(false)
	for viewport_size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size = viewport_size
		await shot("layout-%dx%d" % [viewport_size.x,viewport_size.y])
		for node in preview.find_children("*", "BaseButton", true, false):
			check(preview.get_global_rect().encloses(node.get_global_rect()), "Control fits viewport")
	var file := FileAccess.open(OUT + "validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"directions":4,"poses":8,
		"limits":"Native review only. Unlocked chest stays ajar throughout; no locked painting or access-state transition. No animated lid or gameplay change."}, "\t"))
	file.close()
	print("VULPIN_CHEST_OPEN_SCENE checks=",checks," failures=",failures.size())
	preview.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
