extends SceneTree

const NodeProbes := preload("res://tests/probes/node_probes.gd")
const PRIEST_SCRIPT := "res://scripts/world/nocturne_priest_hero.gd"
const WALK_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_walking.glb"
const RUN_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_running.glb"
const DEAD_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_dead.glb"
const CAST_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_cast.glb"
const WINGS_MODEL := "res://assets/models/characters/nocturne/hero_nocturne_priest_wings.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(WALK_MODEL), "walking Nocturne Priest model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "running Nocturne Priest model must import")
	_check(ResourceLoader.exists(DEAD_MODEL), "dead Nocturne Priest model must import")
	_check(ResourceLoader.exists(CAST_MODEL), "cast Nocturne Priest model must import")
	_check(ResourceLoader.exists(WINGS_MODEL), "Nocturne Priest wings model must import")
	_check(ResourceLoader.exists(PRIEST_SCRIPT), "Nocturne Priest visual script must exist")
	if failures > 0:
		quit(1)
		return

	var hero := load(PRIEST_SCRIPT).new() as Node3D
	root.add_child(hero)
	await process_frame

	var walking := NodeProbes.child(hero, "Walking") as Node3D
	var running := NodeProbes.child(hero, "Running") as Node3D
	var dead := NodeProbes.child(hero, "Dead") as Node3D
	var casting := NodeProbes.child(hero, "Casting") as Node3D
	_check(walking != null and walking.visible, "an advancing Nocturne Priest must show walking")
	_check(running != null and not running.visible, "an advancing Nocturne Priest must hide running")
	_check(dead != null and not dead.visible, "an advancing Nocturne Priest must hide dead")
	_check(casting != null and not casting.visible, "an advancing Nocturne Priest must hide casting")
	for model in [walking, running, dead, casting]:
		_check(_has_back_wings(model), "Nocturne Priest must wear separate back wings for %s" % model.name)
	_check(NodeProbes.playing_clip(hero).contains("walking"), "an advancing Nocturne Priest must play walking")

	hero.call("set_running", true)
	_check(walking != null and not walking.visible, "a fleeing Nocturne Priest must hide walking")
	_check(running != null and running.visible, "a fleeing Nocturne Priest must show running")
	_check(NodeProbes.playing_clip(hero).contains("running"), "a fleeing Nocturne Priest must play running")

	hero.call("set_channeling", true)
	_check(running != null and not running.visible, "a casting Nocturne Priest must hide running")
	_check(casting != null and casting.visible, "a casting Nocturne Priest must show casting")
	_check(NodeProbes.playing_clip(hero).contains("spell") or NodeProbes.playing_clip(hero).contains("cast"),
			"a casting Nocturne Priest must play the spell cast animation")

	hero.call("set_channeling", false)
	_check(running != null and running.visible, "a fleeing Nocturne Priest must return to running after casting")
	_check(casting != null and not casting.visible, "a Nocturne Priest must hide casting after channeling")

	hero.call("set_dying", true)
	_check(running != null and not running.visible, "a defeated Nocturne Priest must hide running")
	_check(dead != null and dead.visible, "a defeated Nocturne Priest must show dead")
	_check(NodeProbes.playing_clip(hero).contains("dead"), "a defeated Nocturne Priest must play dead")

	hero.call("set_preview_pose")
	_check(walking != null and not walking.visible, "Nocturne Priest preview must hide walking")
	_check(running != null and not running.visible, "Nocturne Priest preview must hide running")
	_check(dead != null and not dead.visible, "Nocturne Priest preview must hide dead")
	_check(casting != null and casting.visible, "Nocturne Priest preview must show casting")
	_check(_has_looping_animation(casting), "Nocturne Priest preview must loop casting")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Nocturne Priest selects walking, running, cast, and death animations")
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


func _has_back_wings(model: Node) -> bool:
	if model == null:
		return false
	var report := NodeProbes.attachment_report(model, "WingsBackAttachment", "NocturnePriestWings")
	var wings := report["payload"] as Node3D
	return wings != null \
			and report["bone"] in [&"Chest", &"Spine2", &"Spine", &"Hips"] \
			and wings.position.is_equal_approx(Vector3(0.0, -0.225, -0.155)) \
			and wings.rotation_order == EULER_ORDER_YXZ \
			and wings.rotation_degrees.is_equal_approx(Vector3.ZERO) \
			and wings.scale == Vector3.ONE


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
