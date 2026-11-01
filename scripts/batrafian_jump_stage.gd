@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Real kit floor/trap; independent sample stage, no gameplay state.
const FORWARD := {&"se": Vector2.RIGHT, &"sw": Vector2.DOWN, &"nw": Vector2.LEFT, &"ne": Vector2.UP}
var actor: AnimatedSprite2D
var contact_shadow: Sprite2D
var hero_grid := Vector2.ZERO
var start_grid := Vector2.ZERO
var end_grid := Vector2.ZERO
var root_height := 0.0
var model_z_to_pixels := 0.0
var launch_time := .2
var land_time := .67
var apex_height := .55

func build(direction: StringName, frames: SpriteFrames, registration: Dictionary) -> void:
	var step: Vector2 = FORWARD[direction]
	start_grid = Vector2(.5,.5) - step
	end_grid = Vector2(.5,.5) + step
	launch_time = float(registration.launch_time)
	land_time = float(registration.land_time)
	apex_height = float(registration.apex_height)
	model_z_to_pixels = float(registration.frame_size)/float(registration.ortho_scale)*cos(PI/6)*float(registration.hero_scale)
	var cells := {}
	var openings := {}
	for n in range(-1,2):
		var cell:=Vector2i(step*n)
		cells[cell]=true
		openings[cell]=15
	render_plan({"cells":cells,"openings":openings,
		"floor_replacements":{Vector2i.ZERO:"trap-spike-ready-floor"},
		"mechanisms":{Vector2i.ZERO:"trap-spike-ready-mechanism"}}, {},false)
	contact_shadow=Sprite2D.new()
	contact_shadow.name="GroundShadow"
	contact_shadow.texture=load(LIGHT_FALLOFF_PATH)
	_world.add_child(contact_shadow)
	actor=AnimatedSprite2D.new()
	actor.name="Batrafian"
	actor.sprite_frames=frames
	actor.animation=direction
	actor.centered=false
	actor.offset=-Vector2(registration.anchor[0],registration.anchor[1])
	actor.scale=Vector2.ONE*float(registration.hero_scale)
	actor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	_world.add_child(actor)
	# Fit all poses at all trajectory extrema, not just the ground endpoint.
	for grid in [start_grid,end_grid]:
		for height in [0.0,apex_height]:
			_frame=_frame.merge(Rect2(grid_to_local(grid)-Vector2(0,height*model_z_to_pixels)+actor.offset*actor.scale,
				Vector2.ONE*float(registration.frame_size)*actor.scale))
	_frame=_frame.grow(8)
	set_pose(0.0,0)

func set_pose(seconds: float, frame: int) -> void:
	var progress:=clampf((seconds-launch_time)/(land_time-launch_time),0,1)
	hero_grid=start_grid.lerp(end_grid,progress)
	root_height=4.0*apex_height*progress*(1-progress)
	var ground:=grid_to_local(hero_grid)
	actor.position=ground-Vector2(0,root_height*model_z_to_pixels)
	actor.set_frame_and_progress(frame,0.0)
	contact_shadow.position=ground
	var airborne:=root_height/apex_height
	contact_shadow.modulate=Color(0,0,0,lerpf(.5,.25,airborne))
	contact_shadow.scale=Vector2(38,19)*lerpf(1.0,.75,airborne)/contact_shadow.texture.get_size()
