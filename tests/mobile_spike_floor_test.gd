extends SceneTree

func _initialize() -> void:
	var floor_mesh := FloorRenderer.new()
	floor_mesh.mobile_mode = true
	var cells: Array[Vector2i] = [Vector2i(7, 1), Vector2i(7, 2)]
	var traps: Array[Vector2i] = [cells[0]]
	floor_mesh.sync_cells(cells, 1.0, [], [], [], traps)
	var arrays := floor_mesh.mesh.surface_get_arrays(0)
	for i in 8:
		assert(is_equal_approx(arrays[Mesh.ARRAY_VERTEX][i].y, 0.175))
		assert(arrays[Mesh.ARRAY_TEX_UV2][i].y == (3.0 if i < 4 else 0.0))
	var material: ShaderMaterial = floor_mesh.mesh.surface_get_material(0)
	assert(material.get_shader_parameter("spike_stone") is Texture2D)
	var before := floor_mesh.mesh
	floor_mesh.sync_cells(cells, 1.0, [], [], [], traps)
	assert(floor_mesh.mesh == before)
	floor_mesh.sync_cells(cells, 1.0)
	assert(floor_mesh.mesh != before)
	assert(floor_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2][0].y == 0.0)
	for state in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]:
		var prop := Node3D.new()
		preload("res://scripts/world/mobile_spines.gd").add_to(prop, state.x == 1, state.y == 1)
		assert(prop.get_child_count() == 9)
		assert(not prop.has_node("SpikeSockets"))
		for i in 9:
			var spike: Sprite3D = prop.get_child(i)
			assert(spike.position.is_equal_approx(Vector3(0.25 + (i / 3) * 0.25, 0.185, 0.25 + (i % 3) * 0.25)))
		prop.free()
	floor_mesh.free()
	print("PASS: spike floor, invalidation and all nine animated socket anchors")
	quit()
