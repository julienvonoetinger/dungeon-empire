extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	var textures := ["res://assets/mobile/floor-pavers-v4.png", "res://assets/mobile/bedrock-v2.png", "res://assets/models/walls/entrance_rock_arch_v1_0.jpg"]
	var rock_resources := ["res://scripts/world/mobile_rock_library.gd", "res://assets/mobile/entrance-rock-v1.res", "res://assets/rendering/entrance_stone.gdshader"]
	for i in 6:
		rock_resources.append("res://assets/mobile/rocks/rock_%d.res" % i)
		rock_resources.append("res://assets/mobile/rocks/rock_%d_far.res" % i)
	for texture in textures:
		var imported := ConfigFile.new()
		assert(imported.load(texture + ".import") == OK)
		imported.set_value("params", "process/size_limit", 1024)
		imported.set_value("params", "mipmaps/generate", true)
		assert(imported.save(texture + ".import") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var files: PackedStringArray = config.get_value(section, "export_files")
		for path in textures + rock_resources + ["res://scripts/world/mobile_geology.gd", "res://assets/rendering/rock_strata.gdshader"]:
			if not files.has(path):
				files.append(path)
		files.sort()
		config.set_value(section, "export_files", files)
	config.set_value("preset.2.options", "version/code", 26)
	config.set_value("preset.2.options", "version/name", "0.2.15-environment")
	assert(config.save("res://export_presets.cfg") == OK)
	print("OK: continuous geology and fine paving selected for Android")
	quit()
