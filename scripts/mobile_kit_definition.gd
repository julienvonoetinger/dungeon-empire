extends Resource
## Offline atlas entries: pixels are already projected and padded.
# Defaults preserve historical review catalogues. The active catalogue supplies
# the approved isometric vectors explicitly.
@export var projection_x := Vector3(1, 0, -.18)
@export var projection_y := Vector3(0, 1, -.9)
@export var view_direction := Vector3(.18, .9, 1)
@export var entries: Dictionary = {}
@export var textures: Dictionary = {}
