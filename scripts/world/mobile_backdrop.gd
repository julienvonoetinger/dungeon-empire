extends Node3D

const MARGIN := 20
const CHUNK := 8
var _dimensions := Vector2i.ZERO

func build(cols: int, rows: int) -> void:
	if _dimensions == Vector2i(cols, rows):
		return
	_dimensions = Vector2i(cols, rows)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var surfaces := preload("res://scripts/world/mobile_surfaces.gd")
	var variants: Array[ArrayMesh] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 73129
	for i in 4:
		variants.append(surfaces.rock(Vector2i(i + 71, 93), Vector2.ZERO, Vector2.ONE))
	# Chunked instances allow offscreen sectors to be culled as a whole.
	for z in range(-MARGIN, rows + MARGIN, CHUNK):
		for x in range(-MARGIN, cols + MARGIN, CHUNK):
			var cells: Array[Vector2i] = []
			for iz in range(z, mini(z + CHUNK, rows + MARGIN)):
				for ix in range(x, mini(x + CHUNK, cols + MARGIN)):
					if ix < 0 or iz < 0 or ix >= cols or iz >= rows:
						cells.append(Vector2i(ix, iz))
			if cells.is_empty():
				continue
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.mesh = variants[rng.randi_range(0, 3)]
			instances.instance_count = cells.size()
			for i in cells.size():
				var cell := cells[i]
				var angle := float(rng.randi_range(0, 3)) * PI * 0.5
				var basis := Basis(Vector3.UP, angle).scaled(Vector3(1, rng.randf_range(0.85, 1.1), 1))
				var origin := Vector3(cell.x + 0.5, 0, cell.y + 0.5) - basis * Vector3(0.5, 0, 0.5)
				instances.set_instance_transform(i, Transform3D(basis, origin))
			var batch := MultiMeshInstance3D.new()
			batch.multimesh = instances
			batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(batch)
	var bed := MeshInstance3D.new()
	bed.name = "RockUnderlay"
	var slab := BoxMesh.new()
	slab.size = Vector3(cols + MARGIN * 2, 0.2, rows + MARGIN * 2)
	bed.mesh = slab
	bed.position = Vector3(cols * 0.5, -0.55, rows * 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/mobile/bedrock-v1.png")
	material.albedo_color = Color("555b61")
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.24
	material.roughness = 1.0
	bed.material_override = material
	bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bed)
