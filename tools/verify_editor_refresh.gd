@tool
extends Node

var failures: Array[String] = []

func _ready() -> void:
	if Engine.is_editor_hint() and "--verify-editor-refresh" in OS.get_cmdline_user_args():
		_run.call_deferred()

func _run() -> void:
	# Let the editor finish resource scanning before closing its SceneTree.
	await get_tree().create_timer(1.0).timeout
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var dungeon = scene.get_node("Dungeon")
	var heart: Node = dungeon.get_node_or_null("Heart")
	_check(heart != null,"The editor scene includes its authored heart instance")
	_check(Engine.is_editor_hint(),"This regression runs in editor mode")
	_check(dungeon.has_method("refresh_preview"),"An already-open preview can rebuild without reopening the scene")
	if not failures.is_empty():
		scene.queue_free()
		await get_tree().process_frame
		_finish()
		return
	var initial_parts: Array = dungeon.get_surface_pieces()
	var initial_id: int = initial_parts[0].get_instance_id()
	var initial_count: int = initial_parts.size()
	var kept := Marker2D.new()
	dungeon.add_child(kept)
	kept.owner = scene
	# Material inspector edits must rebuild the open scene with a stable seed.
	var original_seed: int = dungeon.variation_seed
	dungeon.variation_seed = 590
	await _wait_for_refresh()
	_check(dungeon.get_surface_pieces()[0].get_instance_id() != initial_id,"A visual seed edit refreshes the open preview")
	dungeon.stone_variation = false
	await _wait_for_refresh()
	_check(dungeon.get_surface_pieces().size() == initial_count,"Inspector toggle changes complete sprite materials without fragmenting geometry")
	dungeon.variation_seed = original_seed
	dungeon.stone_variation = true
	await _wait_for_refresh()
	_check(dungeon.get_surface_pieces().size() == initial_count,"Restoring material settings restores the original preview")
	# Inspector edits must update the existing instance, not a freshly loaded one.
	var local_layout: Resource = dungeon.layout.duplicate()
	dungeon.layout = local_layout
	local_layout.entrance_enabled = false
	await _wait_for_refresh()
	_check(_light_count(dungeon) == 0,"Disabling the entrance removes the old torch lights")
	_check(dungeon.get_torch_sprites().is_empty(),"Disabling the entrance removes its sprites in the open editor")
	_check(dungeon.get_surface_pieces()[0].get_instance_id() != initial_id,"The live preview rebuilt after an inspector edit")
	local_layout.entrance_enabled = true
	await _wait_for_refresh()
	_check(_light_count(dungeon) == 2,"Re-enabling the entrance restores exactly two lights")
	_check(dungeon.get_torch_sprites().size() == 2,"Re-enabling the entrance restores exactly two sprites")
	_check(dungeon.get_surface_pieces().size() == initial_count,"Rebuild has no accumulated old surfaces")
	# Reload code in place while the editor retains its generated children.
	var renderer: Script = dungeon.get_script()
	renderer.source_code += "\n# Editor refresh regression reload.\n"
	_check(renderer.reload(true) == OK,"The loaded tool script can reload in place")
	var previous_id: int = dungeon.get_surface_pieces()[0].get_instance_id()
	await _wait_for_refresh()
	_check(dungeon.get_surface_pieces()[0].get_instance_id() != previous_id,"Editor processing replaces stale generated geometry")
	var stable_id: int = dungeon.get_surface_pieces()[0].get_instance_id()
	await _wait_for_refresh()
	_check(dungeon.get_surface_pieces()[0].get_instance_id() == stable_id,"An unchanged preview is not rebuilt repeatedly")
	# The manual refresh is deferred and coalesces repeated clicks.
	dungeon.refresh_preview()
	dungeon.refresh_preview()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(dungeon.get_surface_pieces().size() == initial_count,"Manual refresh replaces rather than duplicates the scene")
	_check(_light_count(dungeon) == 2,"Manual refresh keeps exactly two torches")
	_check(dungeon.get_torch_sprites().size() == 2,"Manual refresh never duplicates torch sprites")
	_check(is_instance_valid(kept) and kept.get_parent() == dungeon,"Authored scene children survive regeneration")
	_check(is_instance_valid(heart) and dungeon.get_node_or_null("Heart") == heart,"The same heart instance survives inspector edits and script reload")
	if is_instance_valid(heart):
		_check(heart.get_child_count() == 2,"Refreshing the dungeon never duplicates the heart sprite or light")
		_check(heart.get_node("FloorLight").enabled,"Heart lighting survives dungeon regeneration")
	scene.queue_free()
	await get_tree().process_frame
	_finish()

func _wait_for_refresh() -> void:
	await get_tree().create_timer(0.7).timeout
	await get_tree().process_frame

func _light_count(dungeon: Node) -> int:
	var count := 0
	for child in dungeon.get_children():
		if child is PointLight2D:
			count += 1
	return count

func _check(condition: bool,message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	for failure in failures:
		push_error("FAIL: "+failure)
	if failures.is_empty():
		print("PASS: editor preview refresh, inspector changes, stale geometry, stable idle preview and preserved authored nodes")
	get_tree().quit(0 if failures.is_empty() else 1)
