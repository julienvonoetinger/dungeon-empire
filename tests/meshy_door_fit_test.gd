extends SceneTree

const STATES := {
	"closed": "res://assets/models/doors/wall_v2/door_closed.glb",
	"open": "res://assets/models/doors/wall_v2/door_open.glb",
	"damaged": "res://assets/models/doors/wall_v2/door_damaged.glb",
	"destroyed": "res://assets/models/doors/wall_v2/door_destroyed.glb",
}
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://scripts/world/dungeon_world.gd").new()
	root.add_child(world)
	_check(world.DOOR_CLOSED_GLB == STATES.closed, "closed runtime path must use wall_v2")
	_check(world.DOOR_OPENED_GLB == STATES.open, "open runtime path must use wall_v2")
	_check(world.DOOR_DAMAGED_GLB == STATES.damaged, "damaged runtime path must use wall_v2")
	_check(world.DOOR_DESTROYED_GLB == STATES.destroyed, "destroyed runtime path must use wall_v2")
	for state in STATES:
		var path: String = STATES[state]
		_check(ResourceLoader.exists(path), "%s Meshy door model must exist" % state)
		var holder := Node3D.new()
		root.add_child(holder)
		var door: Node3D = world._add_fitted_door(holder, path)
		_check(door != null, "%s door must instantiate" % state)
		if door != null:
			var bounds: AABB = world._door_aabb(door)
			_check(absf(bounds.position.x + 0.49) < 0.004 and absf(bounds.end.x - 0.49) < 0.004,
				"%s door must span the wall opening" % state)
			_check(absf(bounds.position.z + 0.14) < 0.004 and absf(bounds.end.z - 0.14) < 0.004,
				"%s door must stay within wall thickness" % state)
			_check(absf(bounds.position.y - world.FLOOR_H) < 0.004 and absf(bounds.end.y - world.ROCK_H) < 0.004,
				"%s door must run from floor surface to wall top" % state)
		holder.queue_free()
		await process_frame
	world.queue_free()
	await process_frame
	if failures == 0:
		print("OK: four Meshy door states fit the wall opening, height and thickness")
	quit(1 if failures else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
