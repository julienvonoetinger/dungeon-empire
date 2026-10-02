extends SceneTree

class RockMap:
	extends Node
	const COLS := 16
	const ROWS := 16
	const Tile = GameTypes.Tile
	var grid: Array = []
	func _init() -> void:
		for y in ROWS:
			var row := []
			row.resize(COLS)
			row.fill(Tile.ROCK)
			grid.append(row)
	func _inside(p: Vector2i) -> bool:
		return p.x >= 0 and p.y >= 0 and p.x < COLS and p.y < ROWS

func _initialize() -> void:
	var path := "res://scripts/world/mobile_rock_library.gd"
	if not ResourceLoader.exists(path):
		push_error("runtime Meshy rock library missing")
		quit(1)
		return
	var library = load(path)
	var mesh_ids := {}
	for i in 6:
		var mesh: Mesh = library.mesh(i)
		assert(mesh != null)
		assert(mesh == library.mesh(i), "meshes must be shared")
		mesh_ids[mesh.get_instance_id()] = true
		var bounds := mesh.get_aabb()
		assert(absf(bounds.position.y) < 0.001)
		assert(is_equal_approx(bounds.size.y, 1.0))
		assert(maxf(bounds.size.x, bounds.size.z) <= 1.001)
		assert(mesh.surface_get_material(0) == library.material())
	assert(mesh_ids.size() == 6, "six distinct meshes are used")
	var heights := {}
	for y in 16:
		for x in 16:
			var cell := Vector2i(x, y)
			var a: Dictionary = library.placement(cell)
			assert(a == library.placement(cell), "placement is deterministic")
			assert(a.variant >= 0 and a.variant < 6)
			heights[a.height] = true
	assert(heights.size() > 6, "heights must vary independently of model")
	var world = load("res://scripts/world/dungeon_world.gd").new()
	var map := RockMap.new()
	assert(world._mobile_rock_group_full(Vector2i(4, 4), map))
	assert(world._mobile_rock_group_full(Vector2i(5, 5), map))
	map.grid[3][3] = GameTypes.Tile.FLOOR
	assert(not world._mobile_rock_group_full(Vector2i(5, 5), map), "diagonal excavation rebuilds the whole group")
	map.grid[3][3] = GameTypes.Tile.ROCK
	map.grid[4][6] = GameTypes.Tile.FLOOR
	assert(not world._mobile_rock_group_full(Vector2i(4, 4), map), "large formations leave a low shoulder near walls")
	world.free()
	map.free()
	print("mobile_rock_library_test: PASS")
	quit()
