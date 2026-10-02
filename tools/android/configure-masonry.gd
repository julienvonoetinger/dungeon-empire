extends SceneTree

func _initialize() -> void:
	var assets := PackedStringArray([
		"res://assets/mobile/masonry-grain-v2.png",
		"res://assets/mobile/floor-pavers-v2.png",
	])
	for path in assets:
		var texture := ConfigFile.new()
		assert(texture.load(path + ".import") == OK)
		texture.set_value("params", "process/size_limit", 1024)
		texture.set_value("params", "mipmaps/generate", true)
		assert(texture.save(path + ".import") == OK)
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var roots: PackedStringArray = config.get_value(section, "export_files")
		for path in assets:
			if not roots.has(path):
				roots.append(path)
		roots.sort()
		config.set_value(section, "export_files", roots)
	config.set_value("preset.2.options", "version/code", 7)
	config.set_value("preset.2.options", "version/name", "0.1.6-masonry")
	assert(config.save("res://export_presets.cfg") == OK)
	print("Masonry textures: 1024px mipmaps; Vulkan 0.1.6-masonry")
	quit()
