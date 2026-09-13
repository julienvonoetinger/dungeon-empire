class_name VulpinHero
extends Node3D

const WALK_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_walking.glb")
const RUN_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_running.glb")
const COLLECT_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_collect_gold.glb")
const JUMP_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_jump_trap.glb")
const LOCKPICK_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_lockpicking.glb")
const DYING_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_dying.glb")
const CHARACTER_SCALE := 0.4

var _walking: Node3D
var _running: Node3D
var _collecting: Node3D
var _jumping: Node3D
var _lockpicking: Node3D
var _dying: Node3D
var _is_running := false
var _is_collecting := false
var _is_jumping := false
var _is_lockpicking := false
var _is_dying := false


func _ready() -> void:
	_walking = WALK_MODEL.instantiate() as Node3D
	_running = RUN_MODEL.instantiate() as Node3D
	_collecting = COLLECT_MODEL.instantiate() as Node3D
	_jumping = JUMP_MODEL.instantiate() as Node3D
	_lockpicking = LOCKPICK_MODEL.instantiate() as Node3D
	_dying = DYING_MODEL.instantiate() as Node3D
	_walking.name = "Walking"
	_running.name = "Running"
	_collecting.name = "Collect"
	_jumping.name = "JumpTrap"
	_lockpicking.name = "Lockpicking"
	_dying.name = "Dying"
	add_child(_walking)
	add_child(_running)
	add_child(_collecting)
	add_child(_jumping)
	add_child(_lockpicking)
	add_child(_dying)
	_walking.scale = Vector3.ONE * CHARACTER_SCALE
	_running.scale = Vector3.ONE * CHARACTER_SCALE
	_collecting.scale = Vector3.ONE * CHARACTER_SCALE
	_jumping.scale = Vector3.ONE * CHARACTER_SCALE
	_lockpicking.scale = Vector3.ONE * CHARACTER_SCALE
	_dying.scale = Vector3.ONE * CHARACTER_SCALE
	_collecting.visible = false
	_jumping.visible = false
	_lockpicking.visible = false
	_dying.visible = false
	set_running(false)


func set_running(value: bool) -> void:
	if _walking == null or _running == null or _collecting == null or _jumping == null or _lockpicking == null or _dying == null:
		return
	_is_running = value
	if _is_collecting or _is_jumping or _is_lockpicking or _is_dying:
		return
	_walking.visible = not value
	_running.visible = value
	_collecting.visible = false
	_jumping.visible = false
	_lockpicking.visible = false
	_dying.visible = false
	_stop_animations(_walking if value else _running)
	_play_first_animation(_running if value else _walking)


func set_collecting(value: bool) -> void:
	if _walking == null or _running == null or _collecting == null:
		return
	if _is_collecting == value:
		return
	_is_collecting = value
	if value:
		_walking.visible = false
		_running.visible = false
		_collecting.visible = true
		_stop_animations(_walking)
		_stop_animations(_running)
		_play_first_animation(_collecting)
		return
	_collecting.visible = false
	_stop_animations(_collecting)
	set_running(_is_running)


func set_jumping(value: bool) -> void:
	if _walking == null or _running == null or _collecting == null or _jumping == null or _lockpicking == null or _dying == null:
		return
	if _is_jumping == value:
		return
	_is_jumping = value
	if value:
		_walking.visible = false
		_running.visible = false
		_collecting.visible = false
		_jumping.visible = true
		_lockpicking.visible = false
		_dying.visible = false
		_stop_animations(_walking)
		_stop_animations(_running)
		_stop_animations(_collecting)
		_play_first_animation(_jumping)
		return
	_jumping.visible = false
	_stop_animations(_jumping)
	set_running(_is_running)


func set_lockpicking(value: bool) -> void:
	if _walking == null or _running == null or _collecting == null or _jumping == null or _lockpicking == null or _dying == null:
		return
	if _is_lockpicking == value:
		return
	_is_lockpicking = value
	if value:
		_walking.visible = false
		_running.visible = false
		_collecting.visible = false
		_jumping.visible = false
		_lockpicking.visible = true
		_dying.visible = false
		_stop_animations(_walking)
		_stop_animations(_running)
		_stop_animations(_collecting)
		_stop_animations(_jumping)
		_play_first_animation(_lockpicking)
		return
	_lockpicking.visible = false
	_stop_animations(_lockpicking)
	set_running(_is_running)


func set_dying(value: bool) -> void:
	if _walking == null or _running == null or _collecting == null or _jumping == null or _lockpicking == null or _dying == null:
		return
	if _is_dying == value:
		return
	_is_dying = value
	if value:
		_walking.visible = false
		_running.visible = false
		_collecting.visible = false
		_jumping.visible = false
		_lockpicking.visible = false
		_dying.visible = true
		_stop_animations(_walking)
		_stop_animations(_running)
		_stop_animations(_collecting)
		_stop_animations(_jumping)
		_stop_animations(_lockpicking)
		_play_first_animation(_dying)
		return
	_dying.visible = false
	_stop_animations(_dying)
	set_running(_is_running)


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
