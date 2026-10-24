@tool
extends Node2D
## Disposable art study; the production renderer, kit and heart remain untouched.
const OUTPUT := "res://docs/reference/mobile-heart-review/"

class HeartStudy extends "res://scripts/mobile_dungeon_renderer.gd":
	var heart_info: Dictionary
	var texture_info: Dictionary
	var heart_at := Vector2.ONE
	var heart_texture: Texture2D
	var order_report: Array[Dictionary] = []

	func build() -> void:
		# docs/ is deliberately excluded from Godot import. Decode the prepared
		# PNG directly, as the existing door review tools do; never paint pixels.
		var image := Image.load_from_file("res://" + str(texture_info.file))
		if image == null or image.is_empty():
			push_error("Missing prepared heart image: " + str(texture_info.file))
			return
		heart_texture = ImageTexture.create_from_image(image)
		var cells := {}
		for y in 2:
			for x in 2:
				cells[Vector2i(x,y)] = true
		render_plan({"cells":cells,"openings":{}}, {}, false)

	func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
		var factor := 256.0 / float(texture_info.density)
		var offset := Vector2(texture_info.anchor[0], texture_info.anchor[1]) * factor
		var size := Vector2(texture_info.size[0], texture_info.size[1]) * factor
		var half := Vector2(heart_info.footprint[0], heart_info.footprint[1]) * .5
		var heart := {"id":"review-heart", "at":heart_at,
			"min":Vector3(heart_at.x-half.x,heart_at.y-half.y,0),
			"max":Vector3(heart_at.x+half.x,heart_at.y+half.y,heart_info.supportHeight),
			"depth":heart_at.dot(Vector2(.18,.9)),"rect":Rect2(heart_at*256-offset,size)}
		parts.append(heart)
		var sorted := super._ordered_parts(parts)
		order_report.clear()
		for part in sorted:
			order_report.append({"id":part.id,"at":[part.at.x,part.at.y],"overlaps_heart":part.rect.intersects(heart.rect)})
		return sorted

	func _draw_part(part: Dictionary, layer: int) -> void:
		if part.id != "review-heart":
			super._draw_part(part,layer)
			return
		var sprite := Sprite2D.new()
		sprite.name = "ReviewHeart"
		sprite.texture = heart_texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered = false
		sprite.position = part.rect.position
		sprite.scale = Vector2.ONE * (256.0 / float(texture_info.density))
		sprite.z_index = layer
		_world.add_child(sprite)
		_frame = _frame.merge(part.rect)

static func create_study(id: String, density := 256, location := Vector2.ONE, definition_path := OUTPUT + "prepared.json") -> HeartStudy:
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(definition_path))
	var study := HeartStudy.new()
	for entry: Dictionary in definition.entries:
		if entry.id != id:
			continue
		study.heart_info = entry
		for variant: Dictionary in entry.variants:
			if int(variant.density) == density:
				study.texture_info = variant
	study.heart_at = location
	return study

func _ready() -> void:
	# In-scene preview at the production viewing scale; no change to F5/main scene.
	for child in get_children():
		child.queue_free()
	for i in 3:
		var id: String = ["a","b","c"][i]
		var study := create_study(id)
		study.position = Vector2(i * (2.0 + 1.0/6.0) * 256, 0)
		add_child(study)
		study.build()
		var label := Label.new()
		label.text = study.heart_info.name
		label.position = study.position + Vector2(30,-140)
		label.add_theme_font_size_override("font_size",27)
		add_child(label)
	var camera := Camera2D.new()
	camera.position = Vector2((3.0+1.0/6.0)*256,256)
	camera.zoom = Vector2.ONE * .75
	add_child(camera)
