class_name NocturnePriestHero
extends Node3D

const WALK_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_walking.glb"
const RUN_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_running.glb"
const DEAD_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_dead.glb"
const CAST_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_cast.glb"
const WINGS_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_wings.glb"
const CHARACTER_SCALE := 0.4
const WINGS_BACK_BONES := [&"Chest", &"Spine2", &"Spine", &"Hips"]
const WINGS_BACK_OFFSET := Vector3(0.0, -0.225, -0.155)
const WINGS_BACK_ROTATION := Vector3.ZERO
const WINGS_SCALE := Vector3.ONE

var _is_running := false
var _is_channeling := false
var _is_dying := false
var _preview_pose := false
var _walking: Node3D
var _running: Node3D
var _dead: Node3D
var _casting: Node3D


func _ready() -> void:
	_load_model()
	set_running(_is_running)
	set_channeling(_is_channeling)
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
	if not has_imported_model() or _is_dying or _is_channeling:
		return
	_activate_model(_running if value else _walking)


func set_channeling(value: bool) -> void:
	if _preview_pose:
		return
	_is_channeling = value
	if not has_imported_model() or _is_dying:
		return
	if value:
		_activate_model(_casting)
		return
	_activate_model(_running if _is_running else _walking)


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
	_activate_model(_running if _is_running else _walking)


func has_imported_model() -> bool:
	return _walking != null and _running != null and _dead != null and _casting != null


func _load_model() -> bool:
	var walk_packed := load(WALK_MODEL) as PackedScene
	var run_packed := load(RUN_MODEL) as PackedScene
	var dead_packed := load(DEAD_MODEL) as PackedScene
	var cast_packed := load(CAST_MODEL) as PackedScene
	if walk_packed == null or run_packed == null or dead_packed == null or cast_packed == null:
		return false
	_walking = walk_packed.instantiate() as Node3D
	_running = run_packed.instantiate() as Node3D
	_dead = dead_packed.instantiate() as Node3D
	_casting = cast_packed.instantiate() as Node3D
	if not has_imported_model():
		return false
	_walking.name = "Walking"
	_running.name = "Running"
	_dead.name = "Dead"
	_casting.name = "Casting"
	var wings_packed := load(WINGS_MODEL) as PackedScene
	for model in [_walking, _running, _dead, _casting]:
		if wings_packed != null:
			_attach_wings(model, wings_packed)
		model.scale = Vector3.ONE * CHARACTER_SCALE
		add_child(model)
	_running.visible = false
	_dead.visible = false
	_casting.visible = false
	_activate_model(_walking)
	return true


func _apply_preview_pose() -> void:
	if not has_imported_model():
		return
	_walking.visible = false
	_running.visible = false
	_dead.visible = false
	_casting.visible = true
	for model in [_walking, _running, _dead, _casting]:
		if model != _casting:
			_stop_animations(model)
	_play_first_animation(_casting, true)


func _activate_model(model: Node3D) -> void:
	_walking.visible = model == _walking
	_running.visible = model == _running
	_dead.visible = model == _dead
	_casting.visible = model == _casting
	for candidate in [_walking, _running, _dead, _casting]:
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


func _attach_wings(model: Node3D, wings_packed: PackedScene) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Nocturne Priest model has no Skeleton3D for wings attachment.")
		return
	var skeleton := skeletons[0] as Skeleton3D
	var bone_name := _first_existing_bone(skeleton, WINGS_BACK_BONES)
	if bone_name == &"":
		push_error("Nocturne Priest skeleton is missing a back bone for wings attachment.")
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "WingsBackAttachment"
	skeleton.add_child(attachment)
	attachment.bone_name = bone_name
	var wings := wings_packed.instantiate() as Node3D
	if wings == null:
		push_error("Nocturne Priest wings scene root must be Node3D.")
		return
	wings.name = "NocturnePriestWings"
	wings.position = WINGS_BACK_OFFSET
	wings.rotation_order = EULER_ORDER_YXZ
	wings.rotation_degrees = WINGS_BACK_ROTATION
	wings.scale = WINGS_SCALE
	attachment.add_child(wings)


func _first_existing_bone(skeleton: Skeleton3D, bone_names: Array) -> StringName:
	for bone_name in bone_names:
		if skeleton.find_bone(String(bone_name)) >= 0:
			return bone_name
	return &""
