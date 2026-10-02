extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var is_void := "--void" in OS.get_cmdline_user_args()
	var name := "void" if is_void else "snare"
	var config := ConfigFile.new()
	var path := "res://assets/mobile/%s-floor-v1.png.import" % name
	assert(config.load(path) == OK)
	config.set_value("params", "process/size_limit", 512)
	config.set_value("params", "mipmaps/generate", true)
	assert(config.save(path) == OK)
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	assert(ui.save_api.apply(ui.save_api.read_save("res://artifacts/chest-user-repro.save"), game.sim, game.raid, ui.profile))
	ui.paused = true
	ui._cancel()
	var cell := Vector2i(7, 1)
	game.grid[cell.y][cell.x] = GameTypes.Tile.VOID if is_void else GameTypes.Tile.SNARE
	game.cam_zoom = 4.8
	game.dungeon.set_mobile_walls_visible(false)
	for yaw in [45, 135, 225, 315]:
		game.cam_yaw = yaw
		ui._center(cell)
		for state in ["armed", "active", "broken"]:
			game.trap_charges[cell] = 0 if state == "broken" else (1 if is_void else 3)
			game.hero = {"trap_sprung_at": cell} if state == "active" else {}
			game._sync_world()
			for frame in 8:
				ui.modal.hide()
				await process_frame
			assert(root.get_texture().get_image().save_png("res://artifacts/%s-floor-%d-%s.png" % [name, yaw, state]) == OK)
	quit()
