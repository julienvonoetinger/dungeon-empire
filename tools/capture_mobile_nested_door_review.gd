extends SceneTree
## Appearance review only, using the existing prepared-sprite runtime renderer.
const BASE := "res://docs/reference/mobile-door-frame-review/"
var review := BASE + "painted-v8/"
const DEFINITION_SCRIPT = preload("res://scripts/mobile_kit_definition.gd")
var viewport: SubViewport

class NestedReview extends "res://scripts/mobile_dungeon_renderer.gd":
	var proposed := false
	func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
		if proposed:
			var added: Array[Dictionary] = []
			for part in parts:
				if str(part.id).begins_with("door-") and str(part.id).ends_with("-leaf"):
					for suffix in ["inner-arch", "jamb-left", "jamb-right", "smooth-upper", "smooth-left", "smooth-right"]:
						added.append(_part(str(part.id).replace("-leaf", "-" + suffix), part.at))
			parts.append_array(added)
		return super._ordered_parts(parts)

func _initialize() -> void:
	if "--legacy-v7" in OS.get_cmdline_user_args():
		review = BASE + "painted-v7/"
	if "--art" in OS.get_cmdline_user_args():
		review = BASE + "painted-art-v1/"
	if "--art-v2" in OS.get_cmdline_user_args():
		review = BASE + "painted-art-v2/"
	_capture.call_deferred()

func _definition(mode: String) -> Resource:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE + "source/catalog.json"))
	var definition: Resource = DEFINITION_SCRIPT.new()
	definition.entries = data.atlas.regions.duplicate(true)
	var atlas := ImageTexture.create_from_image(Image.load_from_file(BASE + "source/atlas-256.png"))
	for id: String in definition.entries:
		var region: Array = definition.entries[id].region
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(region[0], region[1], region[2], region[3])
		texture.filter_clip = true
		definition.textures[id] = texture
	if mode != "before":
		var proposal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(review + "proposal.json"))
		for id: String in proposal.entries:
			definition.entries[id] = proposal.entries[id]
			var file := "res://" + str(proposal.entries[id].file)
			if mode == "overlay":
				file = file.replace("/sprites/", "/overlays/")
			definition.textures[id] = ImageTexture.create_from_image(Image.load_from_file(file))
		if mode == "overlay":
			for direction in ["north", "east", "south", "west"]:
				var id: String = "door-" + direction + "-arch"
				definition.textures[id] = ImageTexture.create_from_image(Image.load_from_file("res://docs/reference/mobile-kit/overlays/" + id + ".png"))
	return definition

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(review + "captures")
	viewport = SubViewport.new()
	viewport.size = Vector2i(400, 420)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for mode in ["before", "proposal", "overlay"]:
		for direction in ["north", "east", "south", "west"]:
			var scene := Node2D.new()
			viewport.add_child(scene)
			var dungeon := NestedReview.new()
			dungeon.proposed = mode != "before"
			dungeon._definition = _definition(mode)
			scene.add_child(dungeon)
			var vertical: bool = direction == "north" or direction == "south"
			var axis := Vector2i.DOWN if vertical else Vector2i.RIGHT
			var cells := {Vector2i.ZERO: 0}
			cells[-axis] = 0
			cells[axis] = 0
			var openings := {}
			openings[-axis] = 1 if vertical else 8
			openings[axis] = 4 if vertical else 2
			dungeon.render_plan({"cells": cells, "openings": openings}, {Vector2i.ZERO: "doors/" + direction}, false, false)
			var camera := Camera2D.new()
			camera.position = Vector2(128, 76.8)
			camera.zoom = Vector2.ONE * .75
			scene.add_child(camera)
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(review + "captures/" + mode + "-" + direction + ".png")
			print("Captured ", mode, "-", direction)
			viewport.remove_child(scene)
			scene.free()
	quit()
