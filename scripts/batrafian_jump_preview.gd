@tool
extends "res://scripts/paladin_action_preview.gd"
## Shared one-shot controls, Batrafian-specific trajectory; no raid/save access.
const Stage := preload("res://scripts/batrafian_jump_stage.gd")
const REGISTRATION_PATH := "res://assets/previews/batrafian-jump/registration.json"
var registration: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REGISTRATION_PATH))
var stages: Array[Node2D]=[]

func _populate_stage(group: Node2D, index: int) -> void:
	var stage:=Stage.new()
	group.add_child(stage)
	stage.build(DIRECTIONS[index],animation_frames,registration)
	stages.append(stage)
	actors.append(stage.actor)

func _fit_stage(host: Control, group: Node2D) -> void:
	var stage=group.get_child(0)
	var bounds: Rect2=stage.get_content_rect()
	var display_scale:=minf(host.size.x/bounds.size.x,host.size.y/bounds.size.y)
	group.scale=Vector2.ONE*display_scale
	group.position=host.size*.5-bounds.get_center()*display_scale

func seek_action(seconds: float) -> void:
	super.seek_action(seconds)
	for stage in stages:
		stage.set_pose(action_time,actors[0].frame)
