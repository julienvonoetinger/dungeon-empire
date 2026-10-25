@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Standalone scene for the same prepared heart support used by dungeon layouts.

@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")

func _ready() -> void:
	refresh_preview()

func refresh_preview(reload_textures := true) -> void:
	if not is_inside_tree():
		return
	# An already open editor can retain the previous tool script's generated node.
	var old_sprite := get_node_or_null("HeartSprite")
	if old_sprite != null and old_sprite.owner == null:
		remove_child(old_sprite)
		old_sprite.queue_free()
	render_plan({"cells":{},"openings":{},"hearts":PackedVector2Array([Vector2.ZERO])},{},false,reload_textures)
