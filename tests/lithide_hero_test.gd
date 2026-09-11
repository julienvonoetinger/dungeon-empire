extends SceneTree

const LITHIDE_SCRIPT := "res://scripts/world/lithide_hero.gd"
const WALK_MODEL := "res://assets/models/characters/lithide/hero_lithide_paladin_walking_v3.glb"
const RUN_MODEL := "res://assets/models/characters/lithide/hero_lithide_paladin_running_v3.glb"
const ATTACK_MODEL := "res://assets/models/characters/lithide/hero_lithide_paladin_axe_spin_attack.glb"
const HAMMER_MODEL := "res://assets/models/characters/lithide/gilded_stonehammer.glb"
const SHIELD_MODEL := "res://assets/models/characters/lithide/aegis_of_the_golden_s.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(LITHIDE_SCRIPT), "Lithide hero controller must exist")
	_check(ResourceLoader.exists(WALK_MODEL), "Lithide walking model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "Lithide running model must import")
	_check(ResourceLoader.exists(ATTACK_MODEL), "Lithide attack model must import")
	_check(ResourceLoader.exists(HAMMER_MODEL), "Lithide hammer model must import")
	_check(ResourceLoader.exists(SHIELD_MODEL), "Lithide shield model must import")
	if failures > 0:
		quit(1)
		return

	var hero: Node3D = load(LITHIDE_SCRIPT).new()
	root.add_child(hero)
	await process_frame
	var walking := hero.get_node("Walking") as Node3D
	var running := hero.get_node("Running") as Node3D
	var attacking := hero.get_node("Attack") as Node3D
	_check(walking.scale.is_equal_approx(Vector3.ONE * 0.45),
		"walking export must use the calibrated Lithide scale")
	_check(running.scale.is_equal_approx(Vector3.ONE * 0.45),
		"running export must use the calibrated Lithide scale")
	_check(attacking.scale.is_equal_approx(Vector3.ONE * 0.45),
		"attack export must use the calibrated Lithide scale")
	_check(walking.position.is_zero_approx() and running.position.is_zero_approx(),
		"both Lithide animation exports must share the same bottom-centered origin")
	_check_hammer_attachment(walking, "walking")
	_check_hammer_attachment(running, "running")
	_check_attack_equipment(attacking)
	_check_shield_attachment(walking, "walking")
	_check_shield_attachment(running, "running")
	_check_shield_attachment(attacking, "attack")
	_check(hero.has_method("get_right_hand_pose_correction_degrees"),
		"Lithide must expose the Blender-calibrated right-hand correction")
	if hero.has_method("get_right_hand_pose_correction_degrees"):
		_check(hero.get_right_hand_pose_correction_degrees().is_equal_approx(Vector3(0.0, 25.0, 20.0)),
			"right hand must use the Blender calibration: X 0°, Y 25°, Z 20°")

	hero.set_running(false)
	_check(_playing_clip(hero).contains("walking"), "normal movement must play the Lithide walking clip")
	hero.set_running(true)
	_check(_playing_clip(hero).contains("running"), "fleeing movement must play the Lithide running clip")
	hero.set_attacking(true, true)
	_check(attacking.visible and not walking.visible and not running.visible,
		"core strike must show only the Lithide attack model")
	_check(_model_has_playing_animation(attacking), "core strike must play the Lithide attack clip")
	var attack_player := attacking.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_check(attack_player != null and attack_player.get_animation(attack_player.current_animation).length >= 1.9,
		"core strike must select the full attack clip instead of the static export clip")
	if attack_player != null:
		var attack_clip := attack_player.get_animation(attack_player.current_animation)
		_check(attack_clip != null and attack_clip.loop_mode != Animation.LOOP_NONE,
			"core strike clip must be configured to loop")
		var skeleton := attacking.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		var hand := skeleton.find_bone("RightHand")
		attack_player.seek(0.0, true)
		var start := skeleton.get_bone_global_pose(hand)
		attack_player.seek(attack_clip.length * 0.5, true)
		var spin := skeleton.get_bone_global_pose(hand)
		_check(not start.is_equal_approx(spin),
			"axe spin attack must animate the right hand that carries the hammer")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Lithide switches between walking and running animations")
	quit(1 if failures else 0)


func _check_attack_equipment(model: Node) -> void:
	_check_hammer_attachment(model, "attack")
	_check(model.find_child("AttackHammer", true, false) == null
		and model.find_child("AttackShield", true, false) == null,
		"attack export must not include integrated equipment")
	var attachments := model.find_children("HammerAttachment", "BoneAttachment3D", true, false)
	_check(attachments.size() == 1, "attack must have one editable hammer attachment")
	if attachments.size() != 1:
		return
	var attachment := attachments[0] as BoneAttachment3D
	_check(attachment.bone_name == &"RightHand", "attack hammer must follow the right hand")


func _playing_clip(hero: Node) -> String:
	var playing: Array[String] = []
	for player in hero.find_children("*", "AnimationPlayer", true, false):
		if player.is_playing():
			playing.append(String(player.current_animation).to_lower())
	_check(playing.size() == 1, "exactly one Lithide animation must be playing")
	return playing[0] if playing.size() == 1 else ""


func _model_has_playing_animation(model: Node) -> bool:
	for player in model.find_children("*", "AnimationPlayer", true, false):
		if (player as AnimationPlayer).is_playing():
			return true
	return false


func _check_hammer_attachment(model: Node, motion_name: String) -> void:
	var attachments := model.find_children("HammerAttachment", "BoneAttachment3D", true, false)
	_check(attachments.size() == 1, "%s model must have one hammer attachment" % motion_name)
	if attachments.size() != 1:
		return
	var attachment := attachments[0] as BoneAttachment3D
	_check(attachment.bone_name == &"RightHand",
		"%s hammer must be attached to the left-hand bone" % motion_name)
	_check(attachment.get_parent() is Skeleton3D,
		"%s hammer attachment must belong to the animated skeleton" % motion_name)
	_check(attachment.find_child("GildedStonehammer", true, false) != null,
		"%s right hand must contain the gilded stonehammer" % motion_name)
	var hammer := attachment.find_child("GildedStonehammer", true, false) as Node3D
	if hammer != null:
		_check(hammer.position.is_equal_approx(Vector3(26.0, 8.0, -33.0)),
			"%s hammer must keep the calibrated left-hand position" % motion_name)
		_check(hammer.rotation_degrees.is_equal_approx(Vector3(-100.0, 90.0, -34.0)),
			"%s hammer must keep the calibrated left-hand rotation" % motion_name)
		_check(hammer.scale.is_equal_approx(Vector3(110.0, 129.635, 86.416)),
			"%s hammer must keep the calibrated X scale" % motion_name)
		_check(hammer.rotation_order == EULER_ORDER_XZY,
			"%s hammer must use XZY rotation order" % motion_name)
func _check_shield_attachment(model: Node, motion_name: String) -> void:
	var attachments := model.find_children("ShieldAttachment", "BoneAttachment3D", true, false)
	_check(attachments.size() == 1, "%s model must have one shield attachment" % motion_name)
	if attachments.size() != 1:
		return
	var attachment := attachments[0] as BoneAttachment3D
	_check(attachment.bone_name == &"LeftForeArm",
		"%s shield must be attached to the right forearm bone" % motion_name)
	_check(attachment.get_parent() is Skeleton3D,
		"%s shield attachment must belong to the animated skeleton" % motion_name)
	_check(attachment.find_child("GoldenAegis", true, false) != null,
		"%s right forearm must contain the golden aegis" % motion_name)
	var shield := attachment.find_child("GoldenAegis", true, false) as Node3D
	if shield != null:
		_check(shield.position.is_equal_approx(Vector3(8.0, 13.0, 8.0)),
			"%s shield must keep the calibrated right-forearm position" % motion_name)
		_check(shield.rotation_degrees.is_equal_approx(Vector3(-5.0, -269.0, 261.0)),
			"%s shield must keep the calibrated right-forearm rotation" % motion_name)
		_check(shield.scale.is_equal_approx(Vector3.ONE * 92.0),
			"%s shield must keep the calibrated scale" % motion_name)
		_check(shield.rotation_order == EULER_ORDER_YXZ,
			"%s shield must use YXZ rotation order" % motion_name)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
