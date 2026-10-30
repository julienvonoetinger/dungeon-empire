extends SceneTree
## Pack accepted registration data as a resource dependency (no JSON/doc files
## required by exports). Does not alter or duplicate the painted sprite sheets.
func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
func _initialize() -> void:
	var data := Resource.new()
	for state in ["lockpick", "chest-lockpick", "chest-open"]:
		data.set_meta(state.replace("-", "_"), read_json("res://assets/previews/vulpin-"+state+"/registration.json"))
	var bounds := {}
	for sample in read_json("res://docs/reference/door-redesign/seal-v1/hero-fit-v11-compact/passage-validation.json").samples:
		if not bounds.has(sample.kind): bounds[sample.kind] = {}
		bounds[sample.kind][int(sample.pose)] = sample.bounds
	data.set_meta("bounds", bounds)
	DirAccess.make_dir_recursive_absolute("res://assets/heroes/vulpin")
	var error := ResourceSaver.save(data, "res://assets/heroes/vulpin/registration.tres")
	print("Registration resource: ",error)
	quit(error)
