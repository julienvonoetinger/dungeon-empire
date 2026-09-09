class_name VulpinHero
extends Node3D

const WALK_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_walking.glb")
const RUN_MODEL := preload("res://assets/models/characters/vulpin/hero_vulpin_running.glb")
const CHARACTER_SCALE := 0.4

var _walking: Node3D
var _running: Node3D


func _ready() -> void:
	_walking = WALK_MODEL.instantiate() as Node3D
	_running = RUN_MODEL.instantiate() as Node3D
	_walking.name = "Walking"
	_running.name = "Running"
	add_child(_walking)
	add_child(_running)
	_walking.scale = Vector3.ONE * CHARACTER_SCALE
	_running.scale = Vector3.ONE * CHARACTER_SCALE
	set_running(false)


func set_running(value: bool) -> void:
	if _walking == null or _running == null:
		return
	_walking.visible = not value
	_running.visible = value
	_stop_animations(_walking if value else _running)
	_play_first_animation(_running if value else _walking)


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
