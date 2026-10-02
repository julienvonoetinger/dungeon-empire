extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var files: PackedStringArray = config.get_value(section, "export_files")
		var path := "res://scripts/world/jump_motion.gd"
		if not files.has(path):
			files.append(path)
		files.sort()
		config.set_value(section, "export_files", files)
	config.set_value("preset.2.options", "version/code", 15)
	config.set_value("preset.2.options", "version/name", "0.2.4-jump")
	assert(config.save("res://export_presets.cfg") == OK)
	quit()
