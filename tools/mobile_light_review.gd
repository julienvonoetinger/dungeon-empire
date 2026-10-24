@tool
extends Node2D
## Separate appearance study: uses the current atlas without changing it.
const BASE := "res://docs/reference/mobile-light-review/"

class LightStudy extends "res://scripts/mobile_dungeon_renderer.gd":
	var entries: Dictionary = {}
	var textures: Dictionary = {}
	var lights: Array[PointLight2D] = []
	var falloff: Texture2D
	var placements := [
		{"id":"torch", "at":Vector2(.75,1.0/12.0), "height":.025},
		{"id":"crystal", "at":Vector2(3.25,1.0/12.0), "height":.17}
	]

	func build() -> void:
		var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"prepared.json"))
		for entry: Dictionary in definition.entries:
			entries[entry.id] = entry
			textures[entry.id] = ImageTexture.create_from_image(Image.load_from_file("res://"+str(entry.file)))
		falloff = ImageTexture.create_from_image(Image.load_from_file(BASE+"prepared/light-falloff.png"))
		var cells := {}
		for y in 2:
			for x in 4:
				cells[Vector2i(x,y)] = true
		render_plan({"cells":cells,"openings":{}}, {}, false)

	func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
		for placement: Dictionary in placements:
			var entry: Dictionary = entries[placement.id]
			var at: Vector2 = placement.at
			var height: float = placement.height
			var attachment := at*256-Vector2(.18,.9)*height*256
			var anchor := Vector2(entry.anchor[0],entry.anchor[1])
			parts.append({"id":"review-"+str(placement.id),"kind":placement.id,"at":at,
				"min":Vector3(at.x-.10,at.y+.001,0),"max":Vector3(at.x+.10,at.y+.045,.4),
				"depth":at.dot(Vector2(.18,.9)),"rect":Rect2(attachment-anchor,Vector2(entry.size[0],entry.size[1]))})
		return super._ordered_parts(parts)

	func _draw_part(part: Dictionary, layer: int) -> void:
		if not str(part.id).begins_with("review-"):
			super._draw_part(part,layer)
			return
		var entry: Dictionary = entries[part.kind]
		var sprite := Sprite2D.new()
		sprite.name = part.id
		sprite.texture = textures[part.kind]
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.position = part.rect.position
		sprite.z_index = layer
		# The artwork already contains its flame/core light and reflected colour.
		sprite.light_mask = 0
		_world.add_child(sprite)
		_frame = _frame.merge(part.rect)
		var light := PointLight2D.new()
		light.name = part.id+"-light"
		light.texture = falloff
		light.texture_scale = float(entry.radius)*2/128
		light.position = sprite.position+Vector2(entry.emission[0],entry.emission[1])
		light.color = Color(entry.color[0],entry.color[1],entry.color[2])
		light.energy = entry.energy
		light.blend_mode = Light2D.BLEND_MODE_ADD
		light.shadow_enabled = false
		_world.add_child(light)
		lights.append(light)

	func set_local_lights(enabled: bool) -> void:
		for light in lights:
			light.enabled = enabled

var study: LightStudy
var lights_enabled := true

func _ready() -> void:
	study = LightStudy.new()
	add_child(study)
	study.build()
	var camera := Camera2D.new()
	camera.position = Vector2(512,220)
	camera.zoom = Vector2.ONE*.75
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		lights_enabled = not lights_enabled
		study.set_local_lights(lights_enabled)
