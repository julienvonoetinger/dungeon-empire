extends SceneTree

const PROFILE_PATH := "res://assets/rendering/dungeon_render_profile.tres"
const PROFILE_SCRIPT := preload("res://scripts/world/dungeon_render_profile.gd")

func _initialize() -> void:
	var profile = load(PROFILE_PATH)
	assert(profile != null and profile.get_script() == PROFILE_SCRIPT, "render profile must use DungeonRenderProfile")
	assert(profile.max_practical_lights == 12, "PC practical-light budget changed")
	var env := Environment.new()
	profile.apply_to_environment(env)
	assert(env.ambient_light_energy <= 0.30, "ambient energy is too strong")
	assert(env.background_color.b < 0.16, "background is too violet/blue")
	assert(env.tonemap_mode == Environment.TONE_MAPPER_FILMIC, "filmic tonemapping is required")
	print("OK: render profile")
	quit()
