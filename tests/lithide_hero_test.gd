extends SceneTree

const LITHIDE_SCRIPT := "res://scripts/world/lithide_hero.gd"
const WALK_MODEL := "res://assets/models/characters/lithide/hero_lithide_paladin_walking_v3.glb"
const RUN_MODEL := "res://assets/models/characters/lithide/hero_lithide_paladin_running_v3.glb"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists(LITHIDE_SCRIPT), "Lithide hero controller must exist")
	_check(ResourceLoader.exists(WALK_MODEL), "Lithide walking model must import")
	_check(ResourceLoader.exists(RUN_MODEL), "Lithide running model must import")
	if failures > 0:
		quit(1)
		return

	var hero: Node3D = load(LITHIDE_SCRIPT).new()
	root.add_child(hero)
	await process_frame
	var walking := hero.get_node("Walking") as Node3D
	var running := hero.get_node("Running") as Node3D
	_check(walking.scale.is_equal_approx(Vector3.ONE * 0.45),
		"walking export must use the calibrated Lithide scale")
	_check(running.scale.is_equal_approx(Vector3.ONE * 0.45),
		"running export must use the calibrated Lithide scale")
	_check(walking.position.is_zero_approx() and running.position.is_zero_approx(),
		"both Lithide animation exports must share the same bottom-centered origin")

	hero.set_running(false)
	_check(_playing_clip(hero).contains("walking"), "normal movement must play the Lithide walking clip")
	hero.set_running(true)
	_check(_playing_clip(hero).contains("running"), "fleeing movement must play the Lithide running clip")

	hero.queue_free()
	await process_frame
	if failures == 0:
		print("OK: Lithide switches between walking and running animations")
	quit(1 if failures else 0)


func _playing_clip(hero: Node) -> String:
	var playing: Array[String] = []
	for player in hero.find_children("*", "AnimationPlayer", true, false):
		if player.is_playing():
			playing.append(String(player.current_animation).to_lower())
	_check(playing.size() == 1, "exactly one Lithide animation must be playing")
	return playing[0] if playing.size() == 1 else ""


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
