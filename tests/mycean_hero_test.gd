extends SceneTree

const NodeProbes := preload("res://tests/probes/node_probes.gd")
const MYCEAN_SCRIPT := "res://scripts/world/mycean_hero.gd"
const WALK_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_walking.glb"
const RUN_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_running.glb"
const DEAD_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_dead.glb"
const CAST_MODEL := "res://assets/models/characters/mycean/hero_mycean_mage_cast.glb"
const STAFF_MODEL := "res://assets/models/characters/mycean/mycean_mage_staff.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(WALK_MODEL), "walking model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "running model must import")
	_check(ResourceLoader.exists(DEAD_MODEL), "dead model must import")
	_check(ResourceLoader.exists(CAST_MODEL), "cast model must import")
	_check(ResourceLoader.exists(STAFF_MODEL), "staff model must import")

	var hero := load(MYCEAN_SCRIPT).new() as Node3D
	root.add_child(hero)
	await process_frame

	var walking := NodeProbes.child(hero, "Walking") as Node3D
	var running := NodeProbes.child(hero, "Running") as Node3D
	var dead := NodeProbes.child(hero, "Dead") as Node3D
	var casting := NodeProbes.child(hero, "Casting") as Node3D
	_check(_has_right_hand_staff(walking), "walking Mycean Mage must hold the staff in the right hand")
	_check(_has_right_hand_staff(running), "running Mycean Mage must hold the staff in the right hand")
	_check(_has_right_hand_staff(dead), "dead Mycean Mage must keep the staff attached to the right hand")
	_check(_has_right_hand_staff(casting), "casting Mycean Mage must hold the staff in the right hand")
	_check_staff_transform(walking, "walking")
	_check_staff_transform(running, "running")
	_check_staff_transform(dead, "dead")
	_check_staff_transform(casting, "casting")
	_check(hero.has_method("get_staff_grip_offset_unit_scale")
			and is_equal_approx(float(hero.call("get_staff_grip_offset_unit_scale")), 0.01),
			"Mycean Mage staff offset must expose centimeter-style tuning units")
	_check(hero.has_method("get_right_hand_pose_correction_degrees"),
			"Mycean Mage must expose the paladin-matched right-hand correction")
	if hero.has_method("get_right_hand_pose_correction_degrees"):
		_check(hero.get_right_hand_pose_correction_degrees().is_equal_approx(Vector3(0.0, 30.0, 20.0)),
				"Mycean Mage right hand must use the tuned calibration: X 0, Y 30, Z 20")
	_check(walking != null and walking.visible, "an advancing Mycean Mage must show walking")
	_check(running != null and not running.visible, "an advancing Mycean Mage must hide running")
	_check(dead != null and not dead.visible, "an advancing Mycean Mage must hide dead")
	_check(casting != null and not casting.visible, "an advancing Mycean Mage must hide casting")
	_check(NodeProbes.playing_clip(hero).contains("walking"), "an advancing Mycean Mage must play walking")

	hero.call("set_running", true)
	_check(walking != null and not walking.visible, "a fleeing Mycean Mage must hide walking")
	_check(running != null and running.visible, "a fleeing Mycean Mage must show running")
	_check(dead != null and not dead.visible, "a fleeing Mycean Mage must hide dead")
	_check(casting != null and not casting.visible, "a fleeing Mycean Mage must hide casting")
	_check(NodeProbes.playing_clip(hero).contains("running"), "a fleeing Mycean Mage must play running")

	hero.call("set_channeling", true)
	_check(walking != null and not walking.visible, "a casting Mycean Mage must hide walking")
	_check(running != null and not running.visible, "a casting Mycean Mage must hide running")
	_check(dead != null and not dead.visible, "a casting Mycean Mage must hide dead")
	_check(casting != null and casting.visible, "a casting Mycean Mage must show casting")
	_check(NodeProbes.playing_clip(hero).contains("cast"), "a casting Mycean Mage must play the cast animation")

	hero.call("set_channeling", false)
	_check(running != null and running.visible, "a fleeing Mycean Mage must return to running after casting")
	_check(casting != null and not casting.visible, "a Mycean Mage must hide casting after channeling")

	if hero.has_method("set_dying"):
		hero.call("set_dying", true)
		_check(walking != null and not walking.visible, "a defeated Mycean Mage must hide walking")
		_check(running != null and not running.visible, "a defeated Mycean Mage must hide running")
		_check(dead != null and dead.visible, "a defeated Mycean Mage must show dead")
		_check(NodeProbes.playing_clip(hero).contains("dead"), "a defeated Mycean Mage must play dead")

		hero.call("set_dying", false)
		_check(walking != null and not walking.visible, "a recovered fleeing Mycean Mage must stay in running state")
		_check(running != null and running.visible, "a recovered fleeing Mycean Mage must return to running")
		_check(dead != null and not dead.visible, "a recovered Mycean Mage must hide dead")
	else:
		_check(false, "Mycean Mage must expose set_dying")

	if hero.has_method("set_preview_pose"):
		hero.call("set_preview_pose")
		_check(walking != null and not walking.visible, "Mycean Mage preview must hide walking")
		_check(running != null and not running.visible, "Mycean Mage preview must hide running")
		_check(dead != null and not dead.visible, "Mycean Mage preview must hide dead")
		_check(casting != null and casting.visible, "Mycean Mage preview must loop casting")
		_check(_has_right_hand_staff(casting), "Mycean Mage preview casting model must keep the staff in the right hand")
		_check(not NodeProbes.playing_clips(hero).is_empty(), "Mycean Mage preview must play its casting animation")
	else:
		_check(false, "Mycean Mage must expose set_preview_pose")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Mycean Mage selects walking, running, and death animations")
	quit(1 if failures else 0)


func _has_right_hand_staff(model: Node) -> bool:
	var report := NodeProbes.attachment_report(model, "StaffAttachment", "MyceanMageStaff")
	return report["bone"] == &"RightHand" and report["payload"] != null


func _check_staff_transform(model: Node, motion_name: String) -> void:
	var staff := NodeProbes.child(model, "MyceanMageStaff") as Node3D
	_check(staff != null, "%s Mycean Mage must have a staff payload" % motion_name)
	if staff == null:
		return
	_check(staff.scale.length() < 3.0, "%s Mycean Mage staff must keep a normal in-game scale" % motion_name)
	_check(staff.position.is_equal_approx(Vector3(-0.02, 0.11, 0.0)),
			"%s Mycean Mage staff must use the calibrated position" % motion_name)
	_check(staff.rotation_degrees.is_equal_approx(Vector3(88.0, 15.0, 55.0)),
			"%s Mycean Mage staff must use the calibrated rotation" % motion_name)
	_check(staff.rotation_order == EULER_ORDER_YXZ,
			"%s Mycean Mage staff must use YXZ rotation order" % motion_name)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
