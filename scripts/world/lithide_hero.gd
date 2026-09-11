class_name LithideHero
extends Node3D

const WALK_MODEL := preload("res://assets/models/characters/lithide/hero_lithide_paladin_walking_v3.glb")
const RUN_MODEL := preload("res://assets/models/characters/lithide/hero_lithide_paladin_running_v3.glb")
const ATTACK_MODEL := preload("res://assets/models/characters/lithide/hero_lithide_paladin_axe_spin_attack.glb")
const HAMMER_MODEL := preload("res://assets/models/characters/lithide/gilded_stonehammer.glb")
const SHIELD_MODEL := preload("res://assets/models/characters/lithide/aegis_of_the_golden_s.glb")
const CHARACTER_SCALE := 0.45
# Meshy exports the rig at centimetre scale; compensate inside the scaled hand bone.
const HAMMER_SCALE := Vector3(110.0, 129.635, 86.416)
const HAMMER_GRIP_OFFSET := Vector3(26.0, 8.0, -33.0)
const HAMMER_GRIP_ROTATION := Vector3(-100.0, 90.0, -34.0)
const SHIELD_SCALE := 92.0
const SHIELD_FOREARM_OFFSET := Vector3(8.0, 13.0, 8.0)
const SHIELD_FOREARM_ROTATION := Vector3(-5.0, -269.0, 261.0)
const RIGHT_HAND_POSE_CORRECTION_DEGREES := Vector3(0.0, 25.0, 20.0)

var _walking: Node3D
var _running: Node3D
var _attacking: Node3D
var _is_running := false
var _loop_attack := false
var _static_pose := false


func _ready() -> void:
	# Apply the hand correction after AnimationPlayer updates each frame.
	process_priority = 100
	_walking = WALK_MODEL.instantiate() as Node3D
	_running = RUN_MODEL.instantiate() as Node3D
	_attacking = ATTACK_MODEL.instantiate() as Node3D
	_walking.name = "Walking"
	_running.name = "Running"
	_attacking.name = "Attack"
	add_child(_walking)
	add_child(_running)
	add_child(_attacking)
	_walking.scale = Vector3.ONE * CHARACTER_SCALE
	_running.scale = Vector3.ONE * CHARACTER_SCALE
	_attacking.scale = Vector3.ONE * CHARACTER_SCALE
	_attach_hammer(_walking)
	_attach_hammer(_running)
	_attach_hammer(_attacking)
	_attach_shield(_walking)
	_attach_shield(_running)
	_attach_shield(_attacking)
	_attacking.visible = false
	set_running(false)
	if _static_pose:
		_apply_static_pose()


func set_static_pose() -> void:
	if _static_pose:
		return
	_static_pose = true
	if _attacking != null:
		_apply_static_pose()


func _apply_static_pose() -> void:
	_loop_attack = false
	_walking.visible = false
	_running.visible = false
	_attacking.visible = true
	for model in [_walking, _running, _attacking]:
		_stop_animations(model)
	for skeleton in _attacking.find_children("*", "Skeleton3D", true, false):
		(skeleton as Skeleton3D).reset_bone_poses()


func set_running(value: bool) -> void:
	if _static_pose:
		return
	if _walking == null or _running == null or _attacking == null:
		return
	_is_running = value
	if _attacking.visible:
		return
	_activate_model(_running if value else _walking)


func set_attacking(value: bool, loop: bool = false) -> void:
	if _static_pose:
		return
	if _walking == null or _running == null or _attacking == null:
		return
	_loop_attack = value and loop
	_activate_model(_attacking if value else (_running if _is_running else _walking))


func _process(_delta: float) -> void:
	_apply_right_hand_pose_correction()
	if not _loop_attack or _attacking == null or not _attacking.visible:
		return
	for player in _attacking.find_children("*", "AnimationPlayer", true, false):
		if (player as AnimationPlayer).is_playing():
			return
	_play_first_animation(_attacking)


func get_right_hand_pose_correction_degrees() -> Vector3:
	return RIGHT_HAND_POSE_CORRECTION_DEGREES


func _apply_right_hand_pose_correction() -> void:
	for model in [_walking, _running, _attacking]:
		if model == null or not model.visible:
			continue
		for skeleton_node in model.find_children("*", "Skeleton3D", true, false):
			var skeleton := skeleton_node as Skeleton3D
			var hand := skeleton.find_bone("RightHand")
			if hand < 0:
				continue
			skeleton.clear_bones_global_pose_override()
			var corrected_pose := skeleton.get_bone_global_pose(hand)
			var correction := Basis.from_euler(Vector3(
				deg_to_rad(RIGHT_HAND_POSE_CORRECTION_DEGREES.x),
				deg_to_rad(RIGHT_HAND_POSE_CORRECTION_DEGREES.y),
				deg_to_rad(RIGHT_HAND_POSE_CORRECTION_DEGREES.z)
			), EULER_ORDER_XYZ)
			corrected_pose.basis *= correction
			skeleton.set_bone_global_pose_override(hand, corrected_pose, 1.0, true)


func _activate_model(model: Node3D) -> void:
	_walking.visible = model == _walking
	_running.visible = model == _running
	_attacking.visible = model == _attacking
	for candidate in [_walking, _running, _attacking]:
		if candidate != model:
			_stop_animations(candidate)
	_play_first_animation(model)


func _stop_animations(model: Node) -> void:
	for player in model.find_children("*", "AnimationPlayer", true, false):
		player.stop()


func _play_first_animation(model: Node) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	var clips := player.get_animation_list()
	if clips.is_empty():
		return
	var clip: StringName = clips[0]
	for candidate in clips:
		if player.get_animation(candidate).length > player.get_animation(clip).length:
			clip = candidate
	if model == _attacking and _loop_attack:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if not player.is_playing() or player.current_animation != clip:
		player.play(clip)


func _attach_hammer(model: Node3D) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Lithide model has no Skeleton3D for the hammer")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.find_bone("RightHand") < 0:
		push_error("Lithide skeleton has no RightHand bone for the hammer")
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "HammerAttachment"
	skeleton.add_child(attachment)
	attachment.bone_name = &"RightHand"

	var hammer := HAMMER_MODEL.instantiate() as Node3D
	hammer.name = "GildedStonehammer"
	hammer.position = HAMMER_GRIP_OFFSET
	hammer.rotation_order = EULER_ORDER_XZY
	hammer.rotation_degrees = HAMMER_GRIP_ROTATION
	hammer.scale = HAMMER_SCALE
	attachment.add_child(hammer)


func _attach_shield(model: Node3D) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Lithide model has no Skeleton3D for the shield")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.find_bone("LeftForeArm") < 0:
		push_error("Lithide skeleton has no LeftForeArm bone for the shield")
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "ShieldAttachment"
	skeleton.add_child(attachment)
	attachment.bone_name = &"LeftForeArm"

	var shield := SHIELD_MODEL.instantiate() as Node3D
	shield.name = "GoldenAegis"
	shield.position = SHIELD_FOREARM_OFFSET
	shield.rotation_order = EULER_ORDER_YXZ
	shield.rotation_degrees = SHIELD_FOREARM_ROTATION
	shield.scale = Vector3.ONE * SHIELD_SCALE
	attachment.add_child(shield)
