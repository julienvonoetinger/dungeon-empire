extends SceneTree
## Human visual review: normal fixed scale, overview and special joins.
const REVIEW := "res://docs/reference/isometric-review/painted-v1/"
const OUTPUT := REVIEW + "captures/"
var viewport: SubViewport
var output := OUTPUT
var inventory_path := ""
var failed := false

func _initialize() -> void:
	_capture.call_deferred()

func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(output + name + ".png")
	if error != OK:
		failed = true
		push_error("Capture write failed (%d): %s" % [error,output+name+".png"])

func _scene_names() -> PackedStringArray:
	var names := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--output-root="):
			names.append(argument)
	if names.is_empty():
		for file in DirAccess.get_files_at("res://scenes"):
			if file.ends_with(".tscn"):
				names.append(file.get_basename())
	return names

func _capture() -> void:
	if Engine.is_editor_hint():
		output = REVIEW + "editor-captures/"
		var filesystem: Object = Engine.get_singleton("EditorInterface").get_resource_filesystem()
		while filesystem.is_scanning() or filesystem.is_importing():
			await process_frame
	inventory_path = REVIEW + ("editor-" if Engine.is_editor_hint() else "") + "scene-inventory.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-root="):
			var review_root := argument.trim_prefix("--output-root=").trim_suffix("/") + "/"
			output = review_root + ("editor-captures/" if Engine.is_editor_hint() else "captures/")
			inventory_path = review_root + ("editor-" if Engine.is_editor_hint() else "") + "scene-inventory.json"
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
		var dungeon := scene.get_node_or_null("Dungeon") as Node2D
		var camera := scene.get_node_or_null("Camera2D") as Camera2D
		if dungeon == null:
			dungeon = scene
			camera = Camera2D.new()
			camera.position = dungeon.get_content_rect().get_center()
			camera.zoom = Vector2.ONE * .75
			scene.add_child(camera)
		await _save(name + "-native")
		var plan: Dictionary = dungeon.get_connection_plan() if dungeon.has_method("get_connection_plan") else {"cells":{}, "specials":{}}
		var children := dungeon.get_node("PreparedSprites").get_children()
		inventory.append({"scene": name, "cells": plan.cells.size(), "specials": plan.specials.size(), "hearts": plan.get("hearts",PackedVector2Array()).size(),
			"sprites": children.filter(func(child: Node) -> bool: return child is Sprite2D).size(),
			"lights": children.filter(func(child: Node) -> bool: return child is PointLight2D).size(), "zoom": camera.zoom.x,
			"camera_position": [camera.position.x,camera.position.y]})
		if name == "DungeonTorch":
			dungeon.orientation = 1
			camera.position = dungeon.get_content_rect().get_center()
			camera.force_update_scroll()
			await _save(name + "-west")
		for i in plan.get("hearts",PackedVector2Array()).size():
			camera.position = dungeon.grid_to_local(plan.hearts[i])
			camera.zoom = Vector2.ONE * .75
			camera.force_update_scroll()
			await _save(name + "-heart-%d" % i)
		for cell: Vector2i in plan.specials:
			camera.position = dungeon.grid_to_local(Vector2(cell) + Vector2(.5, .3))
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
	var out := FileAccess.open(inventory_path, FileAccess.WRITE)
	if out == null:
		push_error("Cannot write capture inventory: " + inventory_path)
		quit(1)
		return
	out.store_string(JSON.stringify(inventory, "\t") + "\n")
	quit(1 if failed else 0)
