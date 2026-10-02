extends SceneTree

func _initialize() -> void:
	var surfaces = load("res://scripts/world/mobile_surfaces.gd")
	var textures := {}
	for state in ["hidden", "active", "broken"]:
		var parent := Node3D.new()
		surfaces.trap(parent, GameTypes.Tile.SNARE, state == "broken", state == "active")
		var floor_mark := parent.get_node_or_null("GraspFissures") as Sprite3D
		if state != "broken" and floor_mark == null:
			push_error("FAIL: approved grasp needs a transparent floor-bound fissure, not a block hand")
			parent.free()
			quit(1)
			return
		if floor_mark != null:
			assert(floor_mark.billboard == BaseMaterial3D.BILLBOARD_DISABLED)
			assert(is_equal_approx(floor_mark.rotation.x, -PI / 2))
			assert(floor_mark.position.y > 0.17 and floor_mark.position.y < 0.20)
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
