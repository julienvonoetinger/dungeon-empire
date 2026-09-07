extends SceneTree

const SCENE_PATH := "res://scenes/render_lab/RenderLab.tscn"
const REQUIRED_NODES := [
	"Camera3D",
	"Environment",
	"CoolKey",
	"CoreLight",
	"Floor",
	"Walls",
	"Torch",
	"Vault",
	"Core",
	"HeroProxy",
]

func _initialize() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	assert(packed != null, "RenderLab scene must load")
	var lab := packed.instantiate()
	root.add_child(lab)
	for node_name in REQUIRED_NODES:
		assert(lab.find_child(node_name, true, false) != null, "missing RenderLab node: %s" % node_name)
	var camera := lab.find_child("Camera3D", true, false) as Camera3D
	assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "RenderLab camera must be orthographic")
	var directional_count := 0
	var omni_count := 0
	for node in lab.find_children("*", "Light3D", true, false):
		if node is DirectionalLight3D:
			directional_count += 1
		elif node is OmniLight3D:
			omni_count += 1
	assert(directional_count == 1, "RenderLab must have exactly one directional key")
	assert(omni_count <= 12, "RenderLab exceeds the practical-light budget")
	print("OK: RenderLab loads")
	quit()
