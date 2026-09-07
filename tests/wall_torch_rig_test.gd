extends SceneTree

const RIG := preload("res://scripts/world/wall_torch_rig.gd")
const PROFILE := preload("res://assets/rendering/dungeon_render_profile.tres")

func _initialize() -> void:
	var rig := RIG.new()
	root.add_child(rig)
	var cells: Array[Vector2i] = []
	for y in 16:
		for x in 16:
			cells.append(Vector2i(x, y))
	rig.sync_cells(cells, 1.0)
	var lights := rig.find_children("*", "OmniLight3D", true, false)
	if lights.size() != PROFILE.max_practical_lights:
		printerr("FAIL: large room must fill, but not exceed, the practical-light budget")
		quit(1)
		return
	for fixture in rig.get_children():
		var p: Vector3 = fixture.position
		if not (p.x < 0.1 or p.x > 15.9 or p.z < 0.1 or p.z > 15.9):
			printerr("FAIL: torch must be attached to a room boundary")
			quit(1)
			return
		for other in rig.get_children():
			if other != fixture and p.distance_to(other.position) < 2.59:
				printerr("FAIL: torches are clustered too closely")
				quit(1)
				return
	var first_id := rig.get_child(0).get_instance_id()
	rig.sync_cells(cells, 1.0)
	if first_id != rig.get_child(0).get_instance_id():
		printerr("FAIL: unchanged layout must reuse fixtures")
		quit(1)
		return
	var fixture_ids: Array[int] = []
	for fixture in rig.get_children():
		fixture_ids.append(fixture.get_instance_id())
	cells.reverse()
	rig.sync_cells(cells, 1.0)
	var reordered_ids: Array[int] = []
	for fixture in rig.get_children():
		reordered_ids.append(fixture.get_instance_id())
	if reordered_ids != fixture_ids:
		printerr("FAIL: cell ordering must not change the selected fixtures")
		quit(1)
		return
	if rig.find_children("*", "OmniLight3D", true, false).size() > PROFILE.max_practical_lights:
		printerr("FAIL: synchronization exceeds light budget before deferred deletion")
		quit(1)
		return
	var empty: Array[Vector2i] = []
	rig.sync_cells(empty, 1.0)
	if rig.get_child_count() != 0:
		printerr("FAIL: map reset must remove every torch")
		quit(1)
		return
	rig.free()
	print("OK: wall torches are spaced, bounded and reusable")
	quit()
