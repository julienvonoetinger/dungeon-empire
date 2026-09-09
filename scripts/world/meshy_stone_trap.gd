extends Node3D
## Real Meshy variants fitted by perimeter paving, never by the spike/claw tips.

const DIRECTORY := "res://assets/models/traps/"
const ASSETS := {
	"spike": {"armed": "paver_v3/spike_armed.glb", "sprung": "paver_v3/spike_sprung.glb", "broken": "paver_v3/spike_broken.glb"},
	"snare": {"armed": "paver_v3/snare_armed.glb", "sprung": "paver_v3/snare_sprung.glb", "broken": "paver_v3/snare_broken.glb"},
	"void": {"armed": "paver_v3/void_armed.glb", "sprung": "paver_v3/void_sprung.glb", "broken": "paver_v3/void_broken.glb"},
}
const FLOOR_LEVEL := 0.175
static var _fits: Dictionary = {}
var kind := "spike"
var state := "armed"
var model: Node3D

func configure(family: String, initial_state: String) -> bool:
	name = "StoneTrap"
	kind = family
	return set_state(initial_state)

func set_state(value: String) -> bool:
	if not ASSETS.has(kind) or not ASSETS[kind].has(value):
		return false
	var path: String = DIRECTORY + str(ASSETS[kind][value])
	if not ResourceLoader.exists(path):
		push_error("Meshy trap model missing: " + path)
		return false
	var replacement := (load(path) as PackedScene).instantiate() as Node3D
	if not _fits.has(path):
		var vertices: Array[Vector3] = []
		var normals: Array[Vector3] = []
		_collect(replacement, Transform3D.IDENTITY, vertices, normals)
		if vertices.is_empty():
			replacement.free()
			return false
		var bounds := AABB(vertices[0], Vector3.ZERO)
		for vertex in vertices:
			bounds = bounds.expand(vertex)
		var vertical_scale := 1.0 / maxf(bounds.size.x, bounds.size.z)
		var scale := Vector3(1.0 / bounds.size.x, vertical_scale, 1.0 / bounds.size.z)
		var perimeter_heights: Array[float] = []
		for index in vertices.size():
			var nx := (vertices[index].x - bounds.position.x) / bounds.size.x
			var nz := (vertices[index].z - bounds.position.z) / bounds.size.z
			if normals[index].y > 0.65 and (absf(nx - 0.5) > 0.35 or absf(nz - 0.5) > 0.35):
				perimeter_heights.append(vertices[index].y * vertical_scale)
		if perimeter_heights.is_empty():
			replacement.free()
			push_error("Cannot determine trap base surface: " + path)
			return false
		perimeter_heights.sort()
		var base_surface := perimeter_heights[int((perimeter_heights.size() - 1) * 0.70)]
		var origin := Vector3(-bounds.position.x * scale.x,
			FLOOR_LEVEL - base_surface,
			-bounds.position.z * scale.z)
		_fits[path] = Transform3D(Basis.from_scale(scale), origin)
	replacement.transform = _fits[path] * replacement.transform
	_prepare_materials(replacement)
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	model = replacement
	add_child(model)
	state = value
	return true

func model_bounds() -> AABB:
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	_collect(model, Transform3D.IDENTITY, vertices, normals)
	if vertices.is_empty():
		return AABB()
	var result := AABB(vertices[0], Vector3.ZERO)
	for vertex in vertices:
		result = result.expand(vertex)
	return result

func measured_walking_height() -> float:
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	_collect(model, Transform3D.IDENTITY, vertices, normals)
	var heights: Array[float] = []
	for index in vertices.size():
		var point := vertices[index]
		if normals[index].y > 0.65 and (absf(point.x - 0.5) > 0.35 or absf(point.z - 0.5) > 0.35):
			heights.append(point.y)
	heights.sort()
	return heights[int((heights.size() - 1) * 0.70)] if not heights.is_empty() else -INF

func _collect(node: Node, parent: Transform3D, vertices: Array[Vector3], normals: Array[Vector3]) -> void:
	var transform := parent
	if node is Node3D:
		transform *= node.transform
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var normal_basis := transform.basis.inverse().transposed()
			for index in positions.size():
				vertices.append(transform * positions[index])
				normals.append((normal_basis * source_normals[index]).normalized())
	for child in node.get_children():
		_collect(child, transform, vertices, normals)

func _prepare_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var source := node.get_active_material(surface) as BaseMaterial3D
			if source != null:
				var material := source.duplicate() as BaseMaterial3D
				material.metallic = 0.0
				material.roughness = 0.94
				material.normal_scale = 0.25
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				node.set_surface_override_material(surface, material)
	for child in node.get_children():
		_prepare_materials(child)
