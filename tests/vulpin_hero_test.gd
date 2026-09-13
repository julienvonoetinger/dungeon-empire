extends SceneTree

const NodeProbes := preload("res://tests/probes/node_probes.gd")
const VULPIN_SCRIPT := "res://scripts/world/vulpin_hero.gd"
const WALK_MODEL := "res://assets/models/characters/vulpin/hero_vulpin_walking.glb"
const RUN_MODEL := "res://assets/models/characters/vulpin/hero_vulpin_running.glb"
const LOCKPICK_MODEL := "res://assets/models/characters/vulpin/hero_vulpin_lockpicking.glb"
const DYING_MODEL := "res://assets/models/characters/vulpin/hero_vulpin_dying.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(VULPIN_SCRIPT), "Vulpin hero controller must exist")
	_check(ResourceLoader.exists(WALK_MODEL), "walking model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "running model must import")
	_check(ResourceLoader.exists(LOCKPICK_MODEL), "lockpicking model must import")
	_check(ResourceLoader.exists(DYING_MODEL), "dying model must import")
	if failures > 0:
		quit(1)
		return

	var hero: Node3D = load(VULPIN_SCRIPT).new()
	root.add_child(hero)
	await process_frame
	var walking := hero.get_node("Walking") as Node3D
	var running := hero.get_node("Running") as Node3D
	_check(walking.scale.is_equal_approx(Vector3.ONE * 0.4), "walking export must use the calibrated Meshy character scale")
	_check(running.scale.is_equal_approx(Vector3.ONE * 0.4), "running export must use the calibrated Meshy character scale")
	_check(walking.position.is_zero_approx() and running.position.is_zero_approx(),
		"both animation exports must share the same bottom-centered origin")

	hero.set_running(false)
	_check(_playing_clip(hero).contains("walking"), "normal movement must play the walking clip")
	hero.set_running(true)
	_check(_playing_clip(hero).contains("running"), "fleeing movement must play the running clip")
	hero.set_lockpicking(true)
	_check((hero.get_node("Lockpicking") as Node3D).visible and not (hero.get_node("Walking") as Node3D).visible,
		"forcing a door must show the lockpicking model")
	hero.set_dying(true)
	_check((hero.get_node("Dying") as Node3D).visible and not (hero.get_node("Lockpicking") as Node3D).visible,
		"a defeated Vulpin must show the dying model")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Vulpin switches between walking and running animations")
	quit(1 if failures else 0)


func _playing_clip(hero: Node) -> String:
	var playing := NodeProbes.playing_clips(hero)
	_check(playing.size() == 1, "exactly one Vulpin animation must be playing")
	return playing[0] if playing.size() == 1 else ""


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
