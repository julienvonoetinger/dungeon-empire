extends SceneTree

func _initialize() -> void:
	var surfaces = load("res://scripts/world/mobile_surfaces.gd")
	var textures := {}
	for state in ["hidden", "active", "broken"]:
		var parent := Node3D.new()
		surfaces.trap(parent, GameTypes.Tile.SNARE, state == "broken", state == "active")
		assert(not parent.has_node("GraspFissures"), "the dedicated floor replaces the fissure overlay")
		var hand := parent.get_node_or_null("StoneGrasp") as Sprite3D
		assert((hand == null) == (state == "hidden"))
		if hand != null:
			assert(hand.modulate == Color.WHITE and not hand.shaded)
			assert(not hand.no_depth_test and hand.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD)
			assert(hand.texture.get_width() <= 512, "bounded mobile texture size")
			textures[state] = hand.texture
		assert(parent.get_child_count() <= 2)
		parent.free()
	assert(textures.active != textures.broken, "destruction is a different image, not tint")
	var last_charge := Node3D.new()
	surfaces.trap(last_charge, GameTypes.Tile.SNARE, true, true)
	assert(last_charge.get_node("StoneGrasp").texture == textures.active)
	last_charge.free()
	for i in 20:
		var copy := Node3D.new()
		surfaces.trap(copy, GameTypes.Tile.SNARE, false, true)
		assert(copy.get_node("StoneGrasp").texture == textures.active, "textures shared across rebuilds")
		copy.free()
	print("OK: approved grasp sprites, floor integration, distinct states, cached textures and final charge")
	quit()
