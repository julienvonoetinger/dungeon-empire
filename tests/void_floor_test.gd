extends SceneTree

func _initialize() -> void:
	var floor_mesh := FloorRenderer.new()
	floor_mesh.mobile_mode = true
	var cells: Array[Vector2i] = [Vector2i(1, 1)]
	floor_mesh.sync_cells(cells, 1.0, [], [], [], [], [], cells)
	assert(floor_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][0].y == 5.0)
	assert(floor_mesh.mesh.surface_get_material(0).get_shader_parameter("void_stone") is Texture2D)
	floor_mesh.sync_cells(cells, 1.0)
	assert(floor_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][0].y == 0.0)
	floor_mesh.free()
	print("OK: dedicated void floor and invalidation")
	quit()
