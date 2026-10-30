@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Standalone prepared torch, with the same atlas/light metadata as dungeon walls.
@export_enum("Mur horizontal", "Mur vertical") var orientation := 0:
	set(value):
		orientation = value
		refresh_preview(false)
@export var light_enabled := true:
	set(value):
		light_enabled = value
		refresh_preview(false)
@export_tool_button("Refresh preview", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")

func _ready() -> void:
	refresh_preview()

func refresh_preview(reload_textures := true) -> void:
	if not is_inside_tree():
		return
	var plan := {"cells":{}, "openings":{}, "standalone_props":true,
		"torch_lights_enabled":light_enabled}
	plan["torch_north_cells" if orientation == 0 else "torch_west_cells"] = [Vector2i.ZERO]
	render_plan(plan, {}, false, reload_textures)
