extends SceneTree

const VIEW_PATHS := [
	"res://production/meshy_assets/characters/heroes/hero_nocturne_priest_front.png",
	"res://production/meshy_assets/characters/heroes/hero_nocturne_priest_back.png",
	"res://production/meshy_assets/characters/heroes/hero_nocturne_priest_left.png",
	"res://production/meshy_assets/characters/heroes/hero_nocturne_priest_right.png",
	"res://production/meshy_assets/characters/heroes/hero_nocturne_priest_wings.png",
]

var failures := 0


func _initialize() -> void:
	for path in VIEW_PATHS:
		_check(FileAccess.file_exists(path), path + " must exist")
		_check(ResourceLoader.exists(path), path + " must import as a Godot resource")
	if failures == 0:
		print("OK: Nocturne Priest has wingless production views and isolated wings")
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
