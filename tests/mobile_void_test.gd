extends SceneTree

func _initialize() -> void:
	var surfaces = load("res://scripts/world/mobile_surfaces.gd")
	var textures := {}
	var transform: Transform3D
	for state in ["armed", "active", "broken"]:
		var parent := Node3D.new()
		surfaces.trap(parent, GameTypes.Tile.VOID, state == "broken", state == "active")
		var trap := parent.get_node_or_null("VoidFloor") as Sprite3D
		if trap == null:
			push_error("FAIL: Void must use the approved horizontal floor artwork")
			parent.free()
			quit(1)
			return
		assert(parent.get_child_count() == 1)
		assert(trap.billboard == BaseMaterial3D.BILLBOARD_DISABLED)
		assert(is_equal_approx(trap.rotation.x, -PI / 2))
		assert(trap.position.y > 0.17 and trap.position.y < 0.20)
		assert(trap.modulate == Color.WHITE and trap.shaded, "Void stone must receive the same lighting as paving")
		assert(trap.material_override is ShaderMaterial, "Void uses lit stone with isolated rune emission")
		assert(trap.material_override.get_shader_parameter("artwork") == trap.texture)
		assert(trap.texture.resource_path.ends_with("void-%s-v3.png" % state))
		assert(not trap.no_depth_test and trap.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD)
		assert(trap.texture.get_width() <= 512)
		assert(is_equal_approx(trap.pixel_size * trap.texture.get_width(), 0.98))
		if not textures.is_empty():
			assert(trap.transform.is_equal_approx(transform), "no state footprint jump")
		transform = trap.transform
		textures[state] = trap.texture
		parent.free()
	assert(textures.armed != textures.active and textures.active != textures.broken)
	for i in 20:
		var parent := Node3D.new()
		surfaces.trap(parent, GameTypes.Tile.VOID, true, true)
		assert(parent.get_node("VoidFloor").texture == textures.active, "last-charge absorption keeps the abyss open; texture shared")
		assert(parent.get_node("VoidFloor").material_override == preload("res://scripts/world/mobile_void.gd")._materials[textures.active], "Rebuilds share cached materials")
		parent.free()
	print("OK: horizontal Void, aligned states, cached textures, depth test and last-charge priority")
	quit()
