extends SceneTree
## Run headlessly for assertions, or with -- --capture for actual Godot screenshots.

const SPIKE := Vector2i(2, 3)
const SNARE := Vector2i(5, 4)
const VOID := Vector2i(4, 7)
const DOOR := Vector2i(3, 6)
const ENTRANCE := Vector2i(1, 1)
const ROUTE: Array[Vector2i] = [
	Vector2i(5, 7), Vector2i(4, 7), Vector2i(3, 7), Vector2i(3, 6),
	Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 4),
	Vector2i(5, 3), Vector2i(4, 3), Vector2i(3, 3), Vector2i(2, 3),
	Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 1),
	Vector2i(6, 3), Vector2i(7, 3), Vector2i(7, 4), Vector2i(3, 2), Vector2i(3, 1)]
var game: Node
var failures: Array[String] = []
var capture := false

func _initialize() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(1600, 1000)
	game = load("res://Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	game.set_process(false)
	_build_labyrinth()
	_check_trap_icon_zoom_invariance()
	await _snapshot("labyrinth_armed", Vector2i(-1, -1))
	await _snapshot("entrance", ENTRANCE)
	await _snapshot("door_intact", DOOR)
	for point in [SPIKE, SNARE, VOID]:
		_check_visual(point, "armed")
		await _snapshot("%s_armed" % _label(point), point)
	game._start_raid()
	check(game.hero.pos == ENTRANCE, "hero must spawn at the constructed entrance")
	game._update_hero(0.6)
	check(game.hero.pos == Vector2i(1, 2), "hero must leave stairs through their corridor mouth")
	var budget: int = game.gold
	game.selected_tool = game.Tool.DIG
	game._build_at(Vector2i(2, 1))
	check(int(game.grid[1][2]) == game.Tile.ROCK and game.gold == budget, "raid must lock excavation")
	# Controlled arrivals isolate each state while using the real trap resolver.
	game.hero.hp = 300
	game.hero.max_hp = 300
	game.hero.kind = "thief"
	for point in [SPIKE, SNARE]:
		for charge in 3:
			game.hero.pos = point
			var hp_before: int = game.hero.hp
			var cooldown: float = game.hero.move_cd
			game._resolve_cell(point)
			check(game.hero.hp < hp_before, "%s must deal damage" % _label(point))
			if point == SNARE:
				check(game.hero.move_cd > cooldown, "snare must slow movement")
			_check_visual(point, "sprung")
			if charge < 2:
				await _snapshot("%s_%d_charges" % [_label(point), int(game.trap_charges[point])], point)
			if charge == 2:
				await _snapshot("%s_last_trigger" % _label(point), point)
			game.hero.erase("trap_sprung_at")
			game.hero.pos = Vector2i(5, 5)
			_check_visual(point, "broken" if charge == 2 else "armed")
		check(game.trap_charges[point] == 0, "three activations must exhaust %s" % _label(point))
		var hp: int = game.hero.hp
		game._resolve_cell(point)
		check(game.hero.hp == hp, "spent %s must not deal damage" % _label(point))
		await _snapshot("%s_broken" % _label(point), point)
	game.hero.pos = VOID
	game.hero.carried_gold = 0
	var hp_before_void: int = game.hero.hp
	game._resolve_cell(VOID)
	game.hero.portal_t = game.PORTAL_HOLD * 0.5
	game.dungeon.sync(game)
	check(bool(game.hero.get("void_absorbing", false)) and game.hero.hp == hp_before_void, "void must start an absorption without physical damage")
	check(game.dungeon._town_portal == null or not game.dungeon._town_portal.visible, "void absorption must not show a town portal")
	check(game.dungeon._hero.scale.x < 1.0 and not game.dungeon._hero_bar.visible, "void absorption must shrink the hero and hide their UI")
	_check_visual(VOID, "sprung")
	await _snapshot("void_trigger", VOID)
	game._update_hero(2.0)
	check(not game.raid_active and game.trap_charges[VOID] == 0, "banishment must finish the raid and consume one charge")
	_check_visual(VOID, "broken")
	await _snapshot("void_broken", VOID)
	check(game.corpses.is_empty(), "banishment must not leave a corpse")
	# Exactly enough starting gold remains for all seven replacement charges.
	game._apply_toolbar_tool(game.Tool.REPAIR)
	for point in [SPIKE, SNARE, VOID]:
		check(game.trap_charges[point] == (1 if point == VOID else 3), "repair must recharge %s" % _label(point))
		_check_visual(point, "armed")
	check(game.gold == 0, "construction and repairs must respect the original 320-gold budget")
	await _snapshot("labyrinth_repaired", Vector2i(-1, -1))
	await _natural_raids()
	var report := "Labyrinth integration: %d failure(s)\n" % failures.size()
	for failure in failures:
		report += "FAIL: %s\n" % failure
	if failures.is_empty():
		report += "PASS: 20 excavations, entrance, door, all trap states, repairs, 12 natural raids.\n"
	print(report)
	var file := FileAccess.open("res://artifacts/labyrinth_test_report.txt", FileAccess.WRITE)
	file.store_string(report)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _build_labyrinth() -> void:
	game._new_map()
	game.set_process(false)
	game.selected_tool = game.Tool.DIG
	for point in ROUTE:
		game._build_at(point)
		check(int(game.grid[point.y][point.x]) == game.Tile.FLOOR, "excavation must connect legally at %s" % point)
	for placement in [[SPIKE, game.Tool.TRAP_SPIKE], [SNARE, game.Tool.TRAP_SNARE], [VOID, game.Tool.TRAP_VOID], [DOOR, game.Tool.BUILD_DOOR], [ENTRANCE, game.Tool.BUILD_ENTRANCE]]:
		game.selected_tool = placement[1]
		game._build_at(placement[0])
	check(game.gold == 70, "legal construction should cost 250 gold")
	check(game._has_entrance(), "entrance construction failed")
	check(game._can_step(ENTRANCE, Vector2i(1, 2)), "stair mouth must connect to the labyrinth")
	game.dungeon.sync(game)
	_check_door_visual("intact")
	game.door_hp[DOOR] = int(game.DOOR_MAX_HP) / 2
	game.dungeon.sync(game)
	_check_door_visual("damaged")
	game.door_hp[DOOR] = int(game.DOOR_MAX_HP)
	game.dungeon.sync(game)

func _check_door_visual(expected: String) -> void:
	var cell: Node3D = game.dungeon._cells[DOOR]
	var icon: Sprite3D = cell.get_node_or_null("DoorStateIcon") as Sprite3D
	check(icon != null and icon.texture != null, "door must display a visual condition icon")
	if icon != null and icon.texture != null:
		check(icon.texture.resource_path.ends_with("door_state_%s.png" % expected), "door must display the generated %s condition icon (got %s)" % [expected, icon.texture.resource_path])
		var trap_icon: Sprite3D = game.dungeon._cells[SPIKE].get_node_or_null("TrapStateIcon") as Sprite3D
		check(trap_icon != null and trap_icon.texture != null, "a trap icon must exist to compare shared visual size")
		if trap_icon != null and trap_icon.texture != null:
			var door_world_width := icon.pixel_size * float(icon.texture.get_width())
			var trap_world_width := trap_icon.pixel_size * float(trap_icon.texture.get_width())
			check(is_equal_approx(door_world_width, trap_world_width * 0.85), "door medallions must visually match the shared status diameter")
		check(is_equal_approx(icon.scale.x, 0.55), "door and trap medallions must share the same world scale")
		check(is_equal_approx(icon.position.y, 1.65), "door medallions must sit above the door model")
	check(cell.get_node_or_null("Label3D") == null, "door must not display a numeric health label")

func _check_visual(point: Vector2i, state: String) -> void:
	game.dungeon.sync(game)
	var world: Node = game.dungeon
	var cell: Node3D = world._cells[point]
	var found: Node3D = cell.get_node_or_null("StoneTrap")
	var state_icon: Sprite3D = cell.get_node_or_null("TrapStateIcon") as Sprite3D
	check(found != null, "%s must display its stone mechanism" % _label(point))
	check(state_icon != null and state_icon.texture != null, "%s must display a trap condition icon" % _label(point))
	if found == null:
		return
	check(found.kind == _label(point) and found.state == state, "%s must display %s" % [_label(point), state])
	check(not found.has_node("TrapFrame"), "%s %s must directly replace its 1x1 floor tile" % [_label(point), state])
	var bounds := _bounds(found, _transform_to_cell(found.get_parent(), cell))
	if bounds.has_volume():
		check(absf(bounds.position.x) < 0.03 and absf(bounds.end.x - 1.0) < 0.03 and absf(bounds.position.z) < 0.03 and absf(bounds.end.z - 1.0) < 0.03,
			"%s %s must fill exactly one cell without a gutter: %s" % [_label(point), state, bounds])
	check(bounds.has_volume() and bounds.end.y > 0.15, "%s %s must remain visually distinct" % [_label(point), state])
	if state_icon != null and state_icon.texture != null:
		var charges: int = int(game.trap_charges.get(point, 0))
		var maximum: int = game._trap_max_charges(int(game.grid[point.y][point.x]))
		var expected := "one" if maximum == 1 and charges == 1 else "destroyed" if maximum == 1 else "intact" if charges == maximum else "two" if charges == 2 else "one" if charges == 1 else "destroyed"
		check(state_icon.texture.resource_path.ends_with("trap_state_%s.png" % expected), "%s must display the generated %s-charge condition icon (got %s, charges %d)" % [_label(point), expected, state_icon.texture.resource_path, charges])

func _check_trap_icon_zoom_invariance() -> void:
	var icon: Sprite3D = game.dungeon._cells[SPIKE].get_node_or_null("TrapStateIcon") as Sprite3D
	if icon == null or icon.texture == null:
		check(false, "trap icon must exist before zoom invariance can be checked")
		return
	check(not icon.fixed_size, "trap icon must scale with its world cell rather than screen pixels")
	check(is_equal_approx(icon.scale.x, 0.55), "trap icon must use the compact world display scale")
	check(is_equal_approx(icon.pixel_size, 0.00216), "trap status medallions must remain legible against the dungeon floor")
	check(is_equal_approx(icon.position.y, 0.95), "trap status medallions must clear heroes moving through the trap")

func _transform_to_cell(node: Node3D, cell: Node3D) -> Transform3D:
	if node == cell:
		return Transform3D.IDENTITY
	return _transform_to_cell(node.get_parent(), cell) * node.transform

func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform * node.transform
	var result := AABB()
	var has_mesh := false
	if node is MeshInstance3D and node.mesh != null:
		result = transform * node.get_aabb()
		has_mesh = true
	for child in node.get_children():
		if not child is Node3D:
			continue
		var sub := _bounds(child, transform)
		if sub.size != Vector3.ZERO:
			result = result.merge(sub) if has_mesh else sub
			has_mesh = true
	return result

func _natural_raids() -> void:
	var encountered := {SPIKE: false, SNARE: false, VOID: false}
	var kinds := {}
	var opened_door := false
	for run in 12:
		seed(8200 + run)
		_build_labyrinth()
		game._start_raid()
		kinds[game.hero.kind] = true
		var previous: Vector2i = game.hero.pos
		for step in 900:
			if not game.raid_active:
				break
			var departed: Vector2i = previous
			game._update_hero(0.6)
			if not game.hero.is_empty():
				var point: Vector2i = game.hero.pos
				if point != previous:
					check(game._can_step(previous, point), "natural raid crossed a wall or staircase side")
				previous = point
			for point in encountered:
				var maximum := 1 if point == VOID else 3
				if int(game.trap_charges[point]) < maximum:
					encountered[point] = true
			var door_destroyed := int(game.door_hp.get(DOOR, 60)) == 0
			if door_destroyed:
				opened_door = true
			game.dungeon.sync(game)
			if door_destroyed:
				_check_door_visual("destroyed")
			if previous != departed and encountered.has(departed):
				_check_visual(departed, "broken" if game.trap_charges[departed] == 0 else "armed")
			if step % 8 == 0:
				await process_frame
		check(not game.raid_active, "natural raid %d did not terminate" % run)
		for point in encountered:
			_check_visual(point, "broken" if game.trap_charges[point] == 0 else "armed")
	check(kinds.size() == 3, "natural raids should exercise all three adventurer archetypes")
	check(opened_door, "natural exploration must reach and break the corridor door")
	for point in encountered:
		check(encountered[point], "natural exploration never triggered %s" % _label(point))
	print("Natural raids: archetypes=", kinds.keys(), " traps=", encountered, " door broken=", opened_door)

func _snapshot(label: String, focus: Vector2i) -> void:
	if not capture:
		return
	game.dungeon.sync(game)
	var world: Node3D = game.dungeon
	world._yaw = 45.0
	var target := Vector3(5.0, 0.0, 5.0) if focus.x < 0 else Vector3(focus.x + 0.5, 0.0, focus.y + 0.5)
	var size := 13.0 if focus.x < 0 else 3.2
	var basis: Basis = world._cam_basis()
	var right := Vector3(basis.x.x, 0, basis.x.z).normalized()
	var forward := Vector3(-basis.z.x, 0, -basis.z.z).normalized()
	var offset: Vector3 = target - world.map_center(game.COLS, game.ROWS)
	var k: float = size / game._play_view().y
	game.cam_zoom = world.BASE_ORTHO / size
	game.cam_yaw = 45.0
	game.cam_pan = Vector2(offset.dot(right) / k, -offset.dot(forward) / k)
	game._cam_custom = true
	world.apply_camera(game.cam_zoom, game.cam_pan, game._play_view(), game.COLS, game.ROWS, game.cam_yaw)
	if world._dig_bound != null:
		world._dig_bound.visible = false
	if world._expand_root != null:
		world._expand_root.visible = false
	for frame in 3:
		await process_frame
	RenderingServer.force_draw()
	await process_frame
	var image: Image = game._world_port.get_texture().get_image()
	var output := "res://artifacts/%s.png" % label
	check(image.save_png(output) == OK, "capture failed: " + output)
	print("Captured ", output)

func _label(point: Vector2i) -> String:
	return "spike" if point == SPIKE else "snare" if point == SNARE else "void"

func check(condition: bool, message: String) -> void:
	if not condition and not failures.has(message):
		failures.append(message)
		printerr("FAIL: ", message)
