extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for path in ["res://assets/mobile/chest-full-v3.png", "res://assets/mobile/chest-empty-v3.png", "res://assets/mobile/treasury-floor-v1.png", "res://assets/mobile/treasury-floor-empty-v1.png"]:
		var imported := ConfigFile.new()
		assert(imported.load(path + ".import") == OK)
		imported.set_value("params", "process/size_limit", 512)
		imported.set_value("params", "mipmaps/generate", true)
		assert(imported.save(path + ".import") == OK)
		for section in ["preset.0", "preset.1", "preset.2"]:
			var selected: PackedStringArray = config.get_value(section, "export_files")
			if not selected.has(path):
				selected.append(path)
			config.set_value(section, "export_files", selected)
	assert(config.save("res://export_presets.cfg") == OK)
	quit()
