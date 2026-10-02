extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	var main := "res://assets/mobile/app-icon-v1.png"
	var adaptive := "res://assets/mobile/app-icon-adaptive-v1.png"
	for path in [main, adaptive]:
		var image := Image.load_from_file(path)
		assert(image != null and image.get_width() == image.get_height())
	for section in ["preset.0", "preset.1", "preset.2"]:
		var files: PackedStringArray = config.get_value(section, "export_files")
		for path in [main, adaptive]:
			if not files.has(path):
				files.append(path)
		files.sort()
		config.set_value(section, "export_files", files)
		config.set_value(section + ".options", "launcher_icons/main_192x192", main)
		config.set_value(section + ".options", "launcher_icons/adaptive_foreground_432x432", adaptive)
		config.set_value(section + ".options", "launcher_icons/adaptive_background_432x432", adaptive)
	config.set_value("preset.2.options", "version/code", 17)
	config.set_value("preset.2.options", "version/name", "0.2.6-icon")
	assert(config.save("res://export_presets.cfg") == OK)
	quit()
