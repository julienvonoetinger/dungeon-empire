extends SceneTree

func _initialize() -> void:
	var assets := PackedStringArray([
		"res://assets/mobile/spike-active-v2.png",
		"res://assets/mobile/spike-broken-v2.png",
		"res://assets/mobile/spike-armed-v2.png",
		"res://assets/mobile/spikes-icon-v2.png",
	])
	for path in assets:
		var texture := ConfigFile.new()
		assert(texture.load(path + ".import") == OK)
		texture.set_value("params", "process/size_limit", 512)
		texture.set_value("params", "mipmaps/generate", true)
		assert(texture.save(path + ".import") == OK)
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var roots: PackedStringArray = config.get_value(section, "export_files")
		for path in assets + PackedStringArray(["res://scripts/world/mobile_spines.gd"]):
			if not roots.has(path):
				roots.append(path)
		roots.sort()
		config.set_value(section, "export_files", roots)
	assert(config.get_value("preset.2", "name") == "Android Vulkan Probe")
	config.set_value("preset.2.options", "version/code", 5)
	config.set_value("preset.2.options", "version/name", "0.1.4-spines")
	assert(config.save("res://export_presets.cfg") == OK)
	print("Spine textures limited to 512px; Vulkan APK version 0.1.4-spines")
	quit()
