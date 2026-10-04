extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	game.starter_enabled = false
	root.add_child(game)
	call_deferred("_run", game)

func _get_core_room(world: Object) -> Node3D:
	for property in world.get_property_list():
		if property.name == "_mobile_core_room":
			return world.get("_mobile_core_room") as Node3D
	return null

func _covered_cells_visible(world: Node, origin: Vector2i) -> bool:
	for y in 2:
		for x in 2:
			var p := origin + Vector2i(x, y)
			if not world._cells.has(p) or not world._cells[p].visible:
				return false
	return true

func _hidden_cell_count(world: Node) -> int:
	var hidden := 0
	for cell_root in world._cells.values():
		if not cell_root.visible:
			hidden += 1
	return hidden

func _mesh_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_count(child)
	return count

func _room_wall_parts(room: Node) -> Array[MeshInstance3D]:
	var parts: Array[MeshInstance3D] = []
	for group_name in ["Walls", "Corners"]:
		var group := room.get_node_or_null(group_name)
		if group != null:
			for mesh in group.find_children("*", "MeshInstance3D", true, false):
				parts.append(mesh)
	return parts

func _run(game: Node) -> void:
	await process_frame
	var world = game.dungeon
	var ui = game.mobile_ui
	var original_grid: Array = game.grid.duplicate(true)
	var original_gold: int = game.gold
	var first_anchor := Vector2i(4, 8)
	game.mobile_selection = first_anchor
	world.sync(game)
	var room := _get_core_room(world)
	check(room != null and room.visible, "valid anchor shows cached Core room preview")
	if room != null:
		var meshes := room.find_children("*", "MeshInstance3D", true, false)
		var floors := 1 if room.find_child("Floor", true, false) is MeshInstance3D else 0
		var walls_node := room.find_child("Walls", true, false)
		var corners_node := room.find_child("Corners", true, false)
		var walls := _mesh_count(walls_node)
		var corners := _mesh_count(corners_node)
		if walls_node == null or corners_node == null:
			for mesh in meshes:
				if walls_node == null and String(mesh.name).begins_with("Wall"):
					walls += 1
				elif corners_node == null and String(mesh.name).begins_with("Corner"):
					corners += 1
		check(floors == 1 and walls == 4 and corners == 4,
			"preview contains one floor, four walls and four corners (got %d/%d/%d)" % [floors, walls, corners])
		check(room.get_meta("bounds") == Rect2i(-1, -1, 4, 4), "interior preview includes all twelve access cells")
		check(is_equal_approx(room.get_node("Floor").get_aabb().size.x, 4.0), "preview floor really spans four cells")
		await _capture(game, "center")
	var first_id := room.get_instance_id() if room != null else 0
	if room != null:
		world.set_mobile_walls_visible(false)
		world.sync(game)
		var foundation_ok := true
		for part in _room_wall_parts(room):
			foundation_ok = foundation_ok and part.has_meta("foundation_mesh") and part.mesh == part.get_meta("foundation_mesh")
		check(foundation_ok and _room_wall_parts(room).size() == 8,
			"all four preview walls and four corners use foundation meshes when walls are hidden")
		world.set_mobile_walls_visible(true)
		world.sync(game)
		var full_ok := true
		for part in _room_wall_parts(room):
			full_ok = full_ok and part.has_meta("full_mesh") and part.mesh == part.get_meta("full_mesh")
		check(full_ok, "all preview walls and corners restore full meshes when walls are visible")
	check(not _covered_cells_visible(world, first_anchor), "preview hides only its four covered rock roots")
	check(_hidden_cell_count(world) >= 16, "preview hides the full Core and access ring")
	var second_anchor := Vector2i(10, 8)
	game.mobile_selection = second_anchor
	world.sync(game)
	var moved_room := _get_core_room(world)
	check(moved_room != null and moved_room.get_instance_id() == first_id,
		"moving the anchor reuses the same preview room node")
	check(_covered_cells_visible(world, first_anchor), "moving preview restores the previous four rock roots")
	check(not _covered_cells_visible(world, second_anchor), "moving preview hides the new four covered roots")
	check(_hidden_cell_count(world) >= 16, "moved preview hides the full Core and access ring")
	game.mobile_selection = Vector2i(-1, -1)
	world.sync(game)
	var cancelled_room := _get_core_room(world)
	check(cancelled_room == null or not cancelled_room.visible, "clearing selection hides the room preview")
	check(_covered_cells_visible(world, second_anchor), "clearing selection restores covered rocks")
	check(_hidden_cell_count(world) == 0, "cancelling preview restores every grid root")
	check(game.grid == original_grid and game.gold == original_gold,
		"preview movement and cancellation do not mutate dungeon or gold")
	for edge in [Vector2i.ZERO, Vector2i(game.COLS - 2, game.ROWS - 2), Vector2i(0, 6)]:
		game.mobile_selection = edge
		world.sync(game)
		var edge_room := _get_core_room(world)
		check(edge_room != null and edge_room.visible and edge_room.position == Vector3(edge.x, 0, edge.y),
			"edge anchor %s keeps the cached preview aligned" % edge)
		if edge_room != null:
			var wall_nodes: Array = edge_room.get_node("Walls").get_children()
			if edge == Vector2i.ZERO:
				check(is_equal_approx(wall_nodes[0].position.z, -0.28) and is_zero_approx(wall_nodes[2].position.x),
					"top-left preview walls stay outside playable floor")
			elif edge.x > 0:
				check(is_equal_approx(wall_nodes[1].position.z, 2.0) and is_equal_approx(wall_nodes[3].position.x, 2.28),
					"bottom-right preview walls stay outside playable floor")
		var expected_size := Vector2i(3, 4) if edge == Vector2i(0, 6) else Vector2i(3, 3)
		check(edge_room.get_meta("bounds").size == expected_size, "preview ring is clipped to map bounds")
		check(_hidden_cell_count(world) >= expected_size.x * expected_size.y, "edge preview hides its clipped footprint")
		await _capture(game, "edge-%d-%d" % [edge.x, edge.y])
		check(edge_room != null and edge_room.get_instance_id() == first_id, "edge anchors reuse cached preview geometry")
	game.mobile_selection = Vector2i(-1, -1)
	world.sync(game)
	check(_hidden_cell_count(world) == 0, "cancelling edge preview restores all roots")
	ui.selected = first_anchor
	ui._update_preview()
	ui._confirm()
	world.sync(game)
	var placed_room := _get_core_room(world)
	check(game._has_core(), "confirm commits the selected Core placement")
	check(placed_room == null or not placed_room.visible, "committing anchor removes the room preview")
	check(_covered_cells_visible(world, second_anchor), "committing anchor restores the abandoned preview rocks")
	check(not game.persistence_enabled, "preview test does not access a real save")
	await _capture(game, "placed")
	game.queue_free()
	await process_frame
	print("Mobile Core room preview: %d failures" % failures)
	quit(1 if failures else 0)

func _capture(game: Node, label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	game.mobile_ui.paused = true
	game.mobile_ui.selected = game.mobile_selection
	game.mobile_ui._update_preview()
	game.mobile_ui._center(game.mobile_selection if game.mobile_selection.x >= 0 else game._core_origin())
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/core-ring-%s.png" % label)
