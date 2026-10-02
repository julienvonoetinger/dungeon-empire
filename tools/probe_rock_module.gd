extends SceneTree

# Isolated art-validation fixture. Never mutates or loads a player save.
const MODULE := "res://assets/models/walls/rock_formation_reference_v1.glb"
const VARIANTS := [MODULE, "res://assets/models/walls/rock_crag_high_v1.glb", "res://assets/models/walls/rock_shelf_low_v1.glb"]
const EXTRA_VARIANTS := ["res://assets/models/walls/rock_compact_mid_v1.glb", "res://assets/models/walls/rock_split_mid_v1.glb", "res://assets/models/walls/rock_broken_low_v1.glb"]
var modules: Array[Node3D] = []
var rock_material: ShaderMaterial

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.mobile_ui.paused = true
	game.mobile_ui._cancel()
	game.mobile_ui.tray_collapsed = true
	game.mobile_ui._layout()
	for frame in 10:
		await process_frame
	for y in game.ROWS:
		for x in game.COLS:
			game.grid[y][x] = GameTypes.Tile.ROCK
	for y in range(6, 8):
		for x in range(5, 7):
			game.grid[y][x] = GameTypes.Tile.CORE
	for x in range(7, 15):
		game.grid[7][x] = GameTypes.Tile.VAULT if x < 11 else GameTypes.Tile.FLOOR
	game.grid[7][14] = GameTypes.Tile.ENTRANCE
	game.core_hp = 100
	game.gold = 60
	game.mobile_ui._cancel()
	game.mobile_ui._refresh()
	game.mobile_ui._layout()
	game.cam_zoom = 1.65
	game.cam_yaw = 45
	game.mobile_ui._center(Vector2i(9, 7))
	game._sync_world()
	for frame in 10:
		await process_frame
	game.set_process(false)
	var full_set := "--full-set" in OS.get_cmdline_user_args()
	var varied := full_set or "--variants" in OS.get_cmdline_user_args()
	var scenes: Array[PackedScene] = []
	var paths: Array = VARIANTS + EXTRA_VARIANTS if full_set else VARIANTS if varied else [MODULE]
	for path in paths:
		var packed: PackedScene = load(path)
		assert(packed != null, "Meshy module must be imported")
		_validate_module(packed, path)
		scenes.append(packed)
	rock_material = ShaderMaterial.new()
	rock_material.shader = load("res://assets/rendering/rock_strata.gdshader")
	rock_material.set_shader_parameter("stone", load("res://assets/mobile/bedrock-v2.png"))
	rock_material.set_shader_parameter("albedo_gain", 0.95)
	rock_material.set_shader_parameter("texture_scale", 0.38)
	rock_material.set_shader_parameter("bump_strength", 0.035)
	for i in 4:
		var back: int = [0, 1, 3, 4][i] if full_set else i % 2 if varied else 0
		var front: int = [2, 5, 3, 2][i] if full_set else 2 if varied and i % 2 == 0 else 0
		_add_module(game.dungeon, scenes[back], Vector3(4.5 + i * 2.8, 0, 4.3 if i < 2 else 5.1), 2.4, 1.25 + (i % 3) * 0.22, i * 90)
		_add_module(game.dungeon, scenes[front], Vector3(4.5 + i * 2.8, 0, 9.95), 2.4, 0.5 if front in [2, 5] else 0.9, 270 - i * 90)
	for yaw in [45, 135]:
		game.cam_yaw = yaw
		game.mobile_ui._center(Vector2i(9, 7))
		for shown in [true, false]:
			game.dungeon.set_mobile_walls_visible(shown)
			game._sync_world()
			game.mobile_ui._refresh()
			# Keep the existing geology as a low continuous bed, with a clear
			# transition band between the new modules and actual masonry.
			for cell in game.dungeon._cells.values():
				var mass: Node3D = cell.get_node_or_null("MobileRockMass")
				if mass != null:
					game.dungeon._mobile_walls.erase(mass)
					mass.scale.y = 0.16
			game.dungeon._mobile_backdrop.scale.y = 0.16
			for module in modules:
				module.scale.y = 1.0 if shown else 0.12
			for frame in 8:
				await process_frame
			var prefix := "meshy-rock-full-set" if full_set else "meshy-rock-variants" if varied else "meshy-rock-prototype"
			assert(root.get_texture().get_image().save_png("res://artifacts/%s-%s-%d.png" % [prefix, shown, yaw]) == OK)
	print("OK: isolated Meshy rock prototype captured; no runtime terrain replacement")
	game.queue_free()
	await process_frame
	quit()

func _validate_module(packed: PackedScene, path: String) -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var sample: Node3D = packed.instantiate()
	holder.add_child(sample)
	var bounds := _forward_bounds(holder)
	assert(bounds.size.x > 0 and bounds.size.y > 0 and bounds.size.z > 0)
	var triangles := 0
	for part in sample.find_children("*", "MeshInstance3D", true, false):
		for s in part.mesh.get_surface_count():
			var arrays: Array = part.mesh.surface_get_arrays(s)
			triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	print("MODULE ", path, " bounds=", bounds, " triangles=", triangles)
	assert(triangles > 0 and triangles <= 6000, "reference module must stay within a mobile prop budget")
	holder.free()

func _add_module(parent: Node3D, packed: PackedScene, position: Vector3, footprint: float, height: float, yaw: float) -> void:
	var holder := Node3D.new()
	holder.name = "RockReferencePrototype"
	parent.add_child(holder)
	var model: Node3D = packed.instantiate()
	holder.add_child(model)
	var bounds := _forward_bounds(holder)
	var horizontal := footprint / maxf(bounds.size.x, bounds.size.z)
	holder.scale = Vector3(horizontal, height / bounds.size.y, horizontal)
	model.position -= bounds.get_center() * Vector3(1, 0, 1)
	model.position.y -= bounds.position.y
	# Put scaling on a separate parent so rotation cannot skew the footprint.
	var placement := Node3D.new()
	parent.add_child(placement)
	holder.reparent(placement, false)
	holder.position.y = 0.04
	var fitted := _forward_bounds(placement)
	assert(is_equal_approx(fitted.size.y, height))
	assert(is_equal_approx(maxf(fitted.size.x, fitted.size.z), footprint))
	for part in model.find_children("*", "MeshInstance3D", true, false):
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part.material_override = rock_material
	placement.position = position
	placement.rotation_degrees.y = yaw
	modules.append(placement)

func _forward_bounds(parent: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for part in parent.find_children("*", "MeshInstance3D", true, false):
		var local: Transform3D = parent.global_transform.affine_inverse() * part.global_transform
		var bounds: AABB = local * part.get_aabb()
		result = bounds if first else result.merge(bounds)
		first = false
	return result
