class_name BatrafianHero
extends Node3D

const WALK_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_walking.glb")
const RUN_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_running.glb")
const DEAD_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_dead.glb")
const JUMP_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_jump_trap.glb")
const ATTACK_MODEL := preload("res://assets/models/characters/batrafian/hero_batrafian_ranger_attack.glb")
const QUIVER_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_quiver.glb"
const CHARACTER_SCALE := 0.4
const QUIVER_BACK_OFFSET := Vector3(0.0, 0.12, -0.22)
const QUIVER_BACK_ROTATION := Vector3(-12.0, 0.0, 18.0)
const QUIVER_SCALE := Vector3.ONE * 0.72
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


func _ready() -> void:
	_walking = WALK_MODEL.instantiate() as Node3D
	_running = RUN_MODEL.instantiate() as Node3D
	_dead = DEAD_MODEL.instantiate() as Node3D
	_jumping = JUMP_MODEL.instantiate() as Node3D
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
	set_running(false)


func set_running(value: bool) -> void:
	if not has_imported_model():
		return
	_is_running = value
	if _is_dying or _is_jumping or _is_attacking:
		return
	_activate_model(_running if value else _walking)


func set_dying(value: bool) -> void:
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
	if not has_imported_model():
		return
	_is_jumping = value
	if _is_dying or _is_attacking:
		return
	_refresh_pose()


func set_attacking(value: bool) -> void:
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


func _play_first_animation(model: Node) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	var clips := player.get_animation_list()
	if clips.is_empty():
		return
	var clip: StringName = clips[0]
	if not player.is_playing() or player.current_animation != clip:
		player.play(clip)


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
	quiver.rotation_degrees = QUIVER_BACK_ROTATION
	quiver.scale = QUIVER_SCALE
	attachment.add_child(quiver)


func _first_existing_bone(skeleton: Skeleton3D, candidates: Array) -> StringName:
	for candidate in candidates:
		var bone := candidate as StringName
		if skeleton.find_bone(String(bone)) >= 0:
			return bone
	return &""
