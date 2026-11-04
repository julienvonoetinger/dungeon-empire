extends Node3D
## Skeletal Meshy model, sampled only from the preview clock.
const MODEL = preload("res://assets/previews/wraith-master/wraith-levitation.glb")
var model: Node3D
var player: AnimationPlayer
var clip: StringName
var clock := 0.0

func _ready() -> void:
	model = MODEL.instantiate()
	add_child(model)
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	for name in player.get_animation_list():
		if name != &"RESET":
			clip = name
			break
	assert(not clip.is_empty())
	player.get_animation(clip).loop_mode = Animation.LOOP_NONE
	player.play(clip)
	player.pause()
	present(0.0)

func present(time: float) -> void:
	if not is_instance_valid(player): return
	clock = clampf(time, 0.0, 6.0)
	player.seek(clock, true)
