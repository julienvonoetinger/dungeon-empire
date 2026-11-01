@tool
extends "res://scripts/paladin_attack_preview.gd"
## Four visual attack contacts; no simulator, damage transactions or save access.
const CORE_STAGE := preload("res://scripts/paladin_core_attack_stage.gd")
var rooms: Array[Node2D] = []
var vortex_time := 0.0
var _ghost_button: CheckButton

func _ready() -> void:
	repeat_enabled = true
	super._ready()
	_ghost_button = CheckButton.new()
	_ghost_button.text = "Ghost core"
	_ghost_button.custom_minimum_size = Vector2(140,48)
	_ghost_button.tooltip_text = "See the hammer contact through the Core. Preview only."
	_ghost_button.toggled.connect(set_ghost_core)
	var toolbar := _repeat_button.get_parent()
	toolbar.add_child(_ghost_button)
	toolbar.move_child(_ghost_button,_status.get_index())

func set_ghost_core(enabled: bool) -> void:
	_ghost_button.set_pressed_no_signal(enabled)
	for room in rooms:
		room.core_sprite.self_modulate.a = .28 if enabled else 1.0

func _populate_stage(group: Node2D, index: int) -> void:
	var room := CORE_STAGE.new()
	room.name = "CoreAttack_" + str(DIRECTIONS[index])
	group.add_child(room)
	room.build(DIRECTIONS[index],animation_frames,registration)
	rooms.append(room)
	actors.append(room.actor)
	_shadows.append(room.contact_shadow)

func _fit_stage(stage: Control, group: Node2D) -> void:
	var room := group.get_child(0)
	var bounds: Rect2 = room.get_content_rect()
	var display_scale := minf(stage.size.x/bounds.size.x,stage.size.y/bounds.size.y)
	group.scale = Vector2.ONE * display_scale
	group.position = stage.size*.5 - bounds.get_center()*display_scale

func seek_action(seconds: float) -> void:
	super.seek_action(seconds)
	for room in rooms:
		# Base reaction previews put the feet at zero. Here each actor faces the
		# Core from a different side, so its shadow follows that fixed root.
		room.contact_shadow.position = room.actor.position
		room.set_pose(room.actor.frame,action_time >= impact_time and action_time < impact_time+.065)

func _process(delta: float) -> void:
	if _playing:
		vortex_time += delta*playback_speed
	super._process(delta)
	for room in rooms:
		room.set_vortex_time(vortex_time)
