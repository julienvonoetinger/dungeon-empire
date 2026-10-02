extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	var additions := PackedStringArray(["res://scripts/world/mobile_door.gd", "res://assets/rendering/door_leaves.gdshader"])
	for name in ["door-leaves", "door-sealed", "door-damaged", "door-sealed-damaged"]:
		var path := "res://assets/mobile/%s-v3.png" % name
		additions.append(path)
		var imported := ConfigFile.new()
		assert(imported.load(path + ".import") == OK)
		imported.set_value("params", "process/size_limit", 512)
		imported.set_value("params", "mipmaps/generate", true)
		assert(imported.save(path + ".import") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var files: PackedStringArray = config.get_value(section, "export_files")
		for path in additions:
			if not files.has(path):
				files.append(path)
		files.sort()
		config.set_value(section, "export_files", files)
	config.set_value("preset.2.options", "version/code", 23)
	config.set_value("preset.2.options", "version/name", "0.2.12-doors")
	assert(config.save("res://export_presets.cfg") == OK)
	print("OK: integrated door textures and module selected for Android")
	quit()
