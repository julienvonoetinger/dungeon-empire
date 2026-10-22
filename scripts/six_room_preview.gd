extends Node2D

@onready var dungeon = $Dungeon
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	if dungeon.has_signal("rebuilt"):
		dungeon.rebuilt.connect(_fit)
	_fit()

func _fit() -> void:
	var bounds: Rect2 = dungeon.get_content_rect()
	var available := get_viewport_rect().size
	camera.position = bounds.get_center()
	camera.zoom = Vector2.ONE * minf(available.x/bounds.size.x,available.y/bounds.size.y)
	camera.force_update_scroll()
