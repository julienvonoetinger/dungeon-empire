extends RefCounted

const LIMIT := 90
var previous: Array = []
var current: Array = []
var _path := ""

func begin(path: String) -> Error:
	_path = path
	previous = []
	current = []
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			var samples = data.get("current", [])
			if not samples is Array or samples.is_empty():
				samples = data.get("previous", [])
			if samples is Array:
				previous = samples.slice(maxi(0, samples.size() - LIMIT))
	return _save()

func append(sample: Dictionary) -> Error:
	current.append(sample.duplicate(true))
	if current.size() > LIMIT:
		current.pop_front()
	return _save()

func export_previous() -> String:
	return JSON.stringify({"format": "dungeon-memory-v2", "session": "previous", "samples": previous})

func export_current() -> String:
	return JSON.stringify({"format": "dungeon-memory-v2", "session": "current", "samples": current})

func _save() -> Error:
	var temporary := _path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"previous": previous, "current": current}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Replace only a complete, flushed snapshot, retaining the prior one on failure.
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(_path))

static func rss_bytes(status: String) -> int:
	for line in status.split("\n"):
		if line.begins_with("VmRSS:"):
			var fields := line.substr(6).strip_edges().split(" ", false)
			if fields.size() == 2 and fields[0].is_valid_int() and fields[1] == "kB":
				return int(fields[0]) * 1024
	return -1
