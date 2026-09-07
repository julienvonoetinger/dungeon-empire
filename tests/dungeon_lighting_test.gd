extends SceneTree

const PROFILE := preload("res://assets/rendering/dungeon_render_profile.tres")

func _initialize() -> void:
	var main_script: GDScript = load("res://scripts/Main.gd")
	var game: Node = main_script.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	game._sync_world()
	var directional_count := 0
	var omni_count := 0
	for node in game.dungeon.find_children("*", "", true, false):
		if node is DirectionalLight3D:
			directional_count += 1
		elif node is OmniLight3D:
			omni_count += 1
	print("lights: directional=", directional_count, " omni=", omni_count)
	assert(directional_count == 1, "dungeon must use one cool directional key")
	assert(omni_count <= PROFILE.max_practical_lights + 1, "dungeon exceeds practical lights plus Core")
	assert(game.dungeon.practical_light_count() <= PROFILE.max_practical_lights, "practical-light budget exceeded")
	print("OK: dungeon lighting is bounded")
	quit()
