class_name BatrafianHero
extends Node3D

const WALK_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_walking.glb")
const RUN_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_running.glb")
const DEAD_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_dead.glb")
const JUMP_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_jump_trap.glb")
const ATTACK_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_attack.glb")
const QUIVER_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_quiver.glb"
const WEAPON_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_weapon.glb"
const CHARACTER_SCALE := 0.4
const QUIVER_BACK_OFFSET := Vector3(0.0, 0.0, -0.17)
const QUIVER_BACK_ROTATION := Vector3(8.0, 0.0, 40.0)
const QUIVER_SCALE := Vector3.ONE * 0.72
const WEAPON_HAND_OFFSET := Vector3(-0.02, 0.06, 0.0)
const WEAPON_HAND_ROTATION := Vector3(0.0, -31.0, -87.0)
const WEAPON_SCALE := Vector3.ONE
const RIGHT_HAND_POSE_CORRECTION_DEGREES := Vector3(0.0, 70.0, 20.0)
const ATTACK_HEAD_TURN_DEGREES := Vector3(0.0, 35.0, 0.0)
const BACK_BONES := [&"Spine2", &"Spine1", &"Spine", &"Chest", &"UpperChest", &"Hips"]

var _walking: Node3D
var _running: Node3D
var _dead: Node3D
var _jumping: Node3D
var _attack: Node3D
var _is_running := false
var _is_dying := false
var _is_jumping := false
var _is_attacking := false
var _preview_pose := false


func _ready() -> void:
	process_priority = 100
	_walking = WALK_MODEL.instantiate() as Node3D
	_running = RUN_MODEL.instantiate() as Node3D
	_dead = DEAD_MODEL.instantiate() as Node3D
	_jumping = JUMP_MODEL.instantiate() as Node3D
	preload("res://scripts/world/jump_motion.gd").prepare(_jumping)
	_attack = ATTACK_MODEL.instantiate() as Node3D
	_walking.name = "Walking"
	_running.name = "Running"
	_dead.name = "Dead"
	_jumping.name = "JumpTrap"
	_attack.name = "Attack"
	add_child(_walking)
	add_child(_running)
	add_child(_dead)
	add_child(_jumping)
	add_child(_attack)
	_walking.scale = Vector3.ONE * CHARACTER_SCALE
	_running.scale = Vector3.ONE * CHARACTER_SCALE
	_dead.scale = Vector3.ONE * CHARACTER_SCALE
	_jumping.scale = Vector3.ONE * CHARACTER_SCALE
	_attack.scale = Vector3.ONE * CHARACTER_SCALE
	var quiver_packed := load(QUIVER_MODEL) as PackedScene
	if quiver_packed != null:
		for model in [_walking, _running, _dead, _jumping, _attack]:
			_attach_quiver(model, quiver_packed)
	var weapon_packed := load(WEAPON_MODEL) as PackedScene
	if weapon_packed != null:
		for model in [_walking, _running, _dead, _jumping, _attack]:
			_attach_weapon(model, weapon_packed)
	set_running(false)
	if _preview_pose:
		_apply_preview_pose()


func set_preview_pose() -> void:
	_preview_pose = true
	if _walking != null:
		_apply_preview_pose()


func get_right_hand_pose_correction_degrees() -> Vector3:
	return RIGHT_HAND_POSE_CORRECTION_DEGREES


func get_attack_head_turn_degrees() -> Vector3:
	return ATTACK_HEAD_TURN_DEGREES


func set_running(value: bool) -> void:
	if _preview_pose:
		return
	if not has_imported_model():
		return
	_is_running = value
	if _is_dying or _is_jumping or _is_attacking:
		return
	_activate_model(_running if value else _walking)


func set_dying(value: bool) -> void:
	if _preview_pose:
		return
	if not has_imported_model():
		return
	if _is_dying == value:
		return
	_is_dying = value
	if value:
		_activate_model(_dead)
		return
	_refresh_pose()


func set_jumping(value: bool) -> void:
	if _preview_pose:
		return
	if not has_imported_model():
		return
	_is_jumping = value
	if _is_dying or _is_attacking:
		return
	_refresh_pose()


func set_attacking(value: bool) -> void:
	if _preview_pose:
		return
	if not has_imported_model():
		return
	_is_attacking = value
	if _is_dying:
		return
	_refresh_pose()


func has_imported_model() -> bool:
	return _walking != null and _running != null and _dead != null and _jumping != null and _attack != null


func _refresh_pose() -> void:
	if _is_dying:
		_activate_model(_dead)
	elif _is_attacking:
		_activate_model(_attack)
	elif _is_jumping:
		_activate_model(_jumping)
	else:
		_activate_model(_running if _is_running else _walking)


func _apply_preview_pose() -> void:
	_walking.visible = false
	_running.visible = false
	_dead.visible = false
	_jumping.visible = false
	_attack.visible = true
	for model in [_walking, _running, _dead, _jumping, _attack]:
		if model != _attack:
			_stop_animations(model)
	_play_first_animation(_attack, true)


func _activate_model(model: Node3D) -> void:
	_walking.visible = model == _walking
	_running.visible = model == _running
	_dead.visible = model == _dead
	_jumping.visible = model == _jumping
	_attack.visible = model == _attack
	for candidate in [_walking, _running, _dead, _jumping, _attack]:
		if candidate != model:
			_stop_animations(candidate)
	_play_first_animation(model)


func _stop_animations(model: Node) -> void:
	for player in model.find_children("*", "AnimationPlayer", true, false):
		player.stop()


func _play_first_animation(model: Node, loop: bool = false) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	var clips := player.get_animation_list()
	if clips.is_empty():
		return
	var clip: StringName = clips[0]
	if loop:
		var anim := player.get_animation(clip)
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR
	if not player.is_playing() or player.current_animation != clip:
		player.play(clip)


func _process(_delta: float) -> void:
	_apply_bone_pose_corrections()


func _apply_bone_pose_corrections() -> void:
	for model in [_walking, _running, _dead, _jumping, _attack]:
		if model == null or not model.visible:
			continue
		for skeleton_node in model.find_children("*", "Skeleton3D", true, false):
			var skeleton := skeleton_node as Skeleton3D
			skeleton.clear_bones_global_pose_override()
			_apply_bone_rotation(skeleton, "RightHand", RIGHT_HAND_POSE_CORRECTION_DEGREES)
			if model == _attack:
				_apply_bone_rotation(skeleton, "Head", ATTACK_HEAD_TURN_DEGREES)


func _apply_bone_rotation(skeleton: Skeleton3D, bone_name: String, rotation_degrees: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	if bone < 0:
		return
	var corrected_pose := skeleton.get_bone_global_pose(bone)
	var correction := Basis.from_euler(Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	), EULER_ORDER_XYZ)
	corrected_pose.basis *= correction
	skeleton.set_bone_global_pose_override(bone, corrected_pose, 1.0, true)


func _pose_model(model: Node, normalized_time: float) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	var clips := player.get_animation_list()
	if clips.is_empty():
		return
	var clip: StringName = clips[0]
	var anim := player.get_animation(clip)
	player.play(clip)
	player.seek(anim.length * clampf(normalized_time, 0.0, 1.0), true)
	player.stop(false)


func _attach_quiver(model: Node3D, quiver_packed: PackedScene) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Batrafian Ranger model has no Skeleton3D for the quiver")
		return
	var skeleton := skeletons[0] as Skeleton3D
	var bone_name := _first_existing_bone(skeleton, BACK_BONES)
	if bone_name == &"":
		push_error("Batrafian Ranger skeleton has no back bone for the quiver")
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "QuiverAttachment"
	skeleton.add_child(attachment)
	attachment.bone_name = bone_name

	var quiver := quiver_packed.instantiate() as Node3D
	if quiver == null:
		push_error("Batrafian Ranger quiver model cannot be instantiated")
		return
	quiver.name = "BatrafianRangerQuiver"
	quiver.position = QUIVER_BACK_OFFSET
	quiver.rotation_order = EULER_ORDER_YXZ
	quiver.rotation_degrees = QUIVER_BACK_ROTATION
	quiver.scale = QUIVER_SCALE
	attachment.add_child(quiver)


func _attach_weapon(model: Node3D, weapon_packed: PackedScene) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Batrafian Ranger model has no Skeleton3D for the weapon")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.find_bone("LeftHand") < 0:
		push_error("Batrafian Ranger skeleton has no LeftHand bone for the weapon")
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "WeaponAttachment"
	skeleton.add_child(attachment)
	attachment.bone_name = &"LeftHand"

	var weapon := weapon_packed.instantiate() as Node3D
	if weapon == null:
		push_error("Batrafian Ranger weapon model cannot be instantiated")
		return
	weapon.name = "BatrafianRangerWeapon"
	weapon.position = WEAPON_HAND_OFFSET
	weapon.rotation_order = EULER_ORDER_YXZ
	weapon.rotation_degrees = WEAPON_HAND_ROTATION
	weapon.scale = WEAPON_SCALE
	attachment.add_child(weapon)


func _first_existing_bone(skeleton: Skeleton3D, candidates: Array) -> StringName:
	for candidate in candidates:
		var bone := candidate as StringName
		if skeleton.find_bone(String(bone)) >= 0:
			return bone
	return &""
