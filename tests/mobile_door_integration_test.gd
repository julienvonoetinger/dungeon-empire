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
			if not magic and state == "opened":
				assert(is_zero_approx(world._cells[cell].get_node("MobileDoor/LeafHinge").rotation.y), "Opening starts at previous closed pose")
				await create_timer(0.30).timeout
			var holder: Node = world._cells[cell]
			assert(holder.get_node_or_null("DoorStateIcon") == null, "Mobile doors have no floating medallion")
			assert(holder.get_node_or_null("MagicDoorSeal") == null, "Runes belong to the leaves, not a floating ring")
			var door := holder.get_node_or_null("MobileDoor")
			assert(door != null, "Mobile door uses the integrated masonry frame")
			if not magic:
				assert(door.has_node("GothicFrame"), "Playable normal door uses the approved Meshy frame")
				var gothic_frame: MeshInstance3D = door.get_node("GothicFrame")
				assert(is_equal_approx(gothic_frame.mesh.get_aabb().size.y, 1.08))
				assert(is_equal_approx(door.position.y, 0.175))
				assert(door.has_node("WallConnections"))
				var joins: MeshInstance3D = door.get_node("WallConnections").get_child(0) if door.get_node("WallConnections").get_child_count() > 0 else door.get_node("WallConnections")
				world.set_mobile_walls_visible(false)
				assert(joins.mesh.get_aabb().end.y <= 0.231, "Door connections lower with hidden walls")
				world.set_mobile_walls_visible(true)
				assert(is_equal_approx(joins.mesh.get_aabb().end.y, 1.10))
				assert(gothic_frame.mesh.surface_get_material(0) is ShaderMaterial, "Arch shares the wall masonry shader")
				if state == "destroyed":
					assert(door.has_node("Rubble") and not door.has_node("LeafHinge"))
				else:
					var pivot: Node3D = door.get_node("LeafHinge")
					assert(is_equal_approx(pivot.rotation.y, -PI / 2 if state == "opened" else 0.0))
					assert(pivot.get_child_count() == 1)
					assert(pivot.get_child(0).mesh.resource_path.ends_with("gothic-door-leaf.res"))
				continue
			var frame: MeshInstance3D = door.get_node("MasonryFrame")
			assert(frame.mesh.get_aabb().size.z >= 0.27, "Frame has wall thickness")
			assert(is_equal_approx(frame.mesh.get_aabb().end.y, 1.10), "Coping aligns with corridor walls")
			for vertex in frame.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				if vertex.y < 0.89:
					assert(absf(vertex.x) >= 0.4749, "Only the thin frame reveal projects into the passage")
			assert(door.find_children("*", "Sprite3D", true, false).is_empty(), "Door stays volumetric from every side")
			if state == "destroyed":
				assert(door.has_node("Rubble") and not door.has_node("LeftHinge"))
			else:
				for side in ["LeftHinge", "RightHinge"]:
					var hinge: Node3D = door.get_node(side)
					assert(is_equal_approx(absf(hinge.rotation.y), PI / 2 if state == "opened" else 0.0))
					var face: MeshInstance3D = hinge.get_node("Front")
					if not magic and state in ["closed", "opened"]:
						assert(hinge.has_node("PrototypeLeaf"), "Normal door uses dimensional timber and ironwork")
						assert(not face.visible, "Prototype must not stretch the old painted door")
						for part in hinge.get_node("PrototypeLeaf").get_children():
							var prototype_bounds: AABB = hinge.transform * part.get_aabb()
							assert(prototype_bounds.position.x >= -0.475 and prototype_bounds.end.x <= 0.475, "Prototype clears frame when opened or closed")
					var body: MeshInstance3D = hinge.get_node("LeafThickness")
					var bounds: AABB = hinge.transform * body.transform * body.get_aabb()
					assert(bounds.position.x >= -0.5 and bounds.end.x <= 0.5, "Closed and opened leaves clear both jambs")
					if state != "opened":
						var center_x := hinge.position.x + face.position.x
						assert(absf(center_x) + face.mesh.size.x / 2 <= 0.5, "Leaves stay inside the passage")
						assert(face.mesh.size.x > 0.47, "Two leaves cover the full passage without narrowing it")
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
