extends SceneTree

## HISTORICAL: checks a rejected assembly, no longer used by the active suite.
## For the current visual study use capture_modular_room.gd instead.
const SCENE := "res://scenes/SingleCellRoom.tscn"
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func _snapshot(dungeon: Node) -> Array:
	var result: Array = []
	for sprite: Sprite2D in dungeon.get_surface_pieces():
		result.append([str(sprite.name), sprite.position, sprite.scale,
			sprite.get_meta("asset_id"), sprite.z_index, sprite.self_modulate])
	return result

func _sheet_x(sprite: Sprite2D, sheet_x: float) -> float:
	var atlas: AtlasTexture = sprite.texture
	return sprite.position.x + (sprite.offset.x + sheet_x - atlas.region.position.x) * sprite.scale.x

func _sheet_y(sprite: Sprite2D, sheet_y: float) -> float:
	var atlas: AtlasTexture = sprite.texture
	return sprite.position.y + (sprite.offset.y + sheet_y - atlas.region.position.y) * sprite.scale.y

func _run() -> void:
	if not ResourceLoader.exists(SCENE):
		printerr("FAIL: single-cell room scene does not exist")
		quit(1)
		return
	var scene: Node2D = load(SCENE).instantiate()
	root.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	var layout: DungeonLayout = dungeon.layout
	_check(dungeon.get_script().resource_path == "res://scripts/single_cell_room.gd",
		"Use the concept-matching single-cell composition")
	_check(layout.get_grid_size() == Vector2i.ONE, "The layout must be exactly 1 x 1")
	_check(layout.get_floor_cells() == [Vector2i.ZERO], "Exactly one floor cell is required")
	_check(layout.cell_size == 96 and layout.margin == 160, "Keep the current logical stone scale and margin")
	_check(not layout.entrance_enabled, "The room must have no entrance")
	_check(not dungeon.has_node("Heart") and dungeon.get_torch_sprites().is_empty(), "No heart or torches")
	_check(scene.find_children("*", "PointLight2D", true, false).is_empty(), "No fixture lights")
	_check(scene.find_children("*", "Polygon2D", true, false).is_empty(), "No programmatic silhouette geometry")
	_check(not scene.has_node("ProbeOverlay"), "Keep probes out of this visual study")
	var walls := {}
	for sprite: Sprite2D in dungeon.get_surface_pieces():
		_check(sprite.texture != null, "Missing texture on " + str(sprite.name))
		_check(is_equal_approx(sprite.scale.x, sprite.scale.y), "Nonuniform scale on " + str(sprite.name))
		_check(sprite.material == null and not sprite.region_enabled and sprite.rotation == 0,
			"No cutout material, sprite crop or rotation: " + str(sprite.name))
		if sprite.get_meta("kind") == "wall":
			walls[str(sprite.name)] = sprite
	_check(walls.keys().size() == 4 and walls.has_all(["North", "South", "West", "East"]),
		"Exactly four complete wall modules: north, south and one column per side")
	if walls.size() == 4:
		var scale: float = walls.North.scale.x
		for wall: Sprite2D in walls.values():
			# One generation at one uniform scale keeps stone size and light coherent.
			_check(is_equal_approx(wall.scale.x, scale), "All wall modules share one scale: " + str(wall.name))
			var atlas: AtlasTexture = wall.texture
			_check(atlas.atlas.resource_path == "res://assets/dungeon/alpha-kit/walls.png", "Walls come from the single walls.png generation")
			var pixels := atlas.get_image()
			_check(pixels.detect_alpha() != Image.ALPHA_NONE, "Native alpha is required")
			var edge_max := 0.0
			for y in range(pixels.get_height()):
				edge_max = maxf(edge_max, maxf(pixels.get_pixel(0, y).a, pixels.get_pixel(pixels.get_width() - 1, y).a))
			for x in range(pixels.get_width()):
				edge_max = maxf(edge_max, maxf(pixels.get_pixel(x, 0).a, pixels.get_pixel(x, pixels.get_height() - 1).a))
			_check(edge_max < 0.01, "Complete module must fit inside its transparent slot margins: " + str(wall.name))
		# Regression: the side columns must line up with the corner blocks of BOTH
		# horizontal walls (the sheet's own south modules were 9 px further out).
		var west_edge := _sheet_x(walls.West, walls.West.get_meta("joints")[0])
		var east_edge := _sheet_x(walls.East, walls.East.get_meta("joints")[0])
		_check(absf(west_edge - 160.0) < 1.0 and absf(east_edge - 256.0) < 1.0, "Side columns bound the floor cell")
		for id in ["North", "South"]:
			var joints: Array = walls[id].get_meta("joints")
			_check(absf(_sheet_x(walls[id], joints[0]) - west_edge) < 2.5,
				id + " west corner block must align with the west column")
			_check(absf(_sheet_x(walls[id], joints[1]) - east_edge) < 2.5,
				id + " east corner block must align with the east column")
		# No gap: columns start at the rear cap row and run under the front caps.
		var rear_cap_end := _sheet_y(walls.North, walls.North.get_meta("joints")[2])
		var front_cap_top := _sheet_y(walls.South, walls.South.get_meta("sheet_anchor").y)
		for id in ["West", "East"]:
			var column: Sprite2D = walls[id]
			var top := _sheet_y(column, column.get_meta("sheet_anchor").y)
			_check(absf(top - rear_cap_end) < 2.0, id + " column must start under the rear cap row")
			_check(top + 423.0 * scale >= front_cap_top, id + " column must reach the front caps")
		_check(walls.South.z_index > walls.West.z_index and walls.West.z_index > walls.North.z_index,
			"Draw order: rear wall, side columns, front wall")
		_check(walls.North.get_meta("asset_id").right(1) != walls.South.get_meta("asset_id").right(1),
			"Front and rear walls use different variants")
	_check(layout.has_floor(Vector2i.ZERO), "Center is walkable floor")
	for direction: Vector2i in DungeonLayout.OUTWARD:
		_check(not layout.has_floor(direction), "Each neighboring cell must be empty")
	var before := _snapshot(dungeon)
	dungeon.refresh_preview()
	await process_frame
	await process_frame
	_check(before == _snapshot(dungeon), "Rebuilding must preserve sprites and placement without duplicates")
	_check(dungeon.get_child_count() == before.size(), "Rebuilding must not accumulate generated nodes")
	print("Single-cell room: ", before.size(), " sprites; ", walls.size(), " wall modules")
	scene.queue_free()
	await process_frame
	if "--gpu" in OS.get_cmdline_user_args():
		await _capture()
	print("Single-cell checks: ", "PASS" if failures.is_empty() else "FAIL", " (artistic fidelity is not asserted)")
	quit(0 if failures.is_empty() else 1)

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	for factor in [1, 2]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(416, 416) * factor
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene: Node2D = load(SCENE).instantiate()
		viewport.add_child(scene)
		await process_frame
		var camera: Camera2D = scene.get_node("Camera2D")
		_check(camera.zoom.is_equal_approx(Vector2.ONE * factor), "Capture must retain exact " + str(factor) + "x zoom")
		await RenderingServer.frame_post_draw
		var pixels := viewport.get_texture().get_image()
		var file := "res://artifacts/single-cell-room" + ("-2x" if factor == 2 else "") + ".png"
		_check(pixels.save_png(file) == OK, "Could not save " + file)
		# Detect empty substrate; style and corner joins still need visual review.
		var background := Color("080e19")
		for y in range(168, 249, 8):
			for x in range(168, 249, 8):
				var sample := pixels.get_pixel(x * factor, y * factor)
				_check(Vector3(sample.r, sample.g, sample.b).distance_to(Vector3(background.r, background.g, background.b)) > 0.06,
					"Missing visible floor at " + str(Vector2i(x, y)))
		print("Saved ", file)
		viewport.queue_free()
		await process_frame
