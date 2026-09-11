class_name VulpinHero
extends Node3D

const WALK_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_walking.glb")
const RUN_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_running.glb")
const COLLECT_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_collect_gold.glb")
const CHARACTER_SCALE := 0.4

var _walking: Node3D
var _running: Node3D
var _collecting: Node3D
var _is_running := false
var _is_collecting := false


func _ready() -> void:
	_walking = WALK_MODEL.instantiate() as Node3D
	_running = RUN_MODEL.instantiate() as Node3D
	_collecting = COLLECT_MODEL.instantiate() as Node3D
	_walking.name = "Walking"
	_running.name = "Running"
	_collecting.name = "Collect"
	add_child(_walking)
	add_child(_running)
	add_child(_collecting)
	_walking.scale = Vector3.ONE * CHARACTER_SCALE
	_running.scale = Vector3.ONE * CHARACTER_SCALE
	_collecting.scale = Vector3.ONE * CHARACTER_SCALE
	_collecting.visible = false
	set_running(false)


func set_running(value: bool) -> void:
	if _walking == null or _running == null or _collecting == null:
		return
	_is_running = value
	if _is_collecting:
		return
	_walking.visible = not value
	_running.visible = value
	_collecting.visible = false
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
