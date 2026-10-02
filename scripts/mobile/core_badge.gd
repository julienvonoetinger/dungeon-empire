extends "res://scripts/mobile/vault_badge.gd"

func _init() -> void:
	super._init()
	size = Vector2(42, 42)

func _draw() -> void:
	_draw_ring(Color("b46aef"))
