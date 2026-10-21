extends Node2D

@onready var dungeon: DungeonView = $Dungeon
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_scene)
	_fit_scene()


func _fit_scene() -> void:
	var bounds := dungeon.get_content_rect()
	var viewport_size := get_viewport_rect().size
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return
	var fit := minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y)
	camera.position = bounds.get_center()
	camera.zoom = Vector2.ONE * fit
	camera.force_update_scroll()
