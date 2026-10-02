extends SceneTree

func _initialize() -> void:
	var path := "res://assets/mobile/door-front-icon-v1.png"
	var imported := ConfigFile.new()
	assert(imported.load(path + ".import") == OK)
	imported.set_value("params", "process/size_limit", 256)
	imported.set_value("params", "mipmaps/generate", true)
	assert(imported.save(path + ".import") == OK)
	quit()
