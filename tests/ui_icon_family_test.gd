extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	var ui = game.mobile_ui
	ui.paused = true
	var regions: Array[Rect2] = []
	for key in [GameTypes.Tool.DIG, GameTypes.Tool.BUILD_DOOR, GameTypes.Tool.BUILD_MAGIC_DOOR, GameTypes.Tool.BUILD_ENTRANCE, GameTypes.Tool.STORE, GameTypes.Tool.STORE_LOCKED, GameTypes.Tool.STORE_MAGIC, GameTypes.Tool.TRAP_SPIKE, GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID, 10, 11]:
		var icon: Texture2D = ui.icons[key]
		assert(icon is AtlasTexture, "Every UI symbol must use the dedicated icon atlas")
		var expected := "res://assets/mobile/spikes-menu-v3.png" if key == GameTypes.Tool.TRAP_SPIKE else "res://assets/mobile/ui-menu-atlas-v2.png"
		if key == GameTypes.Tool.TRAP_SNARE:
			expected = "res://assets/mobile/snare-claw-menu-v1.png"
		assert(icon.atlas.resource_path == expected, "Use dedicated UI artwork, not world sprites")
		assert(not regions.has(icon.region), "Every command has its own symbol")
		regions.append(icon.region)
		assert(icon.filter_clip)
		assert(icon.atlas.get_image().has_mipmaps(), "Reduced UI icons need imported mipmaps")
	assert(ui.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	game._new_map()
	var cell := Vector2i(3, 3)
	game.grid[cell.y][cell.x] = GameTypes.Tile.SPIKE
	game.trap_charges[cell] = 3
	ui._sync_trap_badges()
	assert(ui.trap_badges[cell].icon != ui.icons[GameTypes.Tool.TRAP_SPIKE], "Small spike badge is a pictogram, not the menu illustration")
	assert(ui.trap_badges[cell].icon.resource_path == "res://assets/mobile/spikes-badge-v1.svg")
	game.trap_charges[cell] = 0
	ui._sync_trap_badges()
	assert(ui.trap_badges[cell].repair_button.visible)
	assert(ui.trap_badges[cell].icon == ui.badge_icons[GameTypes.Tool.TRAP_SPIKE])
	for pair in [[GameTypes.Tile.SNARE, GameTypes.Tool.TRAP_SNARE, "snare"], [GameTypes.Tile.VOID, GameTypes.Tool.TRAP_VOID, "void"]]:
		game.grid[cell.y][cell.x] = pair[0]
		ui._sync_trap_badges()
		assert(ui.trap_badges[cell].icon.resource_path == "res://assets/mobile/%s-badge-v1.svg" % pair[2])
		assert(ui.trap_badges[cell].icon != ui.icons[pair[1]])
	for pair in [[GameTypes.Tile.DOOR, "lock"], [GameTypes.Tile.MAGIC_DOOR, "crystal"]]:
		game.grid[cell.y][cell.x] = pair[0]
		ui._sync_door_badges()
		assert(ui.door_badges[cell].icon.resource_path == "res://assets/mobile/%s-badge-v1.svg" % pair[1])
	assert(ui.core_badge.icon == ui.badge_icons[11])
	assert(ui.core_badge.icon.resource_path == "res://assets/mobile/crystal-badge-v1.svg")
	assert(ui.badge_icons[10] == ui.icons[10], "Gold preserves the approved illustrated coins")
	game.queue_free()
	await process_frame
	print("OK: approved illustrated menus and gold, white trap/door/core pictograms, repair state preserved")
	quit()
