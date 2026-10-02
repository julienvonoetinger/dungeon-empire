extends SceneTree

var game
var path := "user://diagnostic_ui_capture.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.mobile_ui.free()
	var store = load("res://scripts/mobile/mobile_diagnostics.gd").new()
	assert(store.begin(path) == OK)
	assert(store.append({"renderer": "test", "rss_bytes": 123456}) == OK)
	assert(store.begin(path) == OK)
	var ui = load("res://scripts/mobile/mobile_session.gd").new()
	ui.g = game
	ui._diagnostics = store
	game.mobile_ui = ui
	game.add_child(ui)
	assert(ui.paused and ui.modal.visible)
	assert(game._world_port.render_target_update_mode == SubViewport.UPDATE_DISABLED)
	assert(not game.dungeon.is_processing())
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/mobile-diagnostic-pause.png")
	var old_clipboard := DisplayServer.clipboard_get()
	ui._copy_diagnostic(true)
	var copied = JSON.parse_string(DisplayServer.clipboard_get())
	DisplayServer.clipboard_set(old_clipboard)
	assert(copied.samples.back().rss_bytes == 123456)
	ui._continue()
	assert(game._world_port.render_target_update_mode == SubViewport.UPDATE_ALWAYS)
	assert(game.dungeon.is_processing())
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/mobile-diagnostic-resumed.png")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Diagnostic recovery/copy/resume passed")
	quit()
