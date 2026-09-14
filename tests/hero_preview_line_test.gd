extends SceneTree

const MainScript := preload("res://scripts/Main.gd")


func _initialize() -> void:
	var game: Node = MainScript.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	game.dungeon.sync(game)

	var previews := _hero_previews(game.dungeon)
	if not _check(previews.size() == 6, "hero preview line must show one static sample per hero archetype"):
		return
	for expected in ["LithidePaladinPreview", "VulpinThiefPreview", "MyceanMagePreview", "BatrafianRangerPreview", "NocturnePriestPreview", "SaurianScalelordPreview"]:
		if not _check(previews.has(expected), "missing hero preview: " + expected):
			return
	for preview in previews.values():
		var node := preview as Node3D
		if not _check(node.visible, node.name + " must be visible for visual inspection"):
			return
		if not _check(_is_outside_dungeon(node.position, game), node.name + " must sit outside the dungeon board"):
			return
		if not _check(node.has_method("set_preview_pose"), node.name + " must expose a dedicated preview pose"):
			return
		if not _check(_shows_preview_action(node), node.name + " preview must show its action model"):
			return
		if not _check(_has_no_playing_animation(node), node.name + " preview must keep its inspection animation stopped"):
			return
	if not _check(_has_preview_light(game.dungeon), "hero preview line must include dedicated inspection lighting"):
		return

	print("OK: hero preview line shows static archetypes outside the dungeon")
	quit()


func _hero_previews(dungeon: Node) -> Dictionary:
	var result := {}
	var root_node: Node = dungeon.get_node_or_null("HeroPreviewLine")
	if root_node == null:
		return result
	for child in root_node.get_children():
		if child is Node3D and String(child.name).ends_with("Preview"):
			result[child.name] = child
	return result


func _is_outside_dungeon(pos: Vector3, game: Node) -> bool:
	return pos.x < -0.5 or pos.z < -0.5 or pos.x > float(game.COLS) + 0.5 or pos.z > float(game.ROWS) + 0.5


func _shows_preview_action(root_node: Node) -> bool:
	var expected := {
		"LithidePaladinPreview": "Attack",
		"VulpinThiefPreview": "Lockpicking",
		"MyceanMagePreview": "Casting",
		"BatrafianRangerPreview": "Attack",
		"NocturnePriestPreview": "Casting",
		"SaurianScalelordPreview": "Attack",
	}
	var action_name := String(expected.get(String(root_node.name), ""))
	var action := root_node.find_child(action_name, true, false) as Node3D
	return action != null and action.visible


func _has_no_playing_animation(root_node: Node) -> bool:
	for player in root_node.find_children("*", "AnimationPlayer", true, false):
		var animation_player := player as AnimationPlayer
		if animation_player.is_playing():
			return false
	return true


func _has_preview_light(dungeon: Node) -> bool:
	var root_node: Node = dungeon.get_node_or_null("HeroPreviewLine")
	if root_node == null:
		return false
	var light := root_node.get_node_or_null("PreviewInspectionLight") as OmniLight3D
	var saurian_light := root_node.get_node_or_null("SaurianPreviewInspectionLight") as OmniLight3D
	return light != null and light.visible and light.light_energy >= 4.8 and light.omni_range >= 10.0 \
			and saurian_light != null and saurian_light.visible \
			and saurian_light.light_energy >= 5.4 and saurian_light.omni_range >= 5.0


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: " + message)
	quit(1)
	return false
