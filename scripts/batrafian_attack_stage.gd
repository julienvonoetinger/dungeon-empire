@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Visual ranged attack against the real Core. No simulation or save access.
const NORMALS := {&"se":Vector2.LEFT,&"sw":Vector2.UP,&"nw":Vector2.RIGHT,&"ne":Vector2.DOWN}
var actor: AnimatedSprite2D
var contact_shadow: Sprite2D
var core_sprite: Sprite2D
var projectile: Sprite2D
var facing: StringName
var hero_grid := Vector2.ZERO
var launch_nock := Vector2.ZERO
var end_nock := Vector2.ZERO
var tip_offset := Vector2.ZERO
var impact_point := Vector2.ZERO
var vortex_center := Vector2.ZERO
var vortex_radius := 0.0
var release_time := .69
var impact_time := .95
var _solids: Array[Dictionary] = []

func build(direction: StringName, frames: SpriteFrames, registration: Dictionary) -> void:
	facing = direction
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
	actor.name = "Batrafian"
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
	parts.append({"node":actor,"id":"batrafian","min":Vector3(hero_grid.x-.16,hero_grid.y-.16,0),
		"max":Vector3(hero_grid.x+.16,hero_grid.y+.16,.95),
		"rect":Rect2(at+actor.offset*actor.scale,Vector2.ONE*320*actor.scale),
		"depth":(hero_grid.x+hero_grid.y)*.6123724356957945})
	for part in _ordered_parts(parts): _world.move_child(part.node,-1)
	var view: Dictionary = registration.views[facing]
	var arrow: Dictionary = registration.projectiles[facing]
	launch_nock = at+Vector2(view.nock[0],view.nock[1])
	tip_offset = Vector2(arrow.tip_offset[0],arrow.tip_offset[1])*actor.scale.x
	var heart: Dictionary = DEFINITION.get("entries")["heart"]
	vortex_center = Vector2(heart.offset[0],heart.offset[1])+Vector2(heart.vortex.center[0],heart.vortex.center[1])
	vortex_radius = float(heart.vortex.radius)
	# Preserve the rendered shooting axis: the shaft reaches the vortex within
	# its radius, with no sideways camera-plane rotation at the handoff.
	var axis := tip_offset.normalized()
	impact_point = launch_nock+axis*(vortex_center-launch_nock).dot(axis)
	end_nock = impact_point-tip_offset
	projectile = Sprite2D.new()
	projectile.name = "Arrow"
	projectile.texture = load(arrow.path)
	projectile.centered = false
	projectile.offset = -Vector2(arrow.anchor[0],arrow.anchor[1])
	projectile.scale = actor.scale
	projectile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	projectile.z_index = 2
	_world.add_child(projectile)
	release_time = float(registration.release_ms)/1000.0
	impact_time = release_time+float(registration.flight_ms)/1000.0
	for frame in frames.get_frame_count(facing):
		var used: Rect2 = frames.get_frame_texture(facing,frame).get_image().get_used_rect()
		_frame = _frame.merge(Rect2(at+(actor.offset+used.position)*actor.scale,used.size*actor.scale))
	for position in [launch_nock,end_nock]:
		_frame = _frame.merge(Rect2(position+projectile.offset*projectile.scale,projectile.texture.get_size()*projectile.scale))
	_frame = _frame.grow(12)
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

func set_pose(frame: int, seconds: float) -> void:
	actor.set_frame_and_progress(frame,0)
	var u := clampf((seconds-release_time)/(impact_time-release_time),0,1)
	projectile.position = launch_nock.lerp(end_nock,u)
	projectile.visible = seconds+.000001 >= release_time and seconds < impact_time-.000001
	core_sprite.modulate = Color(1.25,1.10,1.25) if seconds+.000001 >= impact_time and seconds < impact_time+.08 else Color.WHITE

func tip_position() -> Vector2: return projectile.position+tip_offset
