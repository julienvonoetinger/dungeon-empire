@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Isolated spell rehearsal. Native masonry, measured emitter, no game/save state.
const CONFIG := {
	&"se": {"door":"west", "axis":0, "normal":Vector2.LEFT},
	&"sw": {"door":"north", "axis":1, "normal":Vector2.UP},
	&"nw": {"door":"east", "axis":0, "normal":Vector2.RIGHT},
	&"ne": {"door":"south", "axis":1, "normal":Vector2.DOWN},
}
const SEAL_HEIGHT := .64

const Spell := preload("res://scripts/mycean_arcane_spell.gd")

var actor: AnimatedSprite2D
var contact_shadow: Sprite2D
var spell: Spell
var facing: StringName
var hero_grid := Vector2.ZERO
var seal_grid := Vector2.ZERO
var seal_point := Vector2.ZERO
var opened := false
var channel_time := .45
var unlock_time := 1.5
var _registration: Dictionary
var _solids: Array[Dictionary] = []
var _closed: Array[Sprite2D] = []
var _open: Array[Sprite2D] = []

func build(direction: StringName, frames: SpriteFrames, registration: Dictionary) -> void:
	facing = direction
	_registration = registration
	channel_time = float(registration.channel_ms)/1000.0
	unlock_time = float(registration.unlock_ms)/1000.0
	var config: Dictionary = CONFIG[facing]
	var normal: Vector2 = config.normal
	var cell := Vector2i(1,0) if config.axis == 0 else Vector2i(0,1)
	seal_grid = Vector2(cell)+Vector2(.5,.5)+normal*.025
	hero_grid = seal_grid+normal*1.05
	var cells := {}
	for i in 3: cells[Vector2i(i,0) if config.axis == 0 else Vector2i(0,i)] = true
	render_plan({"cells":cells,"openings":{},"floor_variants":true,"door_materials":{cell:"arcane"}},
		{cell:"doors/"+str(config.door)},false)
	for solid in _solids:
		if str(solid.id).begins_with("door-"): _closed.append(solid.node)
	# Prepared open frame contains no leaf. Keep all its sorted masonry pieces.
	var prefix := "door-"+str(config.door)+"-open"
	var ids := [prefix+"-leaf",prefix+"-arch"]
	for id: String in _definition.entries[prefix+"-leaf"].get("companions",[]): ids.append(id)
	for id: String in ids:
		_draw_part(_part(id,Vector2(cell)),1)
		var node: Sprite2D = _solids[-1].node
		_open.append(node)
		node.visible = false
	seal_point = grid_to_local(seal_grid,SEAL_HEIGHT)
	contact_shadow = Sprite2D.new()
	contact_shadow.texture = load(LIGHT_FALLOFF_PATH)
	contact_shadow.modulate = Color(0,0,0,.5)
	contact_shadow.scale = Vector2(38,19)/contact_shadow.texture.get_size()
	contact_shadow.position = grid_to_local(hero_grid)
	_world.add_child(contact_shadow)
	actor = AnimatedSprite2D.new()
	actor.name = "Mycean"
	actor.sprite_frames = frames
	actor.animation = facing
	actor.centered = false
	actor.offset = -Vector2(registration.anchor[0],registration.anchor[1])
	actor.scale = Vector2.ONE*float(registration.hero_scale)
	actor.position = grid_to_local(hero_grid)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.z_index = 1
	_world.add_child(actor)
	var parts: Array[Dictionary] = _solids.duplicate()
	parts.append({"node":actor,"id":"mycean","min":Vector3(hero_grid.x-.16,hero_grid.y-.16,0),
		"max":Vector3(hero_grid.x+.16,hero_grid.y+.16,.64),
		"rect":Rect2(actor.position+actor.offset*actor.scale,Vector2.ONE*float(registration.frame_size)*actor.scale),
		"depth":(hero_grid.x+hero_grid.y)*.6123724356957945})
	for part in _ordered_parts(parts): _world.move_child(part.node,-1)
	spell = Spell.new()
	spell.name = "StaffSpell"
	# The ray approaches the same side as its caster. Draw it in that physical
	# layer, so a far-side spell cannot paint through the near jamb or panel.
	spell.z_index = 1
	spell.target = seal_point
	spell.seal_axis = grid_to_local(Vector2.DOWN if config.axis == 0 else Vector2.RIGHT).normalized()
	_world.add_child(spell)
	_world.move_child(spell,actor.get_index()+1)
	for i in frames.get_frame_count(facing):
		var used: Rect2 = frames.get_frame_texture(facing,i).get_image().get_used_rect()
		_frame = _frame.merge(Rect2(actor.position+(actor.offset+used.position)*actor.scale,used.size*actor.scale))
		_frame = _frame.merge(Rect2(emitter_point(i)-Vector2.ONE*22,Vector2.ONE*44))
	_frame = _frame.merge(Rect2(seal_point-Vector2.ONE*42,Vector2.ONE*84)).grow(12)
	set_pose(0,0)

func _draw_part(part: Dictionary, layer: int) -> void:
	super._draw_part(part,layer)
	if layer == 1:
		var solid := part.duplicate()
		solid.node = _world.get_child(-1)
		_solids.append(solid)

func emitter_point(frame: int) -> Vector2:
	var xy: Array = _registration.views[facing].emitters[frame]
	return actor.position+(Vector2(xy[0],xy[1])+actor.offset)*actor.scale

func set_pose(frame: int, seconds: float) -> void:
	actor.set_frame_and_progress(frame,0)
	opened = seconds+.000001 >= unlock_time
	for part in _closed: part.visible = not opened
	for part in _open: part.visible = opened
	spell.origin = emitter_point(frame)
	spell.seconds = seconds
	spell.channel = seconds+.000001 >= channel_time and not opened
	spell.charge = clampf((seconds-.2)/.25,0,1) if not opened else maxf(0,1-(seconds-unlock_time)/.1)
	spell.release = clampf((seconds-unlock_time)/.2,0,1) if opened and seconds<unlock_time+.2 else 0.0
	spell.releasing = opened and seconds<unlock_time+.2
	spell.refresh()
