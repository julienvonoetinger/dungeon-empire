extends SceneTree

const NodeProbes := preload("res://tests/probes/node_probes.gd")
const BATRAFIAN_SCRIPT := "res://scripts/world/batrafian_hero.gd"
const WALK_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_walking.glb"
const RUN_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_running.glb"
const DEAD_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_dead.glb"
const JUMP_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_jump_trap.glb"
const ATTACK_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_attack.glb"
const QUIVER_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_quiver.glb"
const WEAPON_MODEL := "res://assets/models/characters/batrafian/hero_batrafian_ranger_weapon.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(WALK_MODEL), "walking Batrafian Ranger model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "running Batrafian Ranger model must import")
	_check(ResourceLoader.exists(DEAD_MODEL), "dead Batrafian Ranger model must import")
	_check(ResourceLoader.exists(JUMP_MODEL), "jumping Batrafian Ranger model must import")
	_check(ResourceLoader.exists(ATTACK_MODEL), "attacking Batrafian Ranger model must import")
	_check(ResourceLoader.exists(QUIVER_MODEL), "Batrafian Ranger quiver model must import")
	_check(ResourceLoader.exists(WEAPON_MODEL), "Batrafian Ranger weapon model must import")
	_check(ResourceLoader.exists(BATRAFIAN_SCRIPT), "Batrafian Ranger visual script must exist")
	if failures > 0:
		quit(1)
		return

	var hero := load(BATRAFIAN_SCRIPT).new() as Node3D
	root.add_child(hero)
	await process_frame

	var walking := NodeProbes.child(hero, "Walking") as Node3D
	var running := NodeProbes.child(hero, "Running") as Node3D
	var dead := NodeProbes.child(hero, "Dead") as Node3D
	var jumping := NodeProbes.child(hero, "JumpTrap") as Node3D
	var attack := NodeProbes.child(hero, "Attack") as Node3D
	_check(walking != null and walking.visible, "an advancing Batrafian Ranger must show walking")
	_check(running != null and not running.visible, "an advancing Batrafian Ranger must hide running")
	_check(dead != null and not dead.visible, "an advancing Batrafian Ranger must hide dead")
	_check(jumping != null and not jumping.visible, "an advancing Batrafian Ranger must hide jumping")
	_check(attack != null and not attack.visible, "an advancing Batrafian Ranger must hide attack")
	_check(NodeProbes.playing_clip(hero).contains("walking"), "an advancing Batrafian Ranger must play walking")
	for model in [walking, running, dead, jumping, attack]:
		if model != null:
			_check(_has_back_quiver(model), "%s must carry the quiver on its back" % model.name)
			_check_quiver_transform(model, String(model.name))
			_check(_has_left_hand_weapon(model), "%s must carry the weapon in its left hand" % model.name)
			_check_weapon_transform(model, String(model.name))
	_check(hero.has_method("get_right_hand_pose_correction_degrees"),
			"Batrafian Ranger must expose the Mycean-matched right-hand correction")
	if hero.has_method("get_right_hand_pose_correction_degrees"):
		_check(hero.get_right_hand_pose_correction_degrees().is_equal_approx(Vector3(0.0, 70.0, 20.0)),
				"Batrafian Ranger right hand must use the tuned calibration: X 0, Y 70, Z 20")
	_check(hero.has_method("get_attack_head_turn_degrees"),
			"Batrafian Ranger must expose the attack head turn")
	if hero.has_method("get_attack_head_turn_degrees"):
		_check(hero.get_attack_head_turn_degrees().is_equal_approx(Vector3(0.0, 35.0, 0.0)),
				"Batrafian Ranger must turn its head left while attacking")

	hero.call("set_running", true)
	_check(walking != null and not walking.visible, "a fleeing Batrafian Ranger must hide walking")
	_check(running != null and running.visible, "a fleeing Batrafian Ranger must show running")
	_check(dead != null and not dead.visible, "a fleeing Batrafian Ranger must hide dead")
	_check(NodeProbes.playing_clip(hero).contains("running"), "a fleeing Batrafian Ranger must play running")

	hero.call("set_jumping", true)
	_check(walking != null and not walking.visible, "a jumping Batrafian Ranger must hide walking")
	_check(running != null and not running.visible, "a jumping Batrafian Ranger must hide running")
	_check(jumping != null and jumping.visible, "a jumping Batrafian Ranger must show jump")
	_check(attack != null and not attack.visible, "a jumping Batrafian Ranger must hide attack")
	_check(NodeProbes.playing_clip(hero).contains("jump") or NodeProbes.playing_clip(hero).contains("obstacle"),
		"a jumping Batrafian Ranger must play the obstacle jump animation")

	hero.call("set_jumping", false)
	_check(running != null and running.visible, "a Batrafian Ranger must return to running after a jump")
	_check(jumping != null and not jumping.visible, "a Batrafian Ranger must hide jump after landing")

	hero.call("set_attacking", true)
	_check(walking != null and not walking.visible, "an attacking Batrafian Ranger must hide walking")
	_check(running != null and not running.visible, "an attacking Batrafian Ranger must hide running")
	_check(jumping != null and not jumping.visible, "an attacking Batrafian Ranger must hide jumping")
	_check(attack != null and attack.visible, "an attacking Batrafian Ranger must show attack")
	_check(_has_head_bone(attack), "an attacking Batrafian Ranger must have a head bone to turn left")
	_check(NodeProbes.playing_clip(hero).contains("archery") or NodeProbes.playing_clip(hero).contains("shot")
			or NodeProbes.playing_clip(hero).contains("attack"),
		"an attacking Batrafian Ranger must play the archery shot animation")

	hero.call("set_attacking", false)
	_check(running != null and running.visible, "a Batrafian Ranger must return to running after attacking")
	_check(attack != null and not attack.visible, "a Batrafian Ranger must hide attack after firing")

	hero.call("set_dying", true)
	_check(walking != null and not walking.visible, "a defeated Batrafian Ranger must hide walking")
	_check(running != null and not running.visible, "a defeated Batrafian Ranger must hide running")
	_check(dead != null and dead.visible, "a defeated Batrafian Ranger must show dead")
	_check(jumping != null and not jumping.visible, "a defeated Batrafian Ranger must hide jumping")
	_check(attack != null and not attack.visible, "a defeated Batrafian Ranger must hide attack")
	_check(NodeProbes.playing_clip(hero).contains("dead"), "a defeated Batrafian Ranger must play dead")

	hero.call("set_dying", false)
	_check(walking != null and not walking.visible, "a recovered fleeing Batrafian Ranger must stay in running state")
	_check(running != null and running.visible, "a recovered Batrafian Ranger must return to running")
	_check(dead != null and not dead.visible, "a recovered Batrafian Ranger must hide dead")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Batrafian Ranger selects walking, running, jump, attack, and death animations")
	quit(1 if failures else 0)


func _has_back_quiver(model: Node) -> bool:
	var report := NodeProbes.attachment_report(model, "QuiverAttachment", "BatrafianRangerQuiver")
	return [&"Spine2", &"Spine1", &"Spine", &"Chest", &"UpperChest", &"Hips"].has(report["bone"]) \
		and report["payload"] != null


func _has_left_hand_weapon(model: Node) -> bool:
	var report := NodeProbes.attachment_report(model, "WeaponAttachment", "BatrafianRangerWeapon")
	return report["bone"] == &"LeftHand" and report["payload"] != null


func _has_head_bone(model: Node) -> bool:
	var skeleton := NodeProbes.first_skeleton(model)
	return skeleton != null and skeleton.find_bone("Head") >= 0


func _check_weapon_transform(model: Node, motion_name: String) -> void:
	var weapon := NodeProbes.child(model, "BatrafianRangerWeapon") as Node3D
	_check(weapon != null, "%s must have a weapon payload" % motion_name)
	if weapon == null:
		return
	_check(weapon.position.is_equal_approx(Vector3(-0.02, 0.06, 0.0)),
			"%s weapon must use the calibrated position" % motion_name)
	_check(weapon.rotation_degrees.is_equal_approx(Vector3(0.0, -31.0, -87.0)),
			"%s weapon must use the calibrated rotation" % motion_name)
	_check(weapon.scale.is_equal_approx(Vector3.ONE),
			"%s weapon must use the calibrated scale" % motion_name)
	_check(weapon.rotation_order == EULER_ORDER_YXZ,
			"%s weapon must use YXZ rotation order" % motion_name)


func _check_quiver_transform(model: Node, motion_name: String) -> void:
	var quiver := NodeProbes.child(model, "BatrafianRangerQuiver") as Node3D
	_check(quiver != null, "%s must have a quiver payload" % motion_name)
	if quiver == null:
		return
	_check(quiver.position.is_equal_approx(Vector3(0.0, 0.0, -0.17)),
			"%s quiver must use the calibrated position" % motion_name)
	_check(quiver.rotation_degrees.is_equal_approx(Vector3(8.0, 0.0, 40.0)),
			"%s quiver must use the calibrated rotation" % motion_name)
	_check(quiver.scale.is_equal_approx(Vector3.ONE * 0.72),
			"%s quiver must use the calibrated scale" % motion_name)
	_check(quiver.rotation_order == EULER_ORDER_YXZ,
			"%s quiver must use YXZ rotation order" % motion_name)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
