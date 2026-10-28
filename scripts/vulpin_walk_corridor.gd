@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Isolated path preview using the kit's normal projection and solid ordering.
const FRAMES: SpriteFrames = preload("res://assets/previews/vulpin-walk/frames.tres")
const ANCHOR := Vector2(128.0, 195.92598)
const HERO_SCALE := 0.85
# A planted foot traverses .26 model units in four 10 fps poses. Convert the
# .65 model units/s through the original 256px / 2.35 orthographic camera.
const CELLS_PER_SECOND := 0.65 * (256.0 / 2.35) * 0.70710678 / 128.0 * HERO_SCALE

var actor: AnimatedSprite2D
var axis := 0
var path_start := Vector2(.55, .5)
var path_end := Vector2(2.45, .5)
var hero_grid := Vector2.ZERO
var outbound := true
var _solids: Array[Dictionary] = []
var _contact: Sprite2D
var pose_fps := 10.0
var cells_per_second := CELLS_PER_SECOND

func build(corridor_axis: int, frames: SpriteFrames = FRAMES, frame_rate: float = 10.0, model_speed: float = .65) -> void:
	axis = corridor_axis
	pose_fps = frame_rate
	cells_per_second = model_speed * (256.0 / 2.35) * .70710678 / 128.0 * HERO_SCALE
	if axis == 1:
		path_start = Vector2(.5, .55)
		path_end = Vector2(.5, 2.45)
	var cells := {}
	for i in 3:
		cells[Vector2i(i, 0) if axis == 0 else Vector2i(0, i)] = true
	_solids.clear()
	render_plan({"cells": cells, "openings": {}, "floor_variants": true}, {}, false)
	_contact = Sprite2D.new()
	_contact.name = "FootContact"
	_contact.texture = load(LIGHT_FALLOFF_PATH)
	_contact.modulate = Color(0, 0, 0, .5)
	_contact.scale = Vector2(38, 19) / _contact.texture.get_size()
	_world.add_child(_contact)
	actor = AnimatedSprite2D.new()
	actor.name = "Vulpin"
	actor.sprite_frames = frames
	actor.centered = false
	actor.offset = -ANCHOR
	actor.scale = Vector2.ONE * HERO_SCALE
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.z_index = 1
	_world.add_child(actor)
	# One clock drives root travel and frames, including pause/speed/stepping.
	set_walk_time(0.0)
	for endpoint in [path_start, path_end]:
		_frame = _frame.merge(Rect2(grid_to_local(endpoint) - ANCHOR * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE))
	_frame = _frame.grow(10)

func _draw_part(part: Dictionary, layer: int) -> void:
	super._draw_part(part, layer)
	if layer == 1:
		var solid := part.duplicate()
		solid["node"] = _world.get_child(-1)
		_solids.append(solid)

func leg_duration() -> float:
	return path_start.distance_to(path_end) / cells_per_second

func set_walk_time(seconds: float) -> void:
	var duration := leg_duration()
	var phase := fposmod(seconds, duration * 2.0)
	outbound = phase < duration
	var progress := phase / duration if outbound else 2.0 - phase / duration
	hero_grid = path_start.lerp(path_end, progress)
	actor.position = grid_to_local(hero_grid)
	_contact.position = actor.position
	actor.animation = (&"se" if outbound else &"nw") if axis == 0 else (&"sw" if outbound else &"ne")
	actor.set_frame_and_progress(floori(seconds * pose_fps + .000001) % actor.sprite_frames.get_frame_count(actor.animation), 0.0)
	var parts: Array[Dictionary] = _solids.duplicate()
	parts.append({"node": actor,
		"min": Vector3(hero_grid.x - .16, hero_grid.y - .16, 0),
		"max": Vector3(hero_grid.x + .16, hero_grid.y + .16, 1.15),
		"rect": Rect2(actor.position - ANCHOR * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE),
		"depth": (hero_grid.x + hero_grid.y) * .6123724356957945})
	for part in _ordered_parts(parts):
		_world.move_child(part.node, -1)
