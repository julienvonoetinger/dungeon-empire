@tool
extends Node2D
## Complete native-alpha sprite retained from the retired architecture kit.
const TEXTURE := preload("res://assets/dungeon/heart/heart.png")
const SOURCE_SIZE := Vector2(1269, 1239)
const BODY := Rect2(295, 322, 680, 724)

func _ready() -> void:
	if get_node_or_null("HeartSprite") == null:
		var factor := TEXTURE.get_size() / SOURCE_SIZE
		var atlas := AtlasTexture.new()
		atlas.atlas = TEXTURE
		atlas.region = Rect2(Vector2.ZERO, TEXTURE.get_size())
		atlas.filter_clip = true
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.offset = -BODY.position * factor
		sprite.scale = Vector2.ONE * (220.0 / (BODY.size.x * factor.x))
		sprite.set_meta("asset_id", "heart")
		sprite.set_meta("source_region", atlas.region)
		sprite.set_meta("source_path", TEXTURE.resource_path)
		sprite.set_meta("body_size", BODY.size * (220.0 / BODY.size.x))
		sprite.name = "HeartSprite"
		sprite.position = Vector2(-110,-147)
		sprite.z_index = 1
		sprite.set_meta("kind","heart")
		add_child(sprite)
