extends SceneTree

const APK := "res://artifacts/android/dungeon-empire-debug.apk"
const MANIFEST := "res://tools/android/mobile-texture-budget-manifest.json"
var entries: Dictionary = {}
var records: Dictionary = {}
var changed := 0
var inspected := 0
var failed := false


func _initialize() -> void:
	if "--verify" in OS.get_cmdline_user_args():
		_verify()
		return
	var zip := ZIPReader.new()
	if zip.open(ProjectSettings.globalize_path(APK)) != OK:
		printerr("A prior APK is required to identify the exported texture dependencies.")
		quit(1)
		return
	for path in zip.get_files():
		entries[path] = true
	zip.close()
	if FileAccess.file_exists(MANIFEST):
		var previous = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if previous is Dictionary:
			records = previous.get("files", {})
	for directory in ["res://assets/models", "res://production/textures", "res://assets/mobile"]:
		_scan(directory)
	var output := FileAccess.open(MANIFEST, FileAccess.WRITE)
	if output == null:
		printerr("Cannot write texture budget manifest.")
		quit(1)
		return
	output.store_string(JSON.stringify({"files": records}, "\t", true) + "\n")
	output.close()
	print("Texture budget: %d exported textures inspected, %d imports changed. Manifest: %s" % [inspected, changed, MANIFEST])
	quit(1 if failed else 0)


func _verify() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not manifest is Dictionary:
		printerr("Missing texture budget manifest.")
		quit(1)
		return
	var count := 0
	for path in manifest.get("files", {}):
		var config := ConfigFile.new()
		if config.load(path) != OK:
			failed = true
			continue
		for key in manifest.files[path]:
			if config.get_value("params", key) != manifest.files[path][key].after:
				printerr("Budget setting changed: ", path, " ", key)
				failed = true
		var texture = load(str(path).trim_suffix(".import"))
		var limit := int(config.get_value("params", "process/size_limit", 0))
		if not texture is Texture2D or maxi(texture.get_width(), texture.get_height()) > limit:
			printerr("Imported texture exceeds budget: ", path)
			failed = true
		var etc2 := str(config.get_value("remap", "path.etc2", ""))
		if etc2.is_empty() or not FileAccess.file_exists(etc2):
			printerr("Missing ETC2 import: ", path)
			failed = true
		count += 1
	print("Verified dimensions, settings and ETC2 imports for %d budgeted textures." % count)
	quit(1 if failed else 0)


func _scan(directory: String) -> void:
	for child in DirAccess.get_directories_at(directory):
		_scan(directory.path_join(child))
	for filename in DirAccess.get_files_at(directory):
		if filename.ends_with(".import"):
			_budget(directory.path_join(filename))


func _budget(path: String) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK or config.get_value("remap", "importer", "") != "texture":
		return
	var exported := false
	for destination in config.get_value("deps", "dest_files", []):
		if entries.has("assets/" + str(destination).trim_prefix("res://")):
			exported = true
	if not exported:
		return
	inspected += 1
	var is_ui := path.begins_with("res://assets/mobile/")
	var is_world_atlas := path.get_file() in ["command-atlas-v1.png.import", "core-monument-v1.png.import"]
	var limit := 512 if "metallic" in path or "roughness" in path else 1024
	var existing := int(config.get_value("params", "process/size_limit", 0))
	if existing > 0:
		limit = mini(limit, existing)
	var settings := {
		"process/size_limit": limit,
		"compress/mode": 2,
		"compress/high_quality": false,
		"mipmaps/generate": not is_ui or is_world_atlas,
	}
	var differences: Dictionary = records.get(path, {}).duplicate(true)
	var dirty := false
	for key in settings:
		var before = config.get_value("params", key, null)
		if before == settings[key]:
			continue
		if not differences.has(key):
			differences[key] = {"before": before, "after": settings[key]}
		else:
			differences[key]["after"] = settings[key]
		config.set_value("params", key, settings[key])
		dirty = true
	if dirty:
		if config.save(path) != OK:
			printerr("Cannot update import: ", path)
			failed = true
			return
		records[path] = differences
		changed += 1
