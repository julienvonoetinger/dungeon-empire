@tool
extends Node2D
## Art review only. Geometry, texture maps and flame occlusion are baked offline.
const BASE := "res://docs/reference/mobile-light-review/painted-v2/"

class TorchStudy extends "res://scripts/mobile_dungeon_renderer.gd":
	var entries: Dictionary = {}
	var textures: Dictionary = {}
	var lights: Array[PointLight2D] = []
	var falloff: Texture2D
	var placements := [
		{"id":"torch-horizontal", "at":Vector2(1,0)},
		{"id":"torch-vertical", "at":Vector2(0,1)}
	]

	func build() -> void:
		var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"prepared.json"))
		for entry: Dictionary in definition.entries:
			entries[entry.id] = entry
			textures[entry.id] = ImageTexture.create_from_image(Image.load_from_file("res://"+str(entry.file)))
		falloff = ImageTexture.create_from_image(Image.load_from_file("res://docs/reference/mobile-light-review/prepared/light-falloff.png"))
		var cells := {}
		for y in 2:
			for x in 3:
				cells[Vector2i(x,y)] = true
		render_plan({"cells":cells,"openings":{}}, {}, false)

	func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
		for placement: Dictionary in placements:
			var entry: Dictionary = entries[placement.id]
			var at: Vector2 = placement.at
			var lo := Vector3(entry.bounds.min[0]+at.x,entry.bounds.min[1]+at.y,entry.bounds.min[2])
			var hi := Vector3(entry.bounds.max[0]+at.x,entry.bounds.max[1]+at.y,entry.bounds.max[2])
			parts.append({"id":"review-"+str(placement.id),"kind":placement.id,"at":at,
				"min":lo,"max":hi,"depth":Vector2((lo.x+hi.x)*.5,(lo.y+hi.y)*.5).dot(Vector2(.18,.9)),
				"rect":Rect2(at*256+Vector2(entry.offset[0],entry.offset[1]),Vector2(entry.size[0],entry.size[1]))})
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
		sprite.light_mask = 0
		_world.add_child(sprite)
		_frame = _frame.merge(part.rect)
		var light := PointLight2D.new()
		light.texture = falloff
		light.texture_scale = float(entry.radius)*2/128
		light.position = part.at*256+Vector2(entry.emission[0],entry.emission[1])
		light.color = Color(entry.color[0],entry.color[1],entry.color[2])
		light.energy = entry.energy
		light.blend_mode = Light2D.BLEND_MODE_ADD
		light.shadow_enabled = false
		_world.add_child(light)
		lights.append(light)

	func set_local_lights(enabled: bool) -> void:
		for light in lights:
			light.enabled = enabled

var study: TorchStudy
var lights_enabled := true

func _ready() -> void:
	study = TorchStudy.new()
	add_child(study)
	study.build()
	var camera := Camera2D.new()
	camera.position = Vector2(384,220)
	camera.zoom = Vector2.ONE*.75
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		lights_enabled = not lights_enabled
		study.set_local_lights(lights_enabled)
