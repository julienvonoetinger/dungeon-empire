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
		var first_batches := _collect_batches(first)
		var second_batches := _collect_batches(second)
		check(first.get_child_count() <= 65, "backdrop stays within 65 scene nodes")
		var first_node_count := first.get_child_count()
		first.build(16, 16)
		check(first.get_child_count() == first_node_count, "rebuilding same dimensions does not duplicate backdrop nodes")
		var instances := 0
		var footprint_ok := true
		var footprint_detail := ""
		for batch in first_batches:
			instances += batch.multimesh.instance_count
			var instance_data: PackedFloat32Array = batch.multimesh.buffer
			if instance_data.size() != batch.multimesh.instance_count * 12:
				continue
			for index in batch.multimesh.instance_count:
				var instance_transform: Transform3D = batch.multimesh.get_instance_transform(index)
				var bounds: AABB = instance_transform * batch.multimesh.mesh.get_aabb()
				if bounds.position.x < 16.0 and bounds.end.x > 0.0 and bounds.position.z < 16.0 and bounds.end.z > 0.0:
					footprint_ok = false
					if footprint_detail.is_empty():
						footprint_detail = "%s transform=%s" % [bounds, instance_transform]
		check(instances == 2880, "backdrop builds exactly 2880 rock instances")
		check(footprint_ok, "transformed rock footprint stays outside the playable map: " + footprint_detail)
		check(_batch_signature(first_batches) == _batch_signature(second_batches), "backdrop placement is deterministic")
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

func _collect_batches(root_node: Node) -> Array[MultiMeshInstance3D]:
	var batches: Array[MultiMeshInstance3D] = []
	for child in root_node.find_children("*", "MultiMeshInstance3D", true, false):
		batches.append(child)
	return batches

func _batch_signature(batches: Array[MultiMeshInstance3D]) -> Array:
	var signature: Array = []
	for batch in batches:
		var positions: Array = []
		for index in batch.multimesh.instance_count:
			positions.append(batch.multimesh.get_instance_transform(index))
		positions.sort_custom(func(a, b): return str(a) < str(b))
		signature.append(positions)
	return signature
