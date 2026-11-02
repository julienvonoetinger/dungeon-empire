@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Visual ranged attack against the real Core. No simulation or save access.
const NORMALS := {&"se":Vector2.LEFT,&"sw":Vector2.UP,&"nw":Vector2.RIGHT,&"ne":Vector2.DOWN}
var actor: AnimatedSprite2D
var contact_shadow: Sprite2D
var core_sprite: Sprite2D
const SPELL := preload("res://scripts/mycean_spore_burst.gd")
var projectile: Node2D
var charge: Node2D
var burst: Node2D
var _registration: Dictionary
var facing: StringName
var hero_grid := Vector2.ZERO
var launch_point := Vector2.ZERO
var impact_point := Vector2.ZERO
var vortex_center := Vector2.ZERO
var vortex_radius := 0.0
var release_time := .65
var impact_time := .97
var _solids: Array[Dictionary] = []

func build(direction: StringName, frames: SpriteFrames, registration: Dictionary) -> void:
	facing = direction
	_registration = registration
	var normal: Vector2 = NORMALS[facing]
	hero_grid = normal*2.0
	var cells := {}
	var openings := {}
	for distance in 3:
		var centre := Vector2i(normal*distance)
		for y in range(-1,1):
			for x in range(-1,1):
				cells[centre+Vector2i(x,y)] = true
				openings[centre+Vector2i(x,y)] = 15
	render_plan({"cells":cells,"openings":openings,"hearts":PackedVector2Array([Vector2.ZERO]),"floor_variants":true},{},false)
	var at := grid_to_local(hero_grid)
	contact_shadow = Sprite2D.new()
	contact_shadow.texture = load(LIGHT_FALLOFF_PATH)
	contact_shadow.modulate = Color(0,0,0,.5)
	contact_shadow.scale = Vector2(38,19)/contact_shadow.texture.get_size()
	contact_shadow.position = at
	_world.add_child(contact_shadow)
	actor = AnimatedSprite2D.new()
	actor.name = "Mycean"
	actor.sprite_frames = frames
	actor.animation = facing
	actor.centered = false
	actor.offset = -Vector2(registration.anchor[0],registration.anchor[1])
	actor.scale = Vector2.ONE*float(registration.hero_scale)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.z_index = 1
	actor.position = at
	_world.add_child(actor)
	var parts: Array[Dictionary] = _solids.duplicate()
	parts.append({"node":actor,"id":"mycean","min":Vector3(hero_grid.x-.16,hero_grid.y-.16,0),
		"max":Vector3(hero_grid.x+.16,hero_grid.y+.16,.95),
		"rect":Rect2(at+actor.offset*actor.scale,Vector2.ONE*320*actor.scale),
		"depth":(hero_grid.x+hero_grid.y)*.6123724356957945})
	for part in _ordered_parts(parts): _world.move_child(part.node,-1)
	var heart: Dictionary = DEFINITION.get("entries")["heart"]
	vortex_center = Vector2(heart.offset[0],heart.offset[1])+Vector2(heart.vortex.center[0],heart.vortex.center[1])
	vortex_radius = float(heart.vortex.radius)
	impact_point = vortex_center
	launch_point = emitter_point(int(registration.release_frame))
	charge = SPELL.new()
	charge.name = "GatheringSpores"
	charge.z_index = 1
	_world.add_child(charge)
	_world.move_child(charge,actor.get_index()+1)
	projectile = SPELL.new()
	projectile.name = "SporeOrb"
	projectile.kind = SPELL.Kind.FLIGHT
	projectile.origin = launch_point
	projectile.target = impact_point
	# A free projectile travelling at vortex height, above this floor-only stage.
	projectile.z_index = 2
	_world.add_child(projectile)
	burst = SPELL.new()
	burst.name = "SporeImpact"
	burst.kind = SPELL.Kind.IMPACT
	burst.target = impact_point
	burst.z_index = 2
	_world.add_child(burst)
	release_time = float(registration.release_ms)/1000.0
	impact_time = release_time+float(registration.flight_ms)/1000.0
	for frame in frames.get_frame_count(facing):
		var used: Rect2 = frames.get_frame_texture(facing,frame).get_image().get_used_rect()
		_frame = _frame.merge(Rect2(at+(actor.offset+used.position)*actor.scale,used.size*actor.scale))
	for frame in frames.get_frame_count(facing):
		_frame = _frame.merge(Rect2(emitter_point(frame)-Vector2.ONE*34,Vector2.ONE*68))
	_frame = _frame.merge(Rect2(impact_point-Vector2.ONE*78,Vector2.ONE*156)).grow(12)
	set_pose(0,0)

func _draw_part(part: Dictionary, layer: int) -> void:
	super._draw_part(part,layer)
	if layer == 1:
		var solid := part.duplicate()
		solid.node = _world.get_child(-1)
		_solids.append(solid)
		if part.id == "heart": core_sprite = solid.node

func _vortex_can_advance() -> bool: return false

func set_vortex_time(seconds: float) -> void:
	_vortex_animator.phase = fposmod(seconds/_vortex_animator.CYCLE_SECONDS,1.0)
	for material in _vortex_animator.materials:
		material.set_shader_parameter("phase",_vortex_animator.phase)

func emitter_point(frame: int) -> Vector2:
	var xy: Array = _registration.views[facing].emitters[frame]
	return actor.position+(Vector2(xy[0],xy[1])+actor.offset)*actor.scale

func set_pose(frame: int, seconds: float) -> void:
	actor.set_frame_and_progress(frame,0)
	var released := seconds+.000001 >= release_time
	var impacted := seconds+.000001 >= impact_time
	charge.origin = emitter_point(frame)
	charge.seconds = seconds
	charge.progress = smoothstep(.15,.55,seconds)
	charge.visible = seconds >= .15 and not released
	charge.refresh()
	projectile.seconds = seconds
	projectile.progress = clampf((seconds-release_time)/(impact_time-release_time),0,1)
	projectile.visible = released and not impacted
	projectile.refresh()
	burst.seconds = seconds
	burst.progress = clampf((seconds-impact_time)/.32,0,1)
	burst.visible = impacted and seconds < impact_time+.32
	burst.refresh()
	core_sprite.modulate = Color(1.13,1.24,1.10) if impacted and seconds<impact_time+.09 else Color.WHITE
