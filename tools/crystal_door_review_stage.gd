extends "res://tools/integrated_compact_door_stage.gd"
## Review textures only, loaded outside the runtime resource cache.
const PROPOSAL="res://docs/reference/door-redesign/seal-v1/hero-fit-v15-iron-crystals/"
var use_proposal:=true
func _load_definition(reload_textures: bool) -> bool:
	if not super._load_definition(reload_textures): return false
	if opened: return true
	_definition=_definition.duplicate(true)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PROPOSAL+("preview-catalog.json" if use_proposal else "previous-catalog.json")))
	for id: String in data:
		_definition.entries[id]=data[id].duplicate(true)
		_definition.textures[id]=ImageTexture.create_from_image(Image.load_from_file(PROPOSAL+data[id].file))
	return true
