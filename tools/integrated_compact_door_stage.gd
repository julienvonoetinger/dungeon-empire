extends "res://scripts/vulpin_lockpick_stage.gd"
## Native integrated kit; open-state inspection uses its actual open resources.
const REVIEW := "res://docs/reference/door-redesign/seal-v1/hero-fit-v11-compact/"
const IDLE: SpriteFrames = preload("res://assets/previews/vulpin-idle/frames.tres")
const WALK: SpriteFrames = preload("res://assets/previews/vulpin-walk/frames.tres")
const RUN: SpriteFrames = preload("res://assets/previews/vulpin-run/frames.tres")
var revision := "after"
var opened := false
var samples: Array = []

func _load_definition(reload_textures: bool) -> bool:
	_definition = null
	if not super._load_definition(reload_textures): return false
	if opened:
		_definition = _definition.duplicate(true)
		for direction in ["south","north","east","west"]:
			for layer in ["leaf","arch"]:
				var id: String = "door-" + direction + "-" + layer
				var open_id: String = "door-" + direction + "-open-" + layer
				_definition.entries[id] = _definition.entries[open_id].duplicate(true)
				_definition.textures[id] = _definition.textures[open_id]
	samples = JSON.parse_string(FileAccess.get_file_as_string(REVIEW + "passage-validation.json")).samples
	return true
func review_pose(kind: String, frame := 0, travel := 0.0) -> void:
	if kind == "lock":
		actor.sprite_frames = _lockpick_frames()
		actor.animation = StringName(facing)
		set_pose(frame)
		return
	actor.sprite_frames = IDLE if kind == "idle" else RUN if kind == "run" else WALK
	actor.animation = StringName(facing)
	actor.set_frame_and_progress(frame, 0)
	hero_grid = local_to_grid(lock_local - _tool_offset) + _normal * .13 if kind == "idle" else lock_grid - _normal * .025 + _normal * travel
	actor.position = grid_to_local(hero_grid)
	_contact.position = actor.position
	var bounds: Dictionary
	for sample: Dictionary in samples:
		if sample.kind == kind and int(sample.pose) == frame: bounds = sample.bounds[facing]
	assert(not bounds.is_empty())
	var origin := Vector3(hero_grid.x, hero_grid.y, 0)
	var parts: Array[Dictionary] = _solids.duplicate()
	parts.append({"node": actor, "id": "vulpin", "min": origin + Vector3(bounds.min[0],bounds.min[1],bounds.min[2]),
		"max": origin + Vector3(bounds.max[0],bounds.max[1],bounds.max[2]),
		"rect": Rect2(actor.position - _anchor * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE),
		"depth": (hero_grid.x + hero_grid.y) * .6123724356957945})
	for part in _ordered_parts(parts): _world.move_child(part.node, -1)

