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
	rig.set_wall_visuals_visible(false)
	for fixture in rig.get_children():
		var fixture_lights := fixture.find_children("*", "OmniLight3D", true, false)
		var visuals := fixture.get_children().filter(func(child: Node) -> bool: return not child is OmniLight3D)
		if fixture_lights.size() != 1 or not fixture_lights[0].visible or visuals.is_empty() or visuals[0].visible:
			printerr("FAIL: hiding wall fixtures must preserve their floor lights")
			quit(1)
			return
	var small_cells: Array[Vector2i] = [Vector2i.ZERO]
	rig.sync_cells(small_cells, 1.0)
	for fixture in rig.get_children():
		if fixture.get_child(0).visible:
			printerr("FAIL: new fixtures inherit hidden visual state")
			quit(1)
			return
	rig.set_wall_visuals_visible(true)
	for fixture in rig.get_children():
		if not fixture.get_child(0).visible or not fixture.get_child(1).visible:
			printerr("FAIL: restoring fixtures shows the model and preserves its light")
			quit(1)
			return
	rig.sync_cells(small_cells, 1.0, [Vector2i.ZERO])
	var hidden_light_count := rig.find_children("*", "OmniLight3D", true, false).size()
	if hidden_light_count != 1:
		printerr("FAIL: hidden entrance fixture must retain its practical light")
		quit(1)
		return
	for fixture in rig.get_children():
		var model := fixture.get_child(0)
		var light := fixture.get_child(1) as OmniLight3D
		if model.visible or light == null or not light.visible:
			printerr("FAIL: hidden_visual_cells hides only the fixture model")
			quit(1)
			return
	rig.set_wall_visuals_visible(false)
	rig.set_wall_visuals_visible(true)
	for fixture in rig.get_children():
		if fixture.get_child(0).visible or not fixture.get_child(1).visible:
			printerr("FAIL: global visibility toggle preserves per-cell hidden visual override")
			quit(1)
			return
	rig.sync_cells(small_cells, 1.0)
	if rig.get_child_count() != 1 or not rig.get_child(0).get_child(0).visible:
		printerr("FAIL: removing hidden_visual_cells restores the reused model")
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
