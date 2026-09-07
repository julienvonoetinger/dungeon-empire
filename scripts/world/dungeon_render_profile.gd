class_name DungeonRenderProfile
extends Resource

@export_group("Environment")
@export var background_color := Color("#17161B")
@export var ambient_color := Color("#303540")
@export_range(0.0, 2.0, 0.01) var ambient_energy := 0.22
@export_range(0.1, 4.0, 0.01) var exposure := 1.05
@export var fog_enabled := true
@export var fog_color := Color("#17161B")
@export_range(0.0, 1.0, 0.001) var fog_density := 0.012

@export_group("Cool Key")
@export var key_color := Color("#A9B8D2")
@export_range(0.0, 8.0, 0.01) var key_energy := 0.72
@export var key_rotation_degrees := Vector3(-52.0, -38.0, 0.0)
@export_range(0.0, 1.0, 0.01) var key_shadow_opacity := 0.72

@export_group("Warm Practicals")
@export var practical_color := Color("#F0A64A")
@export_range(0.0, 8.0, 0.01) var practical_energy := 1.65
@export_range(0.1, 20.0, 0.1) var practical_range := 3.2
@export_range(0, 64, 1) var max_practical_lights := 12

@export_group("Dungeon Core")
@export var core_color := Color("#9B4DB5")
@export_range(0.0, 8.0, 0.01) var core_energy := 1.15
@export_range(0.1, 20.0, 0.1) var core_range := 4.2

func apply_to_environment(env: Environment) -> void:
	env.background_mode = Environment.BG_COLOR
	env.background_color = background_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = exposure
	env.fog_enabled = fog_enabled
	env.fog_light_color = fog_color
	env.fog_density = fog_density

func configure_key(light: DirectionalLight3D) -> void:
	light.light_color = key_color
	light.light_energy = key_energy
	light.rotation_degrees = key_rotation_degrees
	light.shadow_enabled = true
	light.shadow_opacity = key_shadow_opacity

func configure_practical(light: OmniLight3D) -> void:
	light.light_color = practical_color
	light.light_energy = practical_energy
	light.omni_range = practical_range
	light.shadow_enabled = true

func configure_core(light: OmniLight3D) -> void:
	light.light_color = core_color
	light.light_energy = core_energy
	light.omni_range = core_range
	light.shadow_enabled = false
