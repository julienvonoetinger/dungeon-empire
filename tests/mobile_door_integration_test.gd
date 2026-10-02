extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	var world = load("res://scripts/world/dungeon_world.gd").new()
	world.mobile_mode = true
	root.add_child(world)
	var cell := Vector2i(7, 7)
	for magic in [false, true]:
		for state in ["closed", "damaged", "opened", "destroyed"]:
			game.grid[7][7] = GameTypes.Tile.MAGIC_DOOR if magic else GameTypes.Tile.DOOR
			game.door_hp[cell] = 0 if state == "destroyed" else 20 if state == "damaged" else game.DOOR_MAX_HP
			game.door_opened[cell] = state == "opened"
			world._rebuild_cell(cell, game.grid[7][7], game, {}, false)
			var holder: Node = world._cells[cell]
			assert(holder.get_node_or_null("DoorStateIcon") == null, "Mobile doors have no floating medallion")
			assert(holder.get_node_or_null("MagicDoorSeal") == null, "Runes belong to the leaves, not a floating ring")
			var door := holder.get_node_or_null("MobileDoor")
			assert(door != null, "Mobile door uses the integrated masonry frame")
			var frame: MeshInstance3D = door.get_node("MasonryFrame")
			assert(frame.mesh.get_aabb().size.z >= 0.27, "Frame has wall thickness")
			assert(is_equal_approx(frame.mesh.get_aabb().end.y, 1.10), "Coping aligns with corridor walls")
			assert(door.find_children("*", "Sprite3D", true, false).is_empty(), "Door stays volumetric from every side")
			if state == "destroyed":
				assert(door.has_node("Rubble") and not door.has_node("LeftHinge"))
			else:
				for side in ["LeftHinge", "RightHinge"]:
					var hinge: Node3D = door.get_node(side)
					assert(is_equal_approx(absf(hinge.rotation.y), PI / 2 if state == "opened" else 0.0))
					var face: MeshInstance3D = hinge.get_node("Front")
					assert(face.position.y - face.mesh.size.y / 2 >= 0.175, "Leaves do not sink below paving")
					var artwork: Texture2D = face.material_override.get_shader_parameter("artwork")
					var expected := "door-sealed" if magic else "door-leaves"
					if state == "damaged":
						expected = "door-sealed-damaged" if magic else "door-damaged"
					assert(artwork.resource_path.ends_with(expected + "-v3.png"), "Each state uses its own artwork")
					assert(is_equal_approx(face.material_override.get_shader_parameter("rune_energy"), 1.5 if magic and state != "opened" else 0.0))
	world.free()
	game.free()
	await process_frame
	print("OK: both mobile doors, four states, masonry alignment and hinged leaves")
	quit()
