@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Actual painted core, light/shadow and floor; isolated attack-contact review.
const NORMALS := {&"se": Vector2.LEFT, &"sw": Vector2.UP, &"nw": Vector2.RIGHT, &"ne": Vector2.DOWN}
# Corner-cap geometry from the core's approved migration-v1 source.
const CAP_CENTER := .295
const CAP_HEIGHT := .255
var actor: AnimatedSprite2D
var contact_shadow: Sprite2D
var core_sprite: Sprite2D
var facing: StringName
var hero_grid := Vector2.ZERO
var strike_point := Vector2.ZERO
var hammer_offset := Vector2.ZERO
var _solids: Array[Dictionary] = []

func build(direction: StringName, frames: SpriteFrames, registration: Dictionary) -> void:
	facing = direction
	var cells := {}
	var openings := {}
	for y in range(-1,1):
		for x in range(-1,1):
			cells[Vector2i(x,y)] = true
			openings[Vector2i(x,y)] = 15
	render_plan({"cells":cells,"openings":openings,"hearts":PackedVector2Array([Vector2.ZERO]),"floor_variants":true},{},false)
	var normal: Vector2 = NORMALS[facing]
	var tangent := Vector2(-normal.y,normal.x)
	var cap := (normal + tangent) * CAP_CENTER
	strike_point = grid_to_local(cap,CAP_HEIGHT)
	var view: Dictionary = registration.views[facing]
	hammer_offset = Vector2(view.impact[0],view.impact[1])
	# Calibrate the 2D contact against the real stone cap. Both art scales stay
	# unchanged, and the actor's ground root is fixed throughout the entire blow.
	var root_position := strike_point - hammer_offset
	hero_grid = local_to_grid(root_position)
	contact_shadow = Sprite2D.new()
	contact_shadow.name = "FootContact"
	contact_shadow.texture = load(LIGHT_FALLOFF_PATH)
	contact_shadow.modulate = Color(0,0,0,.5)
	contact_shadow.scale = Vector2(38,19) / contact_shadow.texture.get_size()
	contact_shadow.position = root_position
	_world.add_child(contact_shadow)
	actor = AnimatedSprite2D.new()
	actor.name = "Paladin"
	actor.sprite_frames = frames
	actor.animation = facing
	actor.centered = false
	actor.offset = -Vector2(registration.anchor[0],registration.anchor[1])
	actor.scale = Vector2.ONE * float(registration.hero_scale)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.z_index = 1
	actor.position = root_position
	_world.add_child(actor)
	var all_parts: Array[Dictionary] = _solids.duplicate()
	all_parts.append({"node":actor,"id":"paladin","min":Vector3(hero_grid.x-.16,hero_grid.y-.16,0),
		"max":Vector3(hero_grid.x+.16,hero_grid.y+.16,.95),
		"rect":Rect2(actor.position+actor.offset*actor.scale,Vector2.ONE*320*actor.scale),
		"depth":(hero_grid.x+hero_grid.y)*.6123724356957945})
	for part in _ordered_parts(all_parts): _world.move_child(part.node,-1)
	# All ten poses fit the same stage, without a camera jump at impact.
	for frame in frames.get_frame_count(facing):
		var used: Rect2 = frames.get_frame_texture(facing,frame).get_image().get_used_rect()
		_frame = _frame.merge(Rect2(actor.position+(actor.offset+used.position)*actor.scale,used.size*actor.scale))
	_frame = _frame.grow(12)
	set_pose(0,false)

func _draw_part(part: Dictionary, layer: int) -> void:
	super._draw_part(part,layer)
	if layer == 1:
		var solid := part.duplicate()
		solid.node = _world.get_child(-1)
		_solids.append(solid)
		if part.id == "heart": core_sprite = solid.node

func _vortex_can_advance() -> bool:
	# The preview's shared pause/speed clock owns all four vortices.
	return false

func set_vortex_time(seconds: float) -> void:
	_vortex_animator.phase = fposmod(seconds / _vortex_animator.CYCLE_SECONDS,1.0)
	for material in _vortex_animator.materials:
		material.set_shader_parameter("phase",_vortex_animator.phase)

func set_pose(frame: int, impact: bool) -> void:
	actor.set_frame_and_progress(frame,0)
	core_sprite.modulate = Color(1.18,1.08,1.18) if impact else Color.WHITE

func contact_error() -> float:
	return (actor.position + hammer_offset).distance_to(strike_point)

func footprint() -> Rect2:
	return Rect2(hero_grid-Vector2.ONE*.16,Vector2.ONE*.32)
