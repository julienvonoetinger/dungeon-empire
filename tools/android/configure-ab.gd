extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	var roots: PackedStringArray = config.get_value("preset.0", "export_files")
	var diagnostics := "res://scripts/mobile/mobile_diagnostics.gd"
	if not roots.has(diagnostics):
		roots.append(diagnostics)
		roots.sort()
	config.set_value("preset.0", "export_files", roots)
	for index in [1, 2]:
		var section := "preset.%d" % index
		var title := "Android OpenGL Probe" if index == 1 else "Android Vulkan Probe"
		assert(not config.has_section(section) or config.get_value(section, "name") == title,
			"Refuse to overwrite an unrelated export preset")
		for suffix in ["", ".options"]:
			for key in config.get_section_keys("preset.0" + suffix):
				config.set_value(section + suffix, key, config.get_value("preset.0" + suffix, key))
		var backend := "opengl" if index == 1 else "vulkan"
		config.set_value(section, "name", title)
		config.set_value(section, "runnable", false)
		config.set_value(section, "export_path", "artifacts/android/dungeon-empire-%s-probe.apk" % backend)
		config.set_value(section + ".options", "version/code", 3)
		config.set_value(section + ".options", "version/name", "0.1.2-" + backend)
		config.set_value(section + ".options", "command_line/extra_args",
			"--rendering-method gl_compatibility --rendering-driver opengl3" if index == 1
			else "--rendering-method mobile --rendering-driver vulkan")
	assert(config.save("res://export_presets.cfg") == OK)
	print("A/B export presets configured; original renderer unchanged")
	quit()
