class_name FloorRenderer
extends MeshInstance3D

const FLOOR_TEXTURE := preload("res://production/textures/floor/floor_controlled_seamless.png")
const STONE_RELIEF := preload("res://scripts/world/stone_floor_relief.gd")

var _signature := ""
var mobile_mode := false
var _relief: Node3D

func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func sync_cells(open_cells: Array[Vector2i], cell_size: float, inset_cells: Array[Vector2i] = [], treasury_cells: Array[Vector2i] = [], empty_treasury_cells: Array[Vector2i] = [], spike_cells: Array[Vector2i] = [], snare_cells: Array[Vector2i] = [], void_cells: Array[Vector2i] = []) -> void:
	var ordered := open_cells.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var signature := "%s|%.4f|%s|%s|%s|%s|%s" % [str(ordered), cell_size, str(inset_cells), mobile_mode, str(treasury_cells), str(empty_treasury_cells), str(spike_cells)]
	signature += "|" + str(snare_cells)
	signature += "|" + str(void_cells)
	if signature == _signature:
		return
	_signature = signature
	if _relief == null and not mobile_mode:
		_relief = STONE_RELIEF.new()
		_relief.name = "MeshyStoneRelief"
		add_child(_relief)
	# A trap directly replaces this 1x1 relief instance. Its own base surface is
	# aligned to the same height, so no second slab remains visible underneath.
	var relief_cells: Array[Vector2i] = []
	for cell in ordered:
		if not inset_cells.has(cell):
			relief_cells.append(cell)
	if _relief != null:
		_relief.visible = not mobile_mode
		if not mobile_mode:
			_relief.sync_cells(relief_cells, cell_size)
	if ordered.is_empty():
		mesh = null
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var edge_masks := PackedVector2Array()
	var occupied := {}
	for cell in ordered:
		occupied[cell] = true
	var indices := PackedInt32Array()
	for cell in ordered:
		if mobile_mode:
			var mask := 0
			var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			for side in 4:
				if not occupied.has(cell + directions[side]):
					mask |= 1 << side
			for corner in 4:
				var state := (2.0 if empty_treasury_cells.has(cell) else 1.0) if treasury_cells.has(cell) else 0.0
				if spike_cells.has(cell):
					state = 3.0
				if snare_cells.has(cell):
					state = 4.0
				if void_cells.has(cell):
					state = 5.0
				edge_masks.append(Vector2(mask, state))
		var surface_y := 0.175 if mobile_mode else 0.12
		var x0 := float(cell.x) * cell_size
		var z0 := float(cell.y) * cell_size
		var x1 := x0 + cell_size
		var z1 := z0 + cell_size
		var base := vertices.size()
		vertices.append_array(PackedVector3Array([
			Vector3(x0, surface_y, z0), Vector3(x1, surface_y, z0),
			Vector3(x1, surface_y, z1), Vector3(x0, surface_y, z1),
		]))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
		uvs.append_array(PackedVector2Array([
			Vector2(float(cell.x), float(cell.y)), Vector2(float(cell.x + 1), float(cell.y)),
			Vector2(float(cell.x + 1), float(cell.y + 1)), Vector2(float(cell.x), float(cell.y + 1)),
		]))
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	if mobile_mode:
		arrays[Mesh.ARRAY_TEX_UV2] = edge_masks
	arrays[Mesh.ARRAY_INDEX] = indices
	var generated := ArrayMesh.new()
	generated.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	generated.surface_set_material(0, _make_material())
	mesh = generated

func surface_count() -> int:
	return 0 if mesh == null else mesh.get_surface_count()

func _make_material() -> Material:
	if mobile_mode:
		var stone := ShaderMaterial.new()
		stone.shader = preload("res://assets/rendering/rock_strata.gdshader")
		stone.set_shader_parameter("stone", load("res://assets/mobile/floor-pavers-v4.png"))
		stone.set_shader_parameter("texture_scale", 0.4)
		stone.set_shader_parameter("albedo_gain", 1.05)
		stone.set_shader_parameter("bump_strength", 0.025)
		stone.set_shader_parameter("floor_edges", true)
		stone.set_shader_parameter("spike_stone", preload("res://assets/mobile/spike-floor-v1.png"))
		stone.set_shader_parameter("snare_stone", preload("res://assets/mobile/snare-floor-v1.png"))
		stone.set_shader_parameter("void_stone", preload("res://assets/mobile/void-floor-v1.png"))
		stone.set_shader_parameter("treasury_stone", preload("res://assets/mobile/treasury-floor-v1.png"))
		stone.set_shader_parameter("treasury_empty", preload("res://assets/mobile/treasury-floor-empty-v1.png"))
		stone.set_shader_parameter("boundary_stone", load("res://assets/mobile/masonry-grain-v2.png"))
		return stone
	var material := StandardMaterial3D.new()
	material.albedo_texture = FLOOR_TEXTURE
	material.uv1_scale = Vector3(0.25, 0.25, 1.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.roughness = 0.9
	material.metallic = 0.0
	return material
