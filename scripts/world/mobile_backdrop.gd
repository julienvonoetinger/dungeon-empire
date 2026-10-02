extends Node3D

const MARGIN := 20
const CHUNK := 8
const SPACING := 2.0
const ROCKS := preload("res://scripts/world/mobile_rock_library.gd")
var _dimensions := Vector2i.ZERO

func build(cols: int, rows: int) -> void:
	if _dimensions == Vector2i(cols, rows):
		return
	_dimensions = Vector2i(cols, rows)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var transforms: Array = [[], [], [], [], [], []]
	for z in range(-MARGIN, rows + MARGIN, int(SPACING)):
		for x in range(-MARGIN, cols + MARGIN, int(SPACING)):
			if x >= 0 and z >= 0 and x < cols and z < rows:
				continue
			var data := ROCKS.placement(Vector2i(x, z))
			var width: float = SPACING * data.width
			var height: float = data.height
			var basis := Basis(Vector3.UP, data.yaw).scaled(Vector3(width, height, width))
			var transform := Transform3D(basis, Vector3(x + SPACING * 0.5, 0.025, z + SPACING * 0.5))
			transforms[data.variant].append(transform)
	# Six shared low-detail meshes; no source GLB textures are loaded at runtime.
	for variant in 6:
		var batch := MultiMeshInstance3D.new()
		batch.name = "RockBatch_%d" % variant
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = ROCKS.mesh(variant, true)
		instances.instance_count = transforms[variant].size()
		for i in instances.instance_count:
			instances.set_instance_transform(i, transforms[variant][i])
		batch.multimesh = instances
		# Retain CPU placement data for bounds checks with the headless dummy renderer.
		batch.set_meta("placements", transforms[variant])
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(batch)
	var bed := MeshInstance3D.new()
	bed.name = "RockUnderlay"
	var slab := BoxMesh.new()
	slab.size = Vector3(cols + MARGIN * 2, 0.08, rows + MARGIN * 2)
	bed.mesh = slab
	bed.position = Vector3(cols * 0.5, -0.025, rows * 0.5)
	bed.material_override = ROCKS.material()
	bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bed)
