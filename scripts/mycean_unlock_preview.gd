@tool
extends "res://scripts/paladin_action_preview.gd"
## Shared pause/speed/seek clock for casting, beam and door release.
const DOOR_STAGE := preload("res://scripts/mycean_unlock_stage.gd")
const REGISTRATION_PATH := "res://assets/previews/mycean-unlock/registration.json"
var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REGISTRATION_PATH))
var rooms: Array[Node2D] = []
var channel_time := .45
var unlock_time := 1.5
var cast_count := 0
var unlock_count := 0
var _cast_sent := false
var _unlock_sent := false

func _ready() -> void:
	channel_time = float(registration.channel_ms)/1000.0
	unlock_time = float(registration.unlock_ms)/1000.0
	repeat_enabled = true
	super._ready()

func _populate_stage(group: Node2D, index: int) -> void:
	var room := DOOR_STAGE.new()
	room.name = "ArcaneDoor_"+str(DIRECTIONS[index])
	group.add_child(room)
	room.build(DIRECTIONS[index],animation_frames,registration)
	rooms.append(room)
	actors.append(room.actor)
	_shadows.append(room.contact_shadow)

func _fit_stage(stage: Control, group: Node2D) -> void:
	var bounds: Rect2 = group.get_child(0).get_content_rect()
	var factor := minf(stage.size.x/bounds.size.x,stage.size.y/bounds.size.y)
	group.scale = Vector2.ONE*factor
	group.position = stage.size*.5-bounds.get_center()*factor

func seek_action(seconds: float) -> void:
	super.seek_action(seconds)
	for room in rooms:
		room.contact_shadow.position = room.actor.position
		room.set_pose(room.actor.frame,action_time)

func trigger_action() -> void:
	cast_count = 0
	unlock_count = 0
	_cast_sent = false
	_unlock_sent = false
	super.trigger_action()

func _process(delta: float) -> void:
	var before := action_time
	var advancing := _playing and active
	super._process(delta)
	if advancing:
		if not _cast_sent and before<channel_time and action_time+.000001>=channel_time:
			cast_count += 1
			_cast_sent = true
		if not _unlock_sent and before<unlock_time and action_time+.000001>=unlock_time:
			unlock_count += 1
			_unlock_sent = true
