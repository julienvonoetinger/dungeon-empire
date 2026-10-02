extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	config.set_value("preset.2.options", "version/code", 9)
	config.set_value("preset.2.options", "version/name", "0.1.8-restart")
	assert(config.save("res://export_presets.cfg") == OK)
	quit()
