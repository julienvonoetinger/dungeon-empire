@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Native masonry and actor registration, isolated from gameplay.
const FRAMES: SpriteFrames = preload("res://assets/previews/vulpin-lockpick/frames.tres")
const HERO_SCALE := .85
const CONFIG := {
	"se": {"door": "west", "axis": 0, "normal": Vector2.LEFT},
	"sw": {"door": "north", "axis": 1, "normal": Vector2.UP},
	"nw": {"door": "east", "axis": 0, "normal": Vector2.RIGHT},
	"ne": {"door": "south", "axis": 1, "normal": Vector2.DOWN},
}

class ContactGuides extends Node2D:
	var lock_point := Vector2.ZERO
	var tool_point := Vector2.ZERO
	var feet_point := Vector2.ZERO
	func _draw() -> void:
		draw_line(feet_point, tool_point, Color(0.4, 1, .85, .6), 1)
		draw_circle(feet_point, 4, Color(.4, 1, .85), false, 1.5)
		draw_circle(lock_point, 6, Color(1, .7, .2), false, 1.5)
		draw_line(tool_point - Vector2(4,0), tool_point + Vector2(4,0), Color(1,.3,.8), 1.5)
		draw_line(tool_point - Vector2(0,4), tool_point + Vector2(0,4), Color(1,.3,.8), 1.5)

var actor: AnimatedSprite2D
var facing := "se"
var hero_grid := Vector2.ZERO
var lock_grid := Vector2.ZERO
var lock_local := Vector2.ZERO
var distance_offset := 0.0
var _registration: Dictionary
var _solids: Array[Dictionary] = []
var _contact: Sprite2D
var _guides: ContactGuides
var _anchor := Vector2.ZERO
var _tool_offset := Vector2.ZERO
var _normal := Vector2.ZERO

func build(direction: String) -> void:
	facing = direction
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/previews/vulpin-lockpick/registration.json"))
	_registration = data.directions[facing]
	_anchor = Vector2(_registration.anchor[0], _registration.anchor[1])
	_tool_offset = (Vector2(_registration.lock[0], _registration.lock[1]) - _anchor) * HERO_SCALE
	var config: Dictionary = CONFIG[facing]
	_normal = config.normal
	var door_cell := Vector2i(1,0) if config.axis == 0 else Vector2i(0,1)
	lock_grid = Vector2(door_cell) + Vector2(.5,.5) + _normal * .025
	var cells := {}
	for i in 3: cells[Vector2i(i,0) if config.axis == 0 else Vector2i(0,i)] = true
	_solids.clear()
	render_plan({"cells": cells, "openings": {}, "floor_variants": true}, {door_cell: "doors/" + config.door}, false)
	lock_local = grid_to_local(lock_grid, data.lockHeight)
	_contact = Sprite2D.new()
	_contact.texture = load(LIGHT_FALLOFF_PATH)
	_contact.modulate = Color(0,0,0,.5)
	_contact.scale = Vector2(38,19) / _contact.texture.get_size()
	_world.add_child(_contact)
	actor = AnimatedSprite2D.new()
	actor.name = "Vulpin"
	actor.sprite_frames = FRAMES
	actor.animation = StringName(facing)
	actor.centered = false
	actor.offset = -_anchor
	actor.scale = Vector2.ONE * HERO_SCALE
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.z_index = 1
	_world.add_child(actor)
	_guides = ContactGuides.new()
	_guides.z_index = 10
	_guides.visible = false
	_world.add_child(_guides)
	set_pose(0)
	_frame = _frame.merge(Rect2(actor.position - _anchor * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE)).grow(24)

func _draw_part(part: Dictionary, layer: int) -> void:
	super._draw_part(part, layer)
	if layer == 1:
		var solid := part.duplicate()
		solid["node"] = _world.get_child(-1)
		_solids.append(solid)

func set_pose(frame: int) -> void:
	actor.set_frame_and_progress(frame, 0)
	var base := lock_local - _tool_offset
	hero_grid = local_to_grid(base) + _normal * distance_offset
	actor.position = grid_to_local(hero_grid)
	_contact.position = actor.position
	_guides.lock_point = lock_local
	_guides.tool_point = actor.position + _tool_offset
	_guides.feet_point = actor.position
	_guides.queue_redraw()
	var bounds: Dictionary = _registration.bounds[frame]
	var origin := Vector3(hero_grid.x, hero_grid.y, 0)
	var parts: Array[Dictionary] = _solids.duplicate()
	parts.append({"node": actor, "id": "vulpin", "min": origin + Vector3(bounds.min[0],bounds.min[1],bounds.min[2]),
		"max": origin + Vector3(bounds.max[0],bounds.max[1],bounds.max[2]),
		"rect": Rect2(actor.position - _anchor * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE),
		"depth": (hero_grid.x + hero_grid.y) * .6123724356957945})
	for part in _ordered_parts(parts): _world.move_child(part.node, -1)

func set_distance(value: float) -> void:
	distance_offset = clampf(value, -.10, .15)
	set_pose(actor.frame)

func set_ghost(value: bool) -> void:
	for part in _solids:
		if str(part.id).begins_with("door-"): part.node.modulate.a = .28 if value else 1.0

func set_guides(value: bool) -> void:
	_guides.visible = value

func registration_error() -> float:
	return (actor.position + _tool_offset).distance_to(lock_local)

func solid_count() -> int:
	return _solids.size()
