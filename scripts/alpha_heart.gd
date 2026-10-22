@tool
extends Node2D
const KIT := preload("res://scripts/alpha_kit.gd")

func _ready() -> void:
	if get_node_or_null("HeartSprite") == null:
		var sprite := KIT.make("heart",220)
		sprite.name = "HeartSprite"
		sprite.position = Vector2(-110,-147)
		sprite.z_index = 1
		sprite.set_meta("kind","heart")
		add_child(sprite)
