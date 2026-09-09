extends Node3D
## Presentation only. The same void and fragments survive every living HP state.

const PEDESTAL := preload("res://assets/models/core_void_nexus.glb")
const VOID_SHADER := preload("res://assets/rendering/core_void.gdshader")
const HALO_SHADER := preload("res://assets/rendering/core_halo.gdshader")
const PEDESTAL_SHADER := preload("res://assets/rendering/core_pedestal.gdshader")
const FLOOR_LEVEL := 0.175
const CONTENT_LIFT := FLOOR_LEVEL - 0.13
const CENTER := Vector3(0.0, 1.05 + CONTENT_LIFT, 0.0)
const RADIUS := 0.46
const ORBIT := 0.76

var _void: MeshInstance3D
var _halo: MeshInstance3D
var _halo_material: ShaderMaterial
var _fragments: Node3D
var _age := 0.0
var _health := 1.0
# A tilted 3D orbit, aligned with the default overview rather than a flat floor ring.
var _orbit_basis := Basis(Vector3.UP, PI / 4.0) * Basis(Vector3.RIGHT, deg_to_rad(-40.0))

func _init() -> void:
	name = "CoreAnomaly"
	_build_pedestal()
	_void = MeshInstance3D.new()
	_void.name = "Void"
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	_void.mesh = sphere
	var black := ShaderMaterial.new()
	black.shader = VOID_SHADER
	_void.material_override = black
	_void.position = CENTER
	add_child(_void)
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * (RADIUS / 0.398)
	_halo.mesh = quad
	_halo_material = ShaderMaterial.new()
	_halo_material.shader = HALO_SHADER
	_halo.material_override = _halo_material
	_halo.position = CENTER
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)
	_fragments = Node3D.new()
	_fragments.name = "Fragments"
	add_child(_fragments)
	for index in 7:
		var rock := MeshInstance3D.new()
		rock.name = "Fragment%d" % index
		rock.mesh = load("res://assets/models/core_fragments/fragment_%d.res" % index)
		var stone := StandardMaterial3D.new()
		stone.albedo_texture = preload("res://assets/models/core_void_nexus_base_color.jpg")
		stone.normal_enabled = true
		stone.normal_texture = preload("res://assets/models/core_void_nexus_normal.jpg")
		stone.normal_scale = 0.65
		stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		stone.roughness = 0.94
		stone.metallic = 0.0
		rock.material_override = stone
		rock.scale = Vector3.ONE * 0.31 * (0.85 + float(index % 3) * 0.15)
		_fragments.add_child(rock)
	set_health(100)

func set_health(hp: int) -> void:
	_health = clampf(float(hp) / 100.0, 0.0, 1.0)
	_void.visible = hp > 0
	_halo.visible = hp > 0
	_halo_material.set_shader_parameter("instability", 1.0 - _health)
	_update_fragments()

func light_strength() -> float:
	return 0.0 if _health <= 0.0 else lerpf(0.38, 0.68, _health)

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if _health <= 0.0:
		return
	_age += delta
	_halo_material.set_shader_parameter("phase", _age)
	_update_fragments()

func _update_fragments() -> void:
	for index in _fragments.get_child_count():
		var rock := _fragments.get_child(index) as Node3D
		var angle := float(index) * TAU / 7.0 + 0.2
		if _health <= 0.0:
			rock.position = Vector3(cos(angle) * 0.63, 0.27 + CONTENT_LIFT, sin(angle) * 0.63)
			rock.rotation = Vector3(1.2, angle, 0.3)
			continue
		angle += _age * 0.055
		var spread := ORBIT + (1.0 - _health) * 0.08
		var local := Vector3(cos(angle) * spread, sin(angle) * spread,
			sin(angle * 2.0) * 0.08 + sin(_age * 0.65 + index) * 0.025)
		rock.position = CENTER + _orbit_basis * local
		rock.rotation = Vector3(0.2 + sin(_age * 0.3 + index) * 0.12, angle * 0.45, -angle + 0.4)

func _build_pedestal() -> void:
	var base := PEDESTAL.instantiate()
	base.name = "Pedestal"
	base.scale = Vector3(1.48, 0.52, 1.48)
	base.position.y = FLOOR_LEVEL + 0.4727 * base.scale.y
	add_child(base)
	for mesh in base.find_children("*", "MeshInstance3D", true, false):
		var source := mesh.get_active_material(0) as BaseMaterial3D
		var material := ShaderMaterial.new()
		material.shader = PEDESTAL_SHADER
		if source != null:
			material.set_shader_parameter("stone_texture", source.albedo_texture)
		mesh.material_override = material


