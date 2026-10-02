extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var roots: PackedStringArray = config.get_value(section, "export_files")
		var path := "res://scripts/world/mobile_backdrop.gd"
		if not roots.has(path):
			roots.append(path)
		roots.sort()
		config.set_value(section, "export_files", roots)
	config.set_value("preset.2.options", "version/code", 10)
	config.set_value("preset.2.options", "version/name", "0.1.9-backdrop")
	assert(config.save("res://export_presets.cfg") == OK)
	quit()
