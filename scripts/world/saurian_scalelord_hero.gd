class_name SaurianScalelordHero
extends Node3D

const WALK_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_walking.glb"
const RUN_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_running.glb"
const DEAD_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_dead.glb"
const ATTACK_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_attack.glb"
const WEAPON_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_weapon.glb"
const CHARACTER_SCALE := 0.4
const LEFT_WEAPON_OFFSET := Vector3(0.28, 0.075, 0.195)
const RIGHT_WEAPON_OFFSET := Vector3(-0.3, 0.085, 0.165)
const LEFT_WEAPON_ROTATION := Vector3(-2.0, -45.0, -285.0)
const RIGHT_WEAPON_ROTATION := Vector3(-11.0, 215.0, 73.9)
const WEAPON_SCALE := Vector3.ONE

var _is_running := false
var _is_dying := false
var _is_attacking := false
var _preview_pose := false
var _walking: Node3D
var _running: Node3D
var _dead: Node3D
var _attack: Node3D


func _ready() -> void:
	_load_model()
	set_running(_is_running)
	if _preview_pose:
		_apply_preview_pose()


func set_preview_pose() -> void:
	_preview_pose = true
	if _walking != null:
		_apply_preview_pose()


func set_running(value: bool) -> void:
	if _preview_pose:
		return
	_is_running = value
	if not has_imported_model() or _is_dying or _is_attacking:
		return
	_activate_model(_running if value else _walking)


func set_attacking(value: bool) -> void:
	if _preview_pose:
		return
	if not has_imported_model():
		return
	_is_attacking = value
	if _is_dying:
		return
	_activate_model(_attack if value else (_running if _is_running else _walking))


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
	_activate_model(_attack if _is_attacking else (_running if _is_running else _walking))


func has_imported_model() -> bool:
	return _walking != null and _running != null and _dead != null and _attack != null


func _load_model() -> bool:
	var walk_packed := load(WALK_MODEL) as PackedScene
	var run_packed := load(RUN_MODEL) as PackedScene
	var dead_packed := load(DEAD_MODEL) as PackedScene
	var attack_packed := load(ATTACK_MODEL) as PackedScene
	if walk_packed == null or run_packed == null or dead_packed == null or attack_packed == null:
		return false
	_walking = walk_packed.instantiate() as Node3D
	_running = run_packed.instantiate() as Node3D
	_dead = dead_packed.instantiate() as Node3D
	_attack = attack_packed.instantiate() as Node3D
	if not has_imported_model():
		return false
	_walking.name = "Walking"
	_running.name = "Running"
	_dead.name = "Dead"
	_attack.name = "Attack"
	var weapon_packed := load(WEAPON_MODEL) as PackedScene
	for model in [_walking, _running, _dead, _attack]:
		if weapon_packed != null:
			_attach_weapon(model, weapon_packed, &"LeftHand", "LeftWeaponAttachment", "SaurianScalelordLeftWeapon", LEFT_WEAPON_OFFSET, LEFT_WEAPON_ROTATION)
			_attach_weapon(model, weapon_packed, &"RightHand", "RightWeaponAttachment", "SaurianScalelordRightWeapon", RIGHT_WEAPON_OFFSET, RIGHT_WEAPON_ROTATION)
		model.scale = Vector3.ONE * CHARACTER_SCALE
		add_child(model)
	_running.visible = false
	_dead.visible = false
	_attack.visible = false
	_activate_model(_walking)
	return true


func _apply_preview_pose() -> void:
	if not has_imported_model():
		return
	_walking.visible = false
	_running.visible = false
	_dead.visible = false
	_attack.visible = true
	for model in [_walking, _running, _dead, _attack]:
		if model != _attack:
			_stop_animations(model)
	_play_first_animation(_attack, true)


func _activate_model(model: Node3D) -> void:
	_walking.visible = model == _walking
	_running.visible = model == _running
	_dead.visible = model == _dead
	_attack.visible = model == _attack
	for candidate in [_walking, _running, _dead, _attack]:
		if candidate != model:
			_stop_animations(candidate)
	_play_first_animation(model)


func _stop_animations(model: Node) -> void:
	for player in model.find_children("*", "AnimationPlayer", true, false):
		(player as AnimationPlayer).stop()


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
		var animation := player.get_animation(clip)
		if animation != null:
			animation.loop_mode = Animation.LOOP_LINEAR
	if not player.is_playing() or player.current_animation != clip:
		player.play(clip)


func _attach_weapon(
		model: Node3D,
		weapon_packed: PackedScene,
		bone_name: StringName,
		attachment_name: String,
		payload_name: String,
		offset: Vector3,
		rotation: Vector3) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Saurian Scalelord model has no Skeleton3D for weapon attachment.")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.find_bone(String(bone_name)) < 0:
		push_error("Saurian Scalelord skeleton is missing weapon bone: %s" % bone_name)
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = attachment_name
	skeleton.add_child(attachment)
	attachment.bone_name = bone_name
	var weapon := weapon_packed.instantiate() as Node3D
	if weapon == null:
		push_error("Saurian Scalelord weapon scene root must be Node3D.")
		return
	weapon.name = payload_name
	weapon.position = offset
	weapon.rotation_order = EULER_ORDER_YXZ
	weapon.rotation_degrees = rotation
	weapon.scale = WEAPON_SCALE
	attachment.add_child(weapon)
