extends Node3D

const RENDER_PROFILE := preload("res://assets/rendering/dungeon_render_profile.tres")

@onready var world_environment: WorldEnvironment = $Environment
@onready var cool_key: DirectionalLight3D = $CoolKey
@onready var torch_light: OmniLight3D = $TorchLight
@onready var core_light: OmniLight3D = $CoreLight

func _ready() -> void:
	RENDER_PROFILE.apply_to_environment(world_environment.environment)
	RENDER_PROFILE.configure_key(cool_key)
	RENDER_PROFILE.configure_practical(torch_light)
	RENDER_PROFILE.configure_core(core_light)
