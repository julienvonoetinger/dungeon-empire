extends SceneTree

func _initialize() -> void:
	var script = load("res://scripts/world/stone_floor_relief.gd")
	assert(script != null)
	assert(ResourceLoader.exists("res://assets/models/environment/floor_tile_trap_match_1x1.glb"))
	var renderer = script.new()
	root.add_child(renderer)
	var cells: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 1)]
	renderer.sync_cells(cells, 1.0)
	assert(renderer.get_child_count() == 1, "a 1x1 floor kit needs one direct instance batch")
	var batch = renderer.get_child(0)
	assert(batch.multimesh.instance_count == cells.size())
	var bounds: AABB = batch.multimesh.mesh.get_aabb()
	assert(bounds.position.x >= -0.0001 and bounds.position.z >= -0.0001)
	assert(bounds.end.x <= 1.0001 and bounds.end.z <= 1.0001)
	assert(bounds.size.x > 0.9 and bounds.size.z > 0.9, "the model must fill one logical cell")
	assert(bounds.position.y >= 0.03 and bounds.end.y > 0.15, "Meshy relief must render above the seamless backing plane")
	var orientations: Dictionary = {}
	for cell in cells:
		orientations[script.orientation_for(cell)] = true
	assert(orientations.size() >= 3, "coordinate-stable rotations must break obvious repetition")
	var reused_mesh = batch.multimesh.mesh
	renderer.sync_cells(cells, 1.0)
	assert(batch.multimesh.mesh == reused_mesh)
	var empty: Array[Vector2i] = []
	renderer.sync_cells(empty, 1.0)
	assert(batch.multimesh.instance_count == 0)
	renderer.free()
	var floor_mesh = load("res://scripts/world/floor_renderer.gd").new()
	root.add_child(floor_mesh)
	var inset: Array[Vector2i] = [Vector2i(0, 0)]
	floor_mesh.sync_cells(cells, 1.0, inset)
	assert(floor_mesh._relief.get_child(0).multimesh.instance_count == 3,
		"a trap replaces the floor relief in exactly one cell")
	floor_mesh.sync_cells(cells, 1.0)
	assert(floor_mesh._relief.get_child(0).multimesh.instance_count == 4)
	floor_mesh.free()
	print("OK: direct 1x1 Meshy floor cells, stable rotations and trap replacement")
	quit()
