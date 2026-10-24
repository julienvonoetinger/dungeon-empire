@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Four prepared stairs with the same common rails, floor and pillars.
signal rebuilt
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")
var _plan: Dictionary = {}
func _ready() -> void:
	refresh_preview()
func refresh_preview() -> void:
	var cells := {}
	var openings := {}
	var specials := {}
	for i in range(4):
		var cell := Vector2i((i % 2) * 2, (i / 2) * 2)
		cells[cell] = true
		openings[cell] = 1 << i
		specials[cell] = "entrances/" + ["north", "east", "south", "west"][i]
	_plan = {"cells": cells, "openings": openings, "specials": specials}
	render_plan(_plan, specials, true)
	rebuilt.emit()
func get_connection_plan() -> Dictionary:
	return _plan
