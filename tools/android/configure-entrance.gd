extends SceneTree

func _initialize() -> void:
	var path := "res://assets/mobile/entrance-arch-v2.png"
	var texture := ConfigFile.new()
	assert(texture.load(path + ".import") == OK)
	texture.set_value("params", "process/size_limit", 1024)
	texture.set_value("params", "mipmaps/generate", true)
	assert(texture.save(path + ".import") == OK)
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var roots: PackedStringArray = config.get_value(section, "export_files")
		for asset in [path, "res://scripts/world/mobile_entrance.gd"]:
			if not roots.has(asset):
				roots.append(asset)
		roots.sort()
		config.set_value(section, "export_files", roots)
	config.set_value("preset.2.options", "version/code", 8)
	config.set_value("preset.2.options", "version/name", "0.1.7-entrance")
	assert(config.save("res://export_presets.cfg") == OK)
	print("Entrance texture capped at 1024px; Vulkan 0.1.7-entrance")
	quit()
