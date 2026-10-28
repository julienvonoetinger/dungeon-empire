@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Inspection only: looping lockpick attempt on a closed, locked chest.
const FRAMES: SpriteFrames = preload("res://assets/previews/vulpin-chest-lockpick/frames.tres")
const HERO_SCALE := .85
const CONFIG := {
	"se": {"chest": "west", "normal": Vector2.LEFT},
	"sw": {"chest": "north", "normal": Vector2.UP},
	"nw": {"chest": "east", "normal": Vector2.RIGHT},
	"ne": {"chest": "south", "normal": Vector2.DOWN},
}

class ContactGuides extends Node2D:
	var target := Vector2.ZERO
	var hands: Array[Vector2] = []
	func _draw() -> void:
		draw_circle(target, 5, Color(1,.7,.2), false, 1.5)
		for hand in hands:
			draw_circle(hand, 3, Color(.4,1,.85), false, 1.5)
		if hands.size() == 2: draw_line(hands[0], hands[1], Color(.4,1,.85,.7), 1)

var actor: AnimatedSprite2D
var facing := "se"
var hero_grid := Vector2.ZERO
var chest_grid := Vector2.ONE
var chest: Dictionary
var contact_local := Vector2.ZERO
var _registration: Dictionary
var _anchor := Vector2.ZERO
var _tool_offset := Vector2.ZERO
var _guides: ContactGuides

func build(direction: String) -> void:
	facing = direction
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/previews/vulpin-chest-lockpick/registration.json"))
	_registration = data.directions[facing]
	_anchor = Vector2(_registration.anchor[0], _registration.anchor[1])
	_tool_offset = (Vector2(_registration.lock[0], _registration.lock[1]) - _anchor) * HERO_SCALE
	var config: Dictionary = CONFIG[facing]
	var cells := {Vector2i.ZERO:true, Vector2i(1,0):true, Vector2i(0,1):true, Vector2i.ONE:true}
	var openings := {}
	for cell in cells: openings[cell] = 15
	render_plan({"cells":cells, "openings":openings, "floor_variants":true}, {}, false)
	var suffix: String = "" if config.chest == "south" else "-" + str(config.chest)
	var chest_id := "prop-chest" + suffix
	var shadow := _part(chest_id + "-shadow", chest_grid)
	_draw_part(shadow, 0)
	chest = _part(chest_id, chest_grid)
	_draw_part(chest, 1)
	chest.node = _world.get_child(-1)
	var painted_lock: Array = _registration.chestLock.local
	contact_local = grid_to_local(chest_grid) + Vector2(painted_lock[0], painted_lock[1])
	hero_grid = local_to_grid(contact_local - _tool_offset)
	var contact := Sprite2D.new()
	contact.texture = load(LIGHT_FALLOFF_PATH)
	contact.modulate = Color(0,0,0,.5)
	contact.scale = Vector2(38,19) / contact.texture.get_size()
	contact.position = grid_to_local(hero_grid)
	_world.add_child(contact)
	actor = AnimatedSprite2D.new()
	actor.name = "Vulpin"
	actor.sprite_frames = FRAMES
	actor.animation = StringName(facing)
	actor.centered = false
	actor.offset = -_anchor
	actor.scale = Vector2.ONE * HERO_SCALE
	actor.position = grid_to_local(hero_grid)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	actor.z_index = 1
	_world.add_child(actor)
	_guides = ContactGuides.new()
	_guides.z_index = 10
	_guides.visible = false
	_world.add_child(_guides)
	set_pose(0)
	_frame = _frame.merge(Rect2(actor.position - _anchor * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE)).grow(12)

func set_pose(frame: int) -> void:
	actor.set_frame_and_progress(frame, 0)
	# An attempt never grants access or changes the chest to its ajar artwork.
	var bounds: Dictionary = _registration.bounds[frame]
	var origin := Vector3(hero_grid.x, hero_grid.y, 0)
	var parts: Array[Dictionary] = [chest, {"node":actor, "id":"vulpin",
		"min":origin + Vector3(bounds.min[0],bounds.min[1],bounds.min[2]),
		"max":origin + Vector3(bounds.max[0],bounds.max[1],bounds.max[2]),
		"rect":Rect2(actor.position - _anchor * HERO_SCALE, Vector2.ONE * 256 * HERO_SCALE),
		"depth":(hero_grid.x + hero_grid.y) * .6123724356957945}]
	for part in _ordered_parts(parts): _world.move_child(part.node, -1)
	_guides.target = contact_local
	_guides.hands.assign([actor.position + _tool_offset])
	_guides.queue_redraw()

func set_guides(value: bool) -> void:
	_guides.visible = value

func set_ghost(value: bool) -> void:
	chest.node.modulate.a = .3 if value else 1.0

func registration_error() -> float:
	return (actor.position + _tool_offset).distance_to(contact_local)
