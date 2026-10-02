extends SceneTree

func _initialize() -> void:
	var surfaces = load("res://scripts/world/mobile_surfaces.gd")
	var textures := {}
	var socket_mesh: Mesh
	for state in ["armed", "active", "broken"]:
		var parent := Node3D.new()
		surfaces.trap(parent, GameTypes.Tile.SPIKE, state == "broken", state == "active")
		var spikes := parent.find_children("Spike*", "Sprite3D", false, false)
		if spikes.size() != 9:
			push_error("FAIL: approved spines require exactly nine image-backed spikes")
			parent.free()
			quit(1)
			return
		var cells := {}
		for spike in spikes:
			var cell := Vector2i(roundi((spike.position.x - 0.25) * 4), roundi((spike.position.z - 0.25) * 4))
			assert(cell.x in range(3) and cell.y in range(3) and not cells.has(cell))
			cells[cell] = true
			assert(spike.modulate == Color.WHITE and not spike.shaded and not spike.no_depth_test)
			assert(spike.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD)
			assert(spike.texture.get_width() <= 512)
			assert(spike.position.y > 0.17 and spike.position.y < 0.20)
			if textures.has(state):
				assert(textures[state] == spike.texture)
			textures[state] = spike.texture
		var sockets := parent.get_node("SpikeSockets") as MeshInstance3D
		assert(sockets.mesh.get_aabb().end.y < 0.20)
		assert(sockets.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 54)
		if socket_mesh != null:
			assert(socket_mesh == sockets.mesh, "share floor geometry across states")
		socket_mesh = sockets.mesh
		assert(parent.get_child_count() == 10)
		parent.free()
	assert(textures.armed != textures.active and textures.active != textures.broken)
	for i in 20:
		var parent := Node3D.new()
		surfaces.trap(parent, GameTypes.Tile.SPIKE, true, true)
		assert(parent.get_node("Spike0").texture == textures.active, "last charge still activates; texture reused")
		parent.free()
	print("OK: nine spines, distinct states, flush shared sockets, cached textures and final-charge priority")
	quit()
