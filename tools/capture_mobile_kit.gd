extends SceneTree
## Human visual review: normal fixed scale, overview and special joins.
const OUTPUT := "res://docs/reference/mobile-kit/captures/"
var viewport: SubViewport
var output := OUTPUT

func _initialize() -> void:
	_capture.call_deferred()

func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(output + name + ".png")

func _scene_names() -> PackedStringArray:
	var names := OS.get_cmdline_user_args()
	if names.is_empty():
		for file in DirAccess.get_files_at("res://scenes"):
			if file.ends_with(".tscn") and file not in ["DungeonHeart.tscn", "DungeonTorch.tscn"]:
				names.append(file.get_basename())
	return names

func _capture() -> void:
	if Engine.is_editor_hint():
		output = "res://docs/reference/mobile-kit/editor-captures/"
		var filesystem: Object = Engine.get_singleton("EditorInterface").get_resource_filesystem()
		while filesystem.is_scanning() or filesystem.is_importing():
			await process_frame
	DirAccess.make_dir_recursive_absolute(output)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var names := _scene_names()
	var inventory := []
	for name in names:
		var scene: Node2D = load("res://scenes/" + name + ".tscn").instantiate()
		viewport.add_child(scene)
		await process_frame
		await _save(name + "-native")
		var dungeon: Node2D = scene.get_node("Dungeon")
		var camera: Camera2D = scene.get_node("Camera2D")
		var plan: Dictionary = dungeon.get_connection_plan()
		inventory.append({"scene": name, "cells": plan.cells.size(), "specials": plan.specials.size(), "sprites": dungeon.get_node("PreparedSprites").get_child_count(), "zoom": camera.zoom.x})
		for cell: Vector2i in plan.specials:
			camera.position = (Vector2(cell) + Vector2(.5, .3)) * 256
			camera.zoom = Vector2.ONE * .75
			camera.force_update_scroll()
			await _save(name + "-" + str(plan.specials[cell]).replace("/", "-") + "-%d-%d" % [cell.x, cell.y])
		var frame: Rect2 = dungeon.get_content_rect()
		camera.position = frame.get_center()
		camera.zoom = Vector2.ONE * minf(1200 / frame.size.x, 660 / frame.size.y)
		camera.force_update_scroll()
		await _save(name + "-overview")
		viewport.remove_child(scene)
		scene.free()
		print("Captured ", name)
	var out := FileAccess.open("res://docs/reference/mobile-kit/" + ("editor-" if Engine.is_editor_hint() else "") + "scene-inventory.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(inventory, "\t") + "\n")
	quit()
