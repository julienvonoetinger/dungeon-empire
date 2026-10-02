extends SceneTree

func _initialize() -> void:
	var files := ["res://assets/mobile/gothic-door-frame.res", "res://assets/mobile/gothic-door-leaf.res", "res://scripts/world/mobile_gothic_door.gd"]
	for part in ["frame", "leaf"]:
		var texture := "res://assets/models/doors/door_gothic_%s_v1_0.jpg" % part
		var imported := ConfigFile.new()
		assert(imported.load(texture + ".import") == OK)
		imported.set_value("params", "process/size_limit", 1024)
		imported.set_value("params", "mipmaps/generate", true)
		assert(imported.save(texture + ".import") == OK)
		files.append(texture)
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	for section in ["preset.0", "preset.1", "preset.2"]:
		var selected: PackedStringArray = config.get_value(section, "export_files")
		for file in files:
			if not selected.has(file):
				selected.append(file)
		selected.sort()
		config.set_value(section, "export_files", selected)
	assert(config.save("res://export_presets.cfg") == OK)
	print("OK: gothic door resources selected; two albedo textures capped at 1024")
	quit()
