extends SceneTree

const NodeProbes := preload("res://tests/probes/node_probes.gd")
const SCALELORD_SCRIPT := "res://scripts/world/saurian_scalelord_hero.gd"
const WALK_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_walking.glb"
const RUN_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_running.glb"
const DEAD_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_dead.glb"
const ATTACK_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_attack.glb"
const WEAPON_MODEL := "res://assets/models/characters/saurian/hero_saurian_scalelord_weapon.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(WALK_MODEL), "walking Saurian Scalelord model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "running Saurian Scalelord model must import")
	_check(ResourceLoader.exists(DEAD_MODEL), "dead Saurian Scalelord model must import")
	_check(ResourceLoader.exists(ATTACK_MODEL), "attack Saurian Scalelord model must import")
	_check(ResourceLoader.exists(WEAPON_MODEL), "Saurian Scalelord weapon model must import")
	_check(ResourceLoader.exists(SCALELORD_SCRIPT), "Saurian Scalelord visual script must exist")
	if failures > 0:
		quit(1)
		return

	var hero := load(SCALELORD_SCRIPT).new() as Node3D
	root.add_child(hero)
	await process_frame

	var walking := NodeProbes.child(hero, "Walking") as Node3D
	var running := NodeProbes.child(hero, "Running") as Node3D
	var dead := NodeProbes.child(hero, "Dead") as Node3D
	var attack := NodeProbes.child(hero, "Attack") as Node3D
	_check(walking != null and walking.visible, "an advancing Saurian Scalelord must show walking")
	_check(running != null and not running.visible, "an advancing Saurian Scalelord must hide running")
	_check(dead != null and not dead.visible, "an advancing Saurian Scalelord must hide dead")
	_check(attack != null and not attack.visible, "an advancing Saurian Scalelord must hide attack")
	for model in [walking, running, dead, attack]:
		_check(_has_hand_weapon(model, &"LeftHand", "LeftWeaponAttachment", "SaurianScalelordLeftWeapon"),
				"Saurian Scalelord must hold a weapon in the left hand for %s" % model.name)
		_check(_has_hand_weapon(model, &"RightHand", "RightWeaponAttachment", "SaurianScalelordRightWeapon"),
				"Saurian Scalelord must hold a weapon in the right hand for %s" % model.name)
		_check(_has_weapon_transform(model, "SaurianScalelordLeftWeapon", Vector3(0.28, 0.075, 0.195), Vector3(-2.0, -45.0, -285.0)),
				"Saurian Scalelord left weapon must use the inspector placement for %s" % model.name)
		_check(_has_weapon_transform(model, "SaurianScalelordRightWeapon", Vector3(-0.3, 0.085, 0.165), Vector3(-11.0, 215.0, 73.9)),
				"Saurian Scalelord right weapon must use the inspector placement for %s" % model.name)
	_check(NodeProbes.playing_clip(hero).contains("walking"), "an advancing Saurian Scalelord must play walking")

	hero.call("set_running", true)
	_check(walking != null and not walking.visible, "a fleeing Saurian Scalelord must hide walking")
	_check(running != null and running.visible, "a fleeing Saurian Scalelord must show running")
	_check(NodeProbes.playing_clip(hero).contains("running"), "a fleeing Saurian Scalelord must play running")

	hero.call("set_attacking", true)
	_check(running != null and not running.visible, "an attacking Saurian Scalelord must hide running")
	_check(attack != null and attack.visible, "an attacking Saurian Scalelord must show attack")
	_check(NodeProbes.playing_clip(hero).contains("blade") or NodeProbes.playing_clip(hero).contains("spin")
			or NodeProbes.playing_clip(hero).contains("attack"),
			"an attacking Saurian Scalelord must play the blade spin attack animation")

	hero.call("set_attacking", false)
	_check(running != null and running.visible, "a Saurian Scalelord must return to running after attacking")
	_check(attack != null and not attack.visible, "a Saurian Scalelord must hide attack after attacking")

	hero.call("set_dying", true)
	_check(running != null and not running.visible, "a defeated Saurian Scalelord must hide running")
	_check(dead != null and dead.visible, "a defeated Saurian Scalelord must show dead")
	_check(NodeProbes.playing_clip(hero).contains("dead"), "a defeated Saurian Scalelord must play dead")

	hero.call("set_preview_pose")
	_check(walking != null and not walking.visible, "Saurian Scalelord preview must hide walking")
	_check(running != null and not running.visible, "Saurian Scalelord preview must hide running")
	_check(dead != null and not dead.visible, "Saurian Scalelord preview must hide dead")
	_check(attack != null and attack.visible, "Saurian Scalelord preview must show attack")
	_check(_has_looping_animation(attack), "Saurian Scalelord preview must loop attack")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Saurian Scalelord selects walking, running, attack, and death animations")
	quit(1 if failures else 0)


func _has_looping_animation(root_node: Node) -> bool:
	for player in root_node.find_children("*", "AnimationPlayer", true, false):
		var animation_player := player as AnimationPlayer
		if not animation_player.is_playing():
			continue
		var animation := animation_player.get_animation(animation_player.current_animation)
		if animation != null and animation.loop_mode != Animation.LOOP_NONE:
			return true
	return false


func _has_hand_weapon(model: Node, bone_name: StringName, attachment_name: String, payload_name: String) -> bool:
	if model == null:
		return false
	var report := NodeProbes.attachment_report(model, attachment_name, payload_name)
	return report["bone"] == bone_name and report["payload"] != null


func _has_weapon_transform(model: Node, payload_name: String, expected_position: Vector3, expected_rotation: Vector3) -> bool:
	if model == null:
		return false
	var weapon := NodeProbes.child(model, payload_name) as Node3D
	if weapon == null:
		return false
	return weapon.position.is_equal_approx(expected_position) \
			and weapon.rotation_order == EULER_ORDER_YXZ \
			and weapon.rotation_degrees.is_equal_approx(expected_rotation) \
			and weapon.scale == Vector3.ONE


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
