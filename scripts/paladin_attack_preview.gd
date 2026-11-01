@tool
extends "res://scripts/paladin_action_preview.gd"
## Same review controls as hurt/death; no game, session, combat or saves.
const Target := preload("res://scripts/paladin_attack_target.gd")
const REGISTRATION_PATH := "res://assets/previews/paladin-attack/registration.json"
var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REGISTRATION_PATH))
var targets: Array[Node2D] = []
var impact_time := .45
var impact_count := 0
var _hit_sent := false

func _ready() -> void:
	impact_time = float(registration["impact_ms"]) / 1000.0
	super._ready()

func _populate_stage(group: Node2D, index: int) -> void:
	super._populate_stage(group, index)
	var actor := actors[index]
	var target := Target.new()
	var view: Dictionary = registration["views"][DIRECTIONS[index]]
	target.name = "StrikeTarget"
	for point in view["top"]:
		target.top.append(Vector2(point[0],point[1]))
	for point in view["bottom"]:
		target.bottom.append(Vector2(point[0],point[1]))
	target.impact_point = Vector2(view["impact"][0],view["impact"][1])
	actor.get_parent().add_child(target)
	# The target is in front in the two front views, behind in the rear views.
	if float(view["ground"][1]) < 0:
		actor.get_parent().move_child(target,actor.get_index())
	targets.append(target)

func seek_action(seconds: float) -> void:
	super.seek_action(seconds)
	for target in targets:
		target.flash = action_time >= impact_time and action_time < impact_time + .065

func trigger_action() -> void:
	_hit_sent = false
	impact_count = 0
	super.trigger_action()

func _process(delta: float) -> void:
	var before := action_time
	var advancing := _playing and active
	super._process(delta)
	# Event crossing, not frame equality: also works when a 2x tick skips a pose.
	# Manual seeking is only visual and does not issue a fake combat event.
	if advancing and not _hit_sent and before < impact_time and action_time >= impact_time:
		impact_count += 1
		_hit_sent = true
