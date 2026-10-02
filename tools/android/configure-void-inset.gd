extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	var textures := ["floor-pavers", "void-armed", "void-active", "void-broken"]
	for name in textures:
		var path := "res://assets/mobile/%s-v3.png" % name
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert(image != null and image.get_width() == image.get_height())
		if name.begins_with("void"):
			assert(image.get_pixel(0, 0).a < 0.01, "Void exterior must be transparent")
			assert(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.98, "Void center must retain near-opaque artwork for alpha scissoring")
		var imported := ConfigFile.new()
		assert(imported.load(path + ".import") == OK)
		imported.set_value("params", "process/size_limit", 1024 if name == "floor-pavers" else 512)
		imported.set_value("params", "mipmaps/generate", true)
		assert(imported.save(path + ".import") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var files: PackedStringArray = config.get_value(section, "export_files")
		for name in textures:
			files.erase("res://assets/mobile/%s-v2.png" % name)
			var path := "res://assets/mobile/%s-v3.png" % name
			if not files.has(path):
				files.append(path)
		var shader := "res://assets/rendering/void_floor.gdshader"
		if not files.has(shader):
			files.append(shader)
		files.sort()
		config.set_value(section, "export_files", files)
	config.set_value("preset.2.options", "version/code", 20)
	config.set_value("preset.2.options", "version/name", "0.2.9-void-inset")
	assert(config.save("res://export_presets.cfg") == OK)
	print("OK: v3 texture alpha, import caps and export selection")
	quit()
