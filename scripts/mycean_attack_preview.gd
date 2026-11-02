@tool
extends "res://scripts/paladin_action_preview.gd"
## One clock for poses, visible spore flight and preview-only event counters.
const CORE_STAGE := preload("res://scripts/mycean_attack_stage.gd")
const REGISTRATION_PATH := "res://assets/previews/mycean-attack/registration.json"
var registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REGISTRATION_PATH))
var rooms: Array[Node2D] = []
var release_time := .65
var impact_time := .97
var shot_count := 0
var impact_count := 0
var _release_sent := false
var _impact_sent := false
var vortex_time := 0.0

func _ready() -> void:
	release_time = float(registration.release_ms)/1000.0
	impact_time = release_time+float(registration.flight_ms)/1000.0
	repeat_enabled = true
	super._ready()

func _populate_stage(group: Node2D, index: int) -> void:
	var room := CORE_STAGE.new()
	room.name = "RangedAttack_"+str(DIRECTIONS[index])
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
	shot_count = 0
	impact_count = 0
	_release_sent = false
	_impact_sent = false
	super.trigger_action()

func _process(delta: float) -> void:
	var before := action_time
	var advancing := _playing and active
	if _playing: vortex_time += delta*playback_speed
	super._process(delta)
	# Cross boundaries rather than checking one sprite frame: a large 2x tick
	# still produces exactly one release followed by one arrival. Seeking is inert.
	if advancing:
		if not _release_sent and before < release_time and action_time+.000001 >= release_time:
			shot_count += 1
			_release_sent = true
		if not _impact_sent and before < impact_time and action_time+.000001 >= impact_time:
			impact_count += 1
			_impact_sent = true
	for room in rooms: room.set_vortex_time(vortex_time)
