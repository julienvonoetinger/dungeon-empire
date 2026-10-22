@tool
extends Node2D

## Unapproved visual study. Complete native-alpha images; no cutout geometry.
## The north facade remains the same height on both sides of the entrance.
const ROOT := "res://assets/dungeon/reference-study/"
const TORCH := preload("res://scenes/DungeonTorch.tscn")
const TORCH_SCALE := 0.36
# Authored center of the visible entry-masonry-v3 arch, not the PNG canvas.
const ENTRANCE_AXIS_X := 310.0
const TORCH_AXIS_OFFSET := 150.0
const SIZE := Vector2(920, 640)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build()
	if not Engine.is_editor_hint():
		get_viewport().size_changed.connect(_fit)
		_fit()

func _sprite(label: String, file: String, at: Vector2, factor: float, layer: int) -> Sprite2D:
	var part := Sprite2D.new()
	part.name = label
	part.texture = load(ROOT + file)
	part.centered = false
	part.position = at
	part.scale = Vector2.ONE * factor
	part.z_index = layer
	part.light_mask = 2
	add_child(part)
	return part

func _build() -> void:
	_sprite("Floor", "floor-patch-v2.png", Vector2(7, 155), 0.62, 0)
	var exterior := _sprite("Exterior", "exterior-v1.png", Vector2(677, -6), 0.458, 1)
	exterior.self_modulate = Color(0.64, 0.64, 0.70, 1)
	# Wall courses and arch share one authored masonry image. Only the wooden
	# leaf sits behind it; the inner reveals and threshold belong to the wall.
	var leaf := _sprite("Entrance", "door-leaf-v4.png", Vector2(238, 43), 0.128, 2)
	leaf.self_modulate = Color(0.78, 0.80, 0.85, 1)
	_sprite("EntryMasonry", "entry-masonry-v3.png", Vector2(27, -86), 0.44, 3)
	var corner := _sprite("EastCorner", "east-corner-v1.png", Vector2(0, -75), 0.75, 4)
	corner.self_modulate = Color(0.90, 0.90, 0.90, 1)
	for side in [-1.0, 1.0]:
		var torch: Sprite2D = TORCH.instantiate()
		torch.name = "TorchWest" if side < 0 else "TorchEast"
		torch.scale = Vector2.ONE * TORCH_SCALE
		torch.position = Vector2(ENTRANCE_AXIS_X + side * TORCH_AXIS_OFFSET, 225)
		add_child(torch)
		_light(torch.position + Vector2(0, -48.75))

func _light(at: Vector2) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 384
	texture.height = 384
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0)
	var light := PointLight2D.new()
	light.texture = texture
	light.color = Color("955dff")
	light.energy = 0.85
	light.range_item_cull_mask = 2
	light.position = at
	add_child(light)

func _fit() -> void:
	var camera: Camera2D = $Camera2D
	var available := get_viewport_rect().size
	camera.position = SIZE * 0.5
	camera.zoom = Vector2.ONE * minf(available.x / SIZE.x, available.y / SIZE.y)
	camera.force_update_scroll()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-500, -500), SIZE + Vector2(1000, 1000)), Color("080e19"))
