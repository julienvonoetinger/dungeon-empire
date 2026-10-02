extends "res://scripts/mobile/vault_badge.gd"

signal repair_requested

const COPPER := Color("c66b50")
var repair_button: Button

func _init() -> void:
	super._init()
	size = Vector2(42, 42)
	repair_button = Button.new()
	repair_button.text = "R\u00e9parer"
	repair_button.position = Vector2(42, 4)
	repair_button.size = Vector2(90, 34)
	repair_button.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := preload("res://scripts/mobile/hud_frame.gd").new()
		style.border_color = Color("636568") if state == "disabled" else COPPER
		repair_button.add_theme_stylebox_override(state, style)
	repair_button.hide()
	repair_button.pressed.connect(func(): repair_requested.emit())
	add_child(repair_button)

func set_amount(value: int, capacity: int) -> void:
	super.set_amount(value, capacity)
	set_repair_visible(value == 0)

func set_repair_visible(needed: bool) -> void:
	repair_button.visible = needed
	size = Vector2(134 if needed else 42, 42)

func _draw() -> void:
	_draw_ring(COPPER)
