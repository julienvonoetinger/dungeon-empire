extends SceneTree

func _initialize() -> void:
	var script_path := "res://scripts/mobile/mobile_diagnostics.gd"
	if not ResourceLoader.exists(script_path):
		printerr("FAIL: persistent diagnostic store missing")
		quit(1)
		return
	var store_script = load(script_path)
	var path := "user://diagnostic_store_test_%d.json" % OS.get_process_id()
	var store = store_script.new()
	assert(store.begin(path) == OK)
	assert(store.previous.is_empty())
	for index in 100:
		assert(store.append({"frame": index}) == OK)
	assert(store.current.size() == store.LIMIT)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(saved.current.back().frame == 99)
	var restarted = store_script.new()
	assert(restarted.begin(path) == OK)
	assert(restarted.previous.back().frame == 99)
	assert(restarted.current.is_empty())
	assert(JSON.parse_string(restarted.export_previous()).samples.size() == store.LIMIT)
	assert(restarted.append({"frame": 101}) == OK)
	assert(restarted.previous.back().frame == 99)
	assert(store_script.rss_bytes("Name:\ttest\nVmRSS:\t2048 kB\nVmSize:\t99999 kB") == 2097152)
	assert(store_script.rss_bytes("Name:\ttest") == -1)
	assert(store_script.rss_bytes("VmRSS:\tnonsense kB") == -1)
	var third = store_script.new()
	assert(third.begin(path) == OK)
	assert(third.previous.back().frame == 101)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var failed = store_script.new()
	assert(failed.begin("user://nonexistent_diagnostic_test_directory/session.json") != OK)
	print("Persistent diagnostics test passed")
	quit()
