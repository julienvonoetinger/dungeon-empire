extends "res://scripts/mobile_dungeon_renderer.gd"
## Only this review renderer replaces the three closed wall spans and their shared pillar.
const START := Vector2(6,6)
const SPRITES := "res://artifacts/treasury-wireframe/"
var layout: Dictionary = {}
var replaced: Array[Dictionary] = []
var painted: Array[String] = []
var images: Dictionary = {}

func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
	if layout.is_empty():
		return super._ordered_parts(parts)
	replaced.clear()
	painted.clear()
	var merged: Array[Dictionary] = []
	for part in parts:
		var take := false
		for host: Dictionary in layout.hosts:
			var at := START + Vector2(host.at[0],host.at[1])
			if part.id == host.prefix and part.at == at:
				replaced.append(part)
				take = true
				break
		if not take:
			merged.append(part)
	for item: Dictionary in layout.objects:
		var lo := Vector3(START.x+item.min[0],START.y+item.min[1],item.min[2])
		var hi := Vector3(START.x+item.max[0],START.y+item.max[1],item.max[2])
		var rect := Rect2(grid_to_local(START)+Vector2(item.frame[0],item.frame[1]),Vector2(item.frame[2],item.frame[3]))
		var eye: Vector3 = _definition.get("view_direction")
		merged.append({"id":item.id,"at":START,"min":lo,"max":hi,"rect":rect,"review":true,
			"depth":Vector2((lo.x+hi.x)*.5,(lo.y+hi.y)*.5).dot(Vector2(eye.x,eye.y))})
	return super._ordered_parts(merged)

func module_image(id: String) -> Image:
	return Image.load_from_file(SPRITES+id+".png")

func _draw_part(part: Dictionary, layer: int) -> void:
	if not part.has("review"):
		super._draw_part(part,layer)
		return
	if not images.has(part.id):
		var img := module_image(part.id)
		assert(img != null and not img.is_empty())
		img.generate_mipmaps()
		images[part.id] = ImageTexture.create_from_image(img)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = images[part.id]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = part.rect.position
	sprite.scale = part.rect.size/sprite.texture.get_size()
	sprite.z_index = layer
	_world.add_child(sprite)
	painted.append(part.id)
