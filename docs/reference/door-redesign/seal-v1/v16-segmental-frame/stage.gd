extends "res://tools/integrated_compact_door_stage.gd"

const STUDY := "res://docs/reference/door-redesign/seal-v1/v16-segmental-frame/"

func _part_path(file: String) -> String:
	return STUDY + file

func _load_definition(reload_textures: bool) -> bool:
	if not super._load_definition(reload_textures): return false
	if revision == "current": return true
	_definition = _definition.duplicate(true)
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STUDY + "parts.json"))
	for id: String in entries:
		var meta: Dictionary = entries[id]
		var entry: Dictionary = _definition.entries[id].duplicate(true)
		for key in ["offset","size","bounds"]: entry[key] = meta[key]
		if id.ends_with("-leaf"):
			var prefix := id.trim_suffix("-leaf")
			# The intact wall supports the frame. The production door's cut is unnecessary here.
			entry.erase("wall_junction")
			entry.companions = [prefix + "-jamb-right"]
			if not opened: entry.companions.append(prefix + "-panel")
		_definition.entries[id] = entry
		var img := Image.load_from_file(_part_path(meta.file))
		assert(img != null and not img.is_empty())
		_definition.textures[id] = ImageTexture.create_from_image(img)
	return true
