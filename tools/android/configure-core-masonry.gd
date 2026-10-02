extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	var additions := PackedStringArray(["res://assets/rendering/core_masonry.gdshader"])
	for name in ["core-monument", "core-damaged", "core-destroyed"]:
		var path := "res://assets/mobile/%s-v2.png" % name
		additions.append(path)
		var imported := ConfigFile.new()
		assert(imported.load(path + ".import") == OK)
		imported.set_value("params", "process/size_limit", 1024)
		imported.set_value("params", "mipmaps/generate", true)
		assert(imported.save(path + ".import") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var files: PackedStringArray = config.get_value(section, "export_files")
		for path in additions:
			if not files.has(path):
				files.append(path)
		files.sort()
		config.set_value(section, "export_files", files)
	config.set_value("preset.2.options", "version/code", 24)
	config.set_value("preset.2.options", "version/name", "0.2.13-core")
	assert(config.save("res://export_presets.cfg") == OK)
	print("OK: masonry Core images and shader selected")
	quit()
