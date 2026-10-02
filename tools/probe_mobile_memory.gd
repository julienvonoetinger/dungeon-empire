extends SceneTree

var game

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	call_deferred("_run")

func _sample(label: String) -> void:
	print("MEMORY ", label, " static_mb=", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		" video_mb=", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		" texture_mb=", Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		" objects=", Performance.get_monitor(Performance.OBJECT_COUNT),
		" nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		" resources=", Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))

func _run() -> void:
	_sample("empty")
	game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	preload("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.mobile_ui._cancel()
	game.mobile_ui.paused = true
	for i in 20:
		await process_frame
	_sample("loaded")
	for i in 600:
		game.cam_pan = Vector2(sin(i * 0.04) * 350, cos(i * 0.03) * 180)
		game.cam_yaw = 45 + (i / 150) * 90
		game.cam_zoom = 1.5 + 0.5 * sin(i * 0.02)
		await process_frame
		if i % 150 == 149:
			_sample("pan_%d" % (i + 1))
	game.mobile_ui.paused = false
	game.mobile_ui._start_raid()
	assert(game.raid_active, "probe must exercise an active raid")
	for i in 300:
		await process_frame
	_sample("raid")
	quit()
