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

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Mycean Mage selects walking, running, and death animations")
	quit(1 if failures else 0)


func _has_right_hand_staff(model: Node) -> bool:
	var report := NodeProbes.attachment_report(model, "StaffAttachment", "MyceanMageStaff")
	return report["bone"] == &"RightHand" and report["payload"] != null


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
