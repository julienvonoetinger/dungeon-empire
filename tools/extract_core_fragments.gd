extends SceneTree
## Recover independent stones from the existing Meshy model, retaining its UVs.

const SOURCE := "res://assets/models/core_void_nexus.glb"
const OUTPUT := "res://assets/models/core_fragments"
var parents: PackedInt32Array

func _initialize() -> void:
	var scene := (load(SOURCE) as PackedScene).instantiate()
	var source: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var arrays := source.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	parents.resize(positions.size())
	var welded := {}
	for index in positions.size():
		parents[index] = index
		var key := Vector3i((positions[index] * 10000.0).round())
		if welded.has(key):
			parents[_find(index)] = _find(welded[key])
		else:
			welded[key] = index
	for index in range(0, indices.size(), 3):
		parents[_find(indices[index + 1])] = _find(indices[index])
		parents[_find(indices[index + 2])] = _find(indices[index])
	var groups := {}
	for index in indices:
		var group := _find(index)
		if not groups.has(group):
			groups[group] = []
		groups[group].append(index)
	var candidates: Array = []
	for group in groups.values():
		var bounds := AABB(positions[group[0]], Vector3.ZERO)
		for index in group:
			bounds = bounds.expand(positions[index])
		var center := bounds.get_center()
		# Exclude the pedestal, fused central orb and flat halo cards.
		if group.size() > 100 and bounds.size.z > 0.04 and center.y > -0.15 and (absf(center.x) > 0.12 or center.y > 0.28):
			candidates.append({"indices": group, "bounds": bounds})
	candidates.sort_custom(func(a, b): return a.indices.size() > b.indices.size())
	if candidates.size() < 7:
		printerr("FAIL: expected seven separate Meshy stones")
		scene.free()
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for part in 7:
		var candidate: Dictionary = candidates[part]
		var bounds: AABB = candidate.bounds
		var scale := bounds.size[bounds.size.max_axis_index()]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in candidate.indices:
			st.set_normal(normals[index])
			st.set_uv(uvs[index])
			st.add_vertex((positions[index] - bounds.get_center()) / scale)
		st.generate_tangents()
		st.index()
		var mesh := st.commit()
		var path := "%s/fragment_%d.res" % [OUTPUT, part]
		var result := ResourceSaver.save(mesh, path)
		if result != OK:
			printerr("FAIL: saving ", path)
			scene.free()
			quit(1)
			return
		print("Extracted ", path, " triangles=", candidate.indices.size() / 3)
	scene.free()
	quit()

func _find(index: int) -> int:
	while parents[index] != index:
		parents[index] = parents[parents[index]]
		index = parents[index]
	return index
