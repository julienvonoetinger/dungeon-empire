extends SceneTree

const VisualProbes := preload("res://tests/probes/dungeon_visual_probes.gd")
const PROFILE := preload("res://assets/rendering/dungeon_render_profile.tres")

func _initialize() -> void:
	var main_script: GDScript = load("res://scripts/Main.gd")
	var game: Node = main_script.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	if not game._has_core():
		game._place_core(GameTypes.core_origin_cell())
	# Main skips visual synchronization in headless mode; exercise the renderer directly.
	game.dungeon.sync(game)
	var lights := VisualProbes.light_report(game.dungeon)
	var directional_count := int(lights["directional"])
	var omni_count := int(lights["omni"])
	print("lights: directional=", directional_count, " omni=", omni_count)
	assert(directional_count == 1, "dungeon must use one cool directional key")
	assert(omni_count > 1, "starting room must contain lit wall torches")
	assert(omni_count <= PROFILE.max_practical_lights + 1, "dungeon exceeds practical lights plus Core")
	assert(game.dungeon.practical_light_count() <= PROFILE.max_practical_lights, "practical-light budget exceeded")
	var core_light: OmniLight3D = game.dungeon._fill
	var core_visual: Node3D = game.dungeon._core_spin
	assert(core_light.global_position.distance_to(core_visual.global_position) < 1.0, "Core light must follow the Core world position")
	var fixtures_before := VisualProbes.child_global_transforms(game.dungeon._torch_rig)
	for pan in [Vector2(800, 400), Vector2(-800, -400), Vector2.ZERO]:
		game.cam_pan = pan
		game.cam_yaw += 90.0
		game.dungeon.sync(game)
		if VisualProbes.child_global_transforms(game.dungeon._torch_rig) != fixtures_before:
			printerr("FAIL: moving the camera must preserve every torch instance and world transform")
			quit(1)
			return
	print("OK: dungeon lighting is bounded and torches stay fixed during camera movement")
	quit()
