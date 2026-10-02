extends SceneTree

func _initialize() -> void:
	var path := "res://assets/mobile/spike-floor-v1.png"
	var imported := ConfigFile.new()
	assert(imported.load(path + ".import") == OK)
	imported.set_value("params", "process/size_limit", 512)
	imported.set_value("params", "mipmaps/generate", true)
	assert(imported.save(path + ".import") == OK)
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var selected: PackedStringArray = config.get_value(section, "export_files")
		if not selected.has(path):
			selected.append(path)
		config.set_value(section, "export_files", selected)
	assert(config.save("res://export_presets.cfg") == OK)
	quit()
