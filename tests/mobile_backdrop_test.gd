extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var world_script := load("res://scripts/world/dungeon_world.gd")
	var world = world_script.new()
	root.add_child(world)
	call_deferred("_run", world)

func _run(world: Node) -> void:
	check(world.has_method("limit_mobile_camera"), "world provides pure mobile camera limiter")
	var backdrop_path := "res://scripts/world/mobile_backdrop.gd"
	check(ResourceLoader.exists(backdrop_path), "mobile decorative backdrop module exists")
	if ResourceLoader.exists(backdrop_path):
		var backdrop_script = load(backdrop_path)
		var constants: Dictionary = backdrop_script.get_script_constant_map()
		check(int(constants.get("MARGIN", -1)) == 20, "backdrop ring margin is 20 tiles")
		check(int(constants.get("CHUNK", -1)) == 8, "backdrop chunks are 8 tiles")
		var first: Node3D = backdrop_script.new()
		var second: Node3D = backdrop_script.new()
		root.add_child(first)
		root.add_child(second)
		first.build(16, 16)
		second.build(16, 16)
		var first_batches := _collect_rock_batches(first)
		var second_batches := _collect_rock_batches(second)
		check(first.get_child_count() <= 7, "backdrop stays within seven scene nodes")
		check(first.get_node_or_null("RockUnderlay") is MeshInstance3D, "backdrop has a continuous rock underlay")
		check(first_batches.size() == 6, "backdrop creates six MultiMesh rock batches")
		var first_node_count := first.get_child_count()
		var original_signature := _batch_signature(first_batches)
		var original_ids := _resource_ids(first, first_batches)
		first.build(16, 16)
		check(first.get_child_count() == first_node_count, "rebuilding same dimensions does not duplicate backdrop nodes")
		check(_batch_signature(_collect_rock_batches(first)) == original_signature, "rebuilding same dimensions retains exact transforms")
		check(_resource_ids(first, _collect_rock_batches(first)) == original_ids,
			"rebuilding same dimensions does not recreate meshes or MultiMeshes")
		var outside_playable := true
		var triangle_count := 0
		var bad_bounds := ""
		var exterior_sides := {"left": false, "right": false, "top": false, "bottom": false}
		var check_gpu_transforms := DisplayServer.get_name() != "headless"
		var underlay: MeshInstance3D = first.get_node("RockUnderlay")
		var underlay_arrays: Array = underlay.mesh.surface_get_arrays(0)
		var underlay_indices: PackedInt32Array = underlay_arrays[Mesh.ARRAY_INDEX]
		triangle_count += underlay_indices.size() / 3
		for batch in first_batches:
			var multimesh: MultiMesh = batch.multimesh
			if multimesh == null or multimesh.mesh == null:
				outside_playable = false
				continue
			var mesh: Mesh = multimesh.mesh
			var arrays: Array = mesh.surface_get_arrays(0)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var placements: Array = batch.get_meta("placements", [])
			check(placements.size() == multimesh.instance_count,
				"CPU placement table matches batch instance count for " + batch.name)
			triangle_count += indices.size() / 3 * placements.size()
			var mesh_bounds: AABB = mesh.get_aabb()
			for instance_index in placements.size():
				var transform: Transform3D = placements[instance_index]
				if check_gpu_transforms:
					check(multimesh.get_instance_transform(instance_index) == transform,
						"rendered instance transform matches CPU placement for %s[%d]" % [batch.name, instance_index])
				var bounds: AABB = batch.global_transform * transform * mesh_bounds
				if bounds.end.x <= 0.0001 and bounds.end.z > 0 and bounds.position.z < 16:
					exterior_sides.left = true
				if bounds.position.x >= 15.9999 and bounds.end.z > 0 and bounds.position.z < 16:
					exterior_sides.right = true
				if bounds.end.z <= 0.0001 and bounds.end.x > 0 and bounds.position.x < 16:
					exterior_sides.top = true
				if bounds.position.z >= 15.9999 and bounds.end.x > 0 and bounds.position.x < 16:
					exterior_sides.bottom = true
				if bounds.position.x < 16 and bounds.end.x > 0 and bounds.position.z < 16 and bounds.end.z > 0:
					outside_playable = false
					if bad_bounds.is_empty():
						bad_bounds = "%s[%s,%s] z[%s,%s] instance=%s mesh=%s" % [batch.name, bounds.position.x, bounds.end.x, bounds.position.z, bounds.end.z, transform.origin, mesh_bounds]
		check(exterior_sides.left and exterior_sides.right and exterior_sides.top and exterior_sides.bottom,
			"transformed batches provide exterior rock coverage on all four map sides")
		print("Backdrop triangle budget: ", triangle_count)
		check(triangle_count > 0 and triangle_count < 500000, "exterior backdrop stays below the 500000 triangle budget")
		check(outside_playable, "transformed rock instance bounds stay outside the playable map: " + bad_bounds)
		check(_batch_signature(first_batches) == _batch_signature(second_batches), "backdrop transforms are deterministic")
		for variant in 6:
			check(first_batches[variant].multimesh.mesh == second_batches[variant].multimesh.mesh,
				"backdrop variants share cached meshes across instances")
		first.queue_free()
		second.queue_free()
	if world.has_method("limit_mobile_camera"):
		var views := [Vector2(360, 800), Vector2(800, 800), Vector2(1280, 720), Vector2(1600, 600)]
		for view in views:
			for yaw in [45.0, 135.0, 225.0, 315.0]:
				var result: Dictionary = world.limit_mobile_camera(0.05, Vector2(100000, -100000), view, 16, 16, yaw)
				check(result.has("zoom") and result.has("pan"), "camera limiter returns zoom and pan for %s at yaw %s" % [view, yaw])
				if result.has("zoom") and result.has("pan"):
					var aspect: float = view.x / view.y
					var angle: float = deg_to_rad(yaw)
					var depth: float = 1.0 / sin(absf(deg_to_rad(float(world.PITCH))))
					var extent := maxf(absf(cos(angle)) * aspect + absf(sin(angle)) * depth,
						absf(sin(angle)) * aspect + absf(cos(angle)) * depth)
					var ground_extent: float = world.ortho_size(float(result.zoom)) * extent * 0.5
					check(float(result.zoom) >= 1.2 and ground_extent <= 18.0001, "zoom keeps ground frustum within backdrop margin at %s yaw %s" % [view, yaw])
					check(result.pan is Vector2 and is_finite(result.pan.x) and is_finite(result.pan.y), "limited camera pan is finite")
					var basis := Basis.from_euler(Vector3(deg_to_rad(float(world.PITCH)), angle, 0))
					var right := Vector3(basis.x.x, 0, basis.x.z).normalized()
					var forward := Vector3(-basis.z.x, 0, -basis.z.z).normalized()
					var k: float = world.ortho_size(float(result.zoom)) / view.y
					var look: Vector3 = world.map_center(16, 16) + right * result.pan.x * k - forward * result.pan.y * k
					check(look.x >= -0.0001 and look.x <= 16.0001 and look.z >= -0.0001 and look.z <= 16.0001,
						"camera look stays inside the playable map at yaw %s" % yaw)
	print("mobile_backdrop_test: %d failures" % failures)
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _collect_rock_batches(root_node: Node) -> Array[MultiMeshInstance3D]:
	var batches: Array[MultiMeshInstance3D] = []
	for variant in 6:
		var batch := root_node.get_node_or_null("RockBatch_%d" % variant) as MultiMeshInstance3D
		if batch != null:
			batches.append(batch)
	return batches


func _batch_signature(batches: Array[MultiMeshInstance3D]) -> Array:
	var signature: Array = []
	for batch in batches:
		var multimesh: MultiMesh = batch.multimesh
		var transforms: Array = batch.get_meta("placements", [])
		signature.append([batch.name, multimesh.mesh, transforms])
	return signature


func _resource_ids(root_node: Node, batches: Array[MultiMeshInstance3D]) -> Array[int]:
	var ids: Array[int] = [root_node.get_node("RockUnderlay").mesh.get_instance_id()]
	for batch in batches:
		ids.append(batch.multimesh.get_instance_id())
		ids.append(batch.multimesh.mesh.get_instance_id())
	return ids
