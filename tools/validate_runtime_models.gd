extends SceneTree

const WORLD_SCRIPT_PATH := "res://scripts/world/dungeon_world.gd"
const ModelFitScript := preload("res://scripts/world/model_fit.gd")

func _initialize() -> void:
	var source := FileAccess.get_file_as_string(WORLD_SCRIPT_PATH)
	var pattern := RegEx.new()
	pattern.compile("const\\s+[A-Z0-9_]+_GLB\\s*:=\\s*\"([^\"]+)\"")
	var paths: Array[String] = []
	for result in pattern.search_all(source):
		var path := result.get_string(1)
		if not paths.has(path):
			paths.append(path)
	paths.sort()
	var failures: Array[String] = []
	for path in paths:
		_validate_model(path, failures)
	if paths.is_empty():
		failures.append("no runtime GLB constants found")
	if failures.is_empty():
		print("OK: validated %d runtime models" % paths.size())
		quit()
		return
	for failure in failures:
		printerr("FAIL: ", failure)
	quit(1)

func _validate_model(path: String, failures: Array[String]) -> void:
	if not ResourceLoader.exists(path):
		failures.append("missing model: %s" % path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("model is not a PackedScene: %s" % path)
		return
	var instance := packed.instantiate()
	var measured: AABB = ModelFitScript.bounds(instance)
	var meshes := _count_meshes(instance)
	var materials := _count_materials(instance)
	if meshes == 0 or measured.size == Vector3.ZERO:
		failures.append("model contains no measurable geometry: %s" % path)
	else:
		print("MODEL %s | size=%s | bottom=%.4f | meshes=%d | materials=%d" % [path, measured.size, measured.position.y, meshes, materials])
	instance.free()

func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count

func _count_materials(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				if mesh_instance.get_active_material(surface) != null:
					count += 1
	for child in node.get_children():
		count += _count_materials(child)
	return count
