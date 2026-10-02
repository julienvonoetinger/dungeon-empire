extends SceneTree

func _initialize() -> void:
	var floor_mesh := FloorRenderer.new()
	floor_mesh.mobile_mode = true
	var cells: Array[Vector2i] = [Vector2i(1, 1)]
	floor_mesh.sync_cells(cells, 1.0, [], [], [], [], cells)
	assert(floor_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][0].y == 4.0)
	assert(floor_mesh.mesh.surface_get_material(0).get_shader_parameter("snare_stone") is Texture2D)
	floor_mesh.sync_cells(cells, 1.0)
	assert(floor_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][0].y == 0.0)
	for state in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)]:
		var prop := Node3D.new()
		preload("res://scripts/world/mobile_grasp.gd").add_to(prop, state.x == 1, state.y == 1)
		assert(not prop.has_node("GraspFissures"))
		assert(prop.has_node("StoneGrasp") == (state != Vector2i.ZERO))
		prop.free()
	floor_mesh.free()
	print("OK: snare floor and mechanism states")
	quit()
