class_name MyceanHero
extends Node3D

const WALK_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_walking.glb"
const RUN_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_running.glb"
const DEAD_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_dead.glb"
const CAST_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_cast.glb"
const STAFF_MODEL := "res://assets/models/characters/mycean/mycean_mage_staff.glb"
const CHARACTER_SCALE := 0.42
const PLACEHOLDER_SCALE := 0.78
const STAFF_SCALE := Vector3.ONE
const STAFF_GRIP_OFFSET := Vector3.ZERO
const STAFF_GRIP_ROTATION := Vector3.ZERO

var _is_running := false
var _is_channeling := false
var _is_dying := false
var _body: Node3D
var _walking: Node3D
var _running: Node3D
var _dead: Node3D
var _casting: Node3D


func _ready() -> void:
	_body = Node3D.new()
	_body.name = "MyceanBody"
	add_child(_body)
	if not _load_model():
		_body.scale = Vector3.ONE * PLACEHOLDER_SCALE
		_build_placeholder()
	set_running(_is_running)
	set_channeling(_is_channeling)


func set_running(value: bool) -> void:
	_is_running = value
	if _body != null:
		_body.rotation_degrees.z = -3.0 if value else 0.0
	if not has_imported_model() or _is_dying or _is_channeling:
		return
	_activate_model(_running if value else _walking)


func set_channeling(value: bool) -> void:
	_is_channeling = value
	if _body != null:
		var base_scale := CHARACTER_SCALE if has_imported_model() else PLACEHOLDER_SCALE
		_body.scale = Vector3.ONE * base_scale * (1.06 if value else 1.0)
	if not has_imported_model() or _is_dying:
		return
	if value:
		_activate_model(_casting)
		return
	_activate_model(_running if _is_running else _walking)


func set_dying(value: bool) -> void:
	if not has_imported_model():
		return
	if _is_dying == value:
		return
	_is_dying = value
	if value:
		_activate_model(_dead)
		return
	_activate_model(_running if _is_running else _walking)


func has_imported_model() -> bool:
	return _walking != null and _running != null and _dead != null and _casting != null


func _load_model() -> bool:
	var walk_packed := load(WALK_MODEL) as PackedScene
	var run_packed := load(RUN_MODEL) as PackedScene
	var dead_packed := load(DEAD_MODEL) as PackedScene
	var cast_packed := load(CAST_MODEL) as PackedScene
	var staff_packed := load(STAFF_MODEL) as PackedScene
	if walk_packed == null or run_packed == null or dead_packed == null or cast_packed == null:
		return false
	_walking = walk_packed.instantiate() as Node3D
	_running = run_packed.instantiate() as Node3D
	_dead = dead_packed.instantiate() as Node3D
	_casting = cast_packed.instantiate() as Node3D
	if _walking == null or _running == null or _dead == null or _casting == null:
		return false
	_walking.name = "Walking"
	_running.name = "Running"
	_dead.name = "Dead"
	_casting.name = "Casting"
	_body.add_child(_walking)
	_body.add_child(_running)
	_body.add_child(_dead)
	_body.add_child(_casting)
	if staff_packed != null:
		_attach_staff(_walking, staff_packed)
		_attach_staff(_running, staff_packed)
		_attach_staff(_dead, staff_packed)
		_attach_staff(_casting, staff_packed)
	_body.scale = Vector3.ONE * CHARACTER_SCALE
	_running.visible = false
	_dead.visible = false
	_casting.visible = false
	_activate_model(_walking)
	return true


func _build_placeholder() -> void:
	var stem_mat := _mat(Color("#C9AC7A"), Color("#9B4DB5"), 0.0)
	var cap_mat := _mat(Color("#683276"), Color("#CE72DF"), 0.25)
	var glow_mat := _mat(Color("#CE72DF"), Color("#CE72DF"), 1.1)

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.16
	stem_mesh.bottom_radius = 0.24
	stem_mesh.height = 0.84
	stem.mesh = stem_mesh
	stem.material_override = stem_mat
	stem.position.y = 0.42
	_body.add_child(stem)

	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radial_segments = 16
	cap_mesh.rings = 8
	cap.mesh = cap_mesh
	cap.material_override = cap_mat
	cap.scale = Vector3(0.5, 0.2, 0.5)
	cap.position.y = 0.94
	_body.add_child(cap)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	head.mesh = head_mesh
	head.material_override = stem_mat
	head.scale = Vector3(0.2, 0.18, 0.2)
	head.position.y = 0.74
	_body.add_child(head)

	for i in 5:
		var spot := MeshInstance3D.new()
		var spot_mesh := SphereMesh.new()
		spot_mesh.radial_segments = 8
		spot_mesh.rings = 4
		spot.mesh = spot_mesh
		spot.material_override = glow_mat
		var angle := TAU * float(i) / 5.0
		spot.scale = Vector3.ONE * 0.045
		spot.position = Vector3(cos(angle) * 0.28, 0.98 + 0.02 * sin(angle * 2.0), sin(angle) * 0.28)
		_body.add_child(spot)

	var staff := MeshInstance3D.new()
	var staff_mesh := CylinderMesh.new()
	staff_mesh.top_radius = 0.025
	staff_mesh.bottom_radius = 0.025
	staff_mesh.height = 0.95
	staff.mesh = staff_mesh
	staff.material_override = _mat(Color("#555765"), Color.BLACK, 0.0)
	staff.position = Vector3(0.34, 0.48, 0.02)
	staff.rotation_degrees.z = -8.0
	_body.add_child(staff)

	var focus := MeshInstance3D.new()
	var focus_mesh := SphereMesh.new()
	focus_mesh.radial_segments = 10
	focus_mesh.rings = 5
	focus.mesh = focus_mesh
	focus.material_override = glow_mat
	focus.scale = Vector3.ONE * 0.08
	focus.position = Vector3(0.4, 1.0, 0.02)
	_body.add_child(focus)


func _mat(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 0.7
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy
	return mat


func _play_first_animation(model: Node) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	var clips := player.get_animation_list()
	if clips.is_empty():
		return
	var clip: StringName = clips[0]
	if not player.is_playing() or player.current_animation != clip:
		player.play(clip)


func _activate_model(model: Node3D) -> void:
	_walking.visible = model == _walking
	_running.visible = model == _running
	_dead.visible = model == _dead
	_casting.visible = model == _casting
	for candidate in [_walking, _running, _dead, _casting]:
		if candidate != model:
			_stop_animations(candidate)
	_play_first_animation(model)


func _stop_animations(model: Node) -> void:
	for player in model.find_children("*", "AnimationPlayer", true, false):
		player.stop()


func _attach_staff(model: Node3D, staff_packed: PackedScene) -> void:
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("Mycean Mage model has no Skeleton3D for the staff")
		return
	var skeleton := skeletons[0] as Skeleton3D
	if skeleton.find_bone("RightHand") < 0:
		push_error("Mycean Mage skeleton has no RightHand bone for the staff")
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "StaffAttachment"
	skeleton.add_child(attachment)
	attachment.bone_name = &"RightHand"

	var staff := staff_packed.instantiate() as Node3D
	if staff == null:
		push_error("Mycean Mage staff model cannot be instantiated")
		return
	staff.name = "MyceanMageStaff"
	staff.position = STAFF_GRIP_OFFSET
	staff.rotation_degrees = STAFF_GRIP_ROTATION
	staff.scale = STAFF_SCALE
	attachment.add_child(staff)
