extends "res://docs/reference/door-redesign/seal-v1/v16-segmental-frame/stage.gd"

const MATERIALS := "res://docs/reference/door-redesign/seal-v1/v17-door-materials/parts/"
var material_id := "wood"
var ajar := false
var hinge_data: Dictionary

func _part_path(file: String) -> String:
	var name_only := file.get_file()
	return MATERIALS + (material_id + "-" if file.ends_with("-panel.png") else "") + name_only

func _load_definition(reload_textures: bool) -> bool:
	if not super._load_definition(reload_textures): return false
	hinge_data = JSON.parse_string(FileAccess.get_file_as_string(MATERIALS + "../hinges.json"))
	if not ajar: return true
	for id: String in hinge_data.parts:
		var panel := id.rsplit("-",true,1)[0]
		var entry: Dictionary = _definition.entries[panel].duplicate(true)
		entry.merge(hinge_data.parts[id],true)
		_definition.entries[id] = entry
		var file := MATERIALS + material_id + "-" + id.trim_prefix("door-") + ".png"
		var img := Image.load_from_file(file)
		assert(img != null and not img.is_empty())
		_definition.textures[id] = ImageTexture.create_from_image(img)
		var companions: Array = _definition.entries[panel.trim_suffix("-panel")+"-leaf"].companions
		companions.erase(panel)
		companions.append(id)
	return true

