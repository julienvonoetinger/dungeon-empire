extends SceneTree
var failures := 0
var scenes := 0
func _initialize() -> void: run.call_deferred()
func scan(folder: String) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".tscn"):
			scenes += 1
			if ResourceLoader.load(folder.path_join(file)) == null:
				failures += 1
				print("FAIL: Cannot load ", folder.path_join(file))
	for directory in DirAccess.get_directories_at(folder):
		scan(folder.path_join(directory))
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/sanctuary-procession")
	scan("res://scenes")
	var intro = load("res://scripts/game/first_dungeon_intro.gd")
	for chapter in intro.PROLOGUE:
		for index in [2, 3]:
			if ResourceLoader.load(chapter[index]) == null:
				failures += 1
				print("FAIL: Missing prologue art ", chapter[index])
	print("ASSET_CLEANUP_CHECK: scenes=", scenes, " prologue_images=20 failures=", failures)
	quit(0 if failures == 0 else 1)
