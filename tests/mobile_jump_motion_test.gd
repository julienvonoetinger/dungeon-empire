extends SceneTree

const Sim := preload("res://scripts/game/dungeon_sim.gd")
const Raid := preload("res://scripts/game/raid_director.gd")
const NodeProbes := preload("res://tests/probes/node_probes.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_imported_hip_drift()
	_test_raid_jump_contract()
	await _test_world_jump_timing()
	print("Mobile jump motion test: %d failures" % failures)
	quit(1 if failures else 0)


func _test_imported_hip_drift() -> void:
	for script_path in ["res://scripts/world/vulpin_hero.gd", "res://scripts/world/batrafian_hero.gd"]:
		var source_path := "res://assets/models/characters/vulpin/hero_vulpin_jump_trap.glb" if script_path.contains("vulpin") else "res://assets/models/characters/batrafian/hero_batrafian_ranger_jump_trap.glb"
		var source_scene := load(source_path) as PackedScene
		var source_model := source_scene.instantiate() as Node3D
		var source_player := NodeProbes.first_animation_player(source_model)
		var source_span := _hips_track_horizontal_span(source_player)
		_check(source_span > 0.05, "%s imported source jump retains its original Hips translation" % script_path)
		source_model.free()
		var hero: Node3D = load(script_path).new()
		root.add_child(hero)
		await process_frame
		hero.set_jumping(true)
		var model := NodeProbes.child(hero, "JumpTrap") as Node3D
		var player := NodeProbes.first_animation_player(model)
		var skeleton := NodeProbes.first_skeleton(model)
		_check(player != null and skeleton != null, "%s jump model exposes animation and skeleton" % script_path)
		if player != null and skeleton != null:
			var clip := player.get_animation(player.current_animation) as Animation
			var hips := skeleton.find_bone("Hips")
			_check(clip != null and hips >= 0, "%s jump clip exposes Hips" % script_path)
			if clip != null and hips >= 0:
				_check(_hips_track_horizontal_span(player) < 0.001,
					"%s cached jump animation removes Hips horizontal translation" % script_path)
				var first := Vector3.ZERO
				var max_drift := 0.0
				for sample in 5:
					player.seek(clip.length * float(sample) / 4.0, true)
					var hips_world: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(hips).origin
					if sample == 0:
						first = hips_world
					else:
						max_drift = maxf(max_drift, Vector2(hips_world.x - first.x, hips_world.z - first.z).length())
				_check(max_drift < 0.01, "%s imported jump Hips add no horizontal grid travel (drift %.5f)" % [script_path, max_drift])
		var source_after := source_scene.instantiate() as Node3D
		_check(_hips_track_horizontal_span(NodeProbes.first_animation_player(source_after)) > 0.05,
			"%s source GLB animation remains unmodified by its private prepared cache" % script_path)
		source_after.free()
		hero.free()
		await process_frame


func _test_raid_jump_contract() -> void:
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var raid = _raid_fixture()
		var from := Vector2i(7, 7)
		var trap: Vector2i = from + direction
		var landing: Vector2i = from + direction * 2
		raid.sim.grid[trap.y][trap.x] = GameTypes.Tile.SPIKE
		raid.sim.trap_charges[trap] = 3
		raid.hero.pos = from
		raid.hero.known[trap] = GameTypes.Tile.SPIKE
		_check(raid._try_trap_jump(from, trap), "ranger jumps one adjacent trap toward %s" % direction)
		_check(raid.hero.pos == landing, "jump moves exactly two cells toward %s" % direction)
		_check(raid.hero.jump_from == from and is_equal_approx(raid.hero.jump_t, GameTypes.TRAP_JUMP_TIME),
			"jump stores origin and shared duration toward %s" % direction)
		_check(int(raid.sim.trap_charges[trap]) == 3, "jump skips without spending trap toward %s" % direction)

	var blocked = _raid_fixture()
	var from := Vector2i(7, 7)
	var trap := Vector2i(8, 7)
	blocked.sim.grid[trap.y][trap.x] = GameTypes.Tile.SPIKE
	blocked.sim.trap_charges[trap] = 3
	blocked.hero.pos = from
	blocked.hero.known[trap] = GameTypes.Tile.SPIKE
	blocked.sim.grid[7][9] = GameTypes.Tile.ROCK
	_check(not blocked._try_trap_jump(from, trap), "jump rejects a blocked landing")
	_check(blocked.hero.pos == from and not blocked.hero.has("jump_from"), "blocked landing leaves hero state unchanged")
	_check(int(blocked.sim.trap_charges[trap]) == 3, "blocked landing preserves trap charge")
	_check(not blocked._try_trap_jump(from, from + Vector2i(0, 2)), "jump rejects a nonadjacent trap argument")
	_check(blocked.hero.pos == from and not blocked.hero.get("jumping_trap", false), "nonadjacent rejection preserves position")
	var door_landing = _raid_fixture()
	door_landing.sim.grid[7][8] = GameTypes.Tile.SPIKE
	door_landing.sim.trap_charges[Vector2i(8, 7)] = 3
	door_landing.hero.pos = from
	door_landing.hero.known[Vector2i(8, 7)] = GameTypes.Tile.SPIKE
	door_landing.sim.grid[7][9] = GameTypes.Tile.DOOR
	_check(door_landing.sim._door_intact(Vector2i(9, 7)), "door landing fixture starts blocked")
	_check(not door_landing._try_trap_jump(from, Vector2i(8, 7)), "jump rejects an intact-door landing")
	_check(door_landing.hero.pos == from and not door_landing.hero.get("jumping_trap", false), "door rejection preserves hero position")
	var entrance_wrong_side = _raid_fixture()
	entrance_wrong_side.sim.grid[7][7] = GameTypes.Tile.ENTRANCE
	entrance_wrong_side.sim.grid[7][6] = GameTypes.Tile.ROCK
	entrance_wrong_side.sim.grid[7][8] = GameTypes.Tile.FLOOR
	entrance_wrong_side.sim.grid[6][7] = GameTypes.Tile.SPIKE
	entrance_wrong_side.sim.grid[5][7] = GameTypes.Tile.FLOOR
	entrance_wrong_side.sim.trap_charges[Vector2i(7, 6)] = 3
	entrance_wrong_side.hero.pos = Vector2i(7, 7)
	entrance_wrong_side.hero.known[Vector2i(7, 6)] = GameTypes.Tile.SPIKE
	_check(not entrance_wrong_side.sim._can_step(Vector2i(7, 7), Vector2i(7, 6)), "entrance trap is on its blocked side")
	_check(not entrance_wrong_side._try_trap_jump(Vector2i(7, 7), Vector2i(7, 6)), "jump rejects a trap across the entrance's blocked side")
	_check(entrance_wrong_side.hero.pos == Vector2i(7, 7), "entrance rejection preserves hero position")


func _test_world_jump_timing() -> void:
	var world = load("res://scripts/world/dungeon_world.gd").new()
	world.mobile_mode = true
	root.add_child(world)
	world.set_process(false)
	await process_frame
	var game := WorldGame.new()
	game.raid_active = true
	game.hero = {"kind": "proxy", "pos": Vector2i(6, 6), "hp": 80, "max_hp": 80,
		"fleeing": false, "facing": Vector2i.RIGHT}
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var from := Vector2i(6, 6)
		var landing: Vector2i = from + direction * 2
		game.hero["pos"] = from
		game.hero.erase("jumping_trap")
		world._sync_hero(game)
		var start_position: Vector3 = world.cell_center(from, world.FLOOR_H + (0.48 - world.FLOOR_H) * 1.4)
		var landing_position: Vector3 = world.cell_center(landing, world.FLOOR_H + (0.48 - world.FLOOR_H) * 1.4)
		game.hero["pos"] = landing
		game.hero["jumping_trap"] = true
		game.hero["jump_from"] = from
		game.hero["jump_t"] = GameTypes.TRAP_JUMP_TIME * 0.5
		game.hero["facing"] = direction
		world._sync_hero(game)
		_check(world._hero.position.is_equal_approx(start_position.lerp(landing_position, 0.5)),
			"world jump timer places hero halfway toward %s" % direction)
		game.hero["jump_t"] = 0.0
		world._sync_hero(game)
		_check(world._hero.position.is_equal_approx(landing_position), "world jump timer lands exactly toward %s" % direction)
		game.hero.erase("jumping_trap")
		game.hero.erase("jump_from")
		game.hero.erase("jump_t")
		world._sync_hero(game)
		_check(world._hero.position.is_equal_approx(landing_position), "completed jump remains snapped at landing")
	game.free()
	world.free()


func _raid_fixture():
	var sim = Sim.new()
	sim.new_map()
	for y in range(4, 11):
		for x in range(4, 11):
			sim.grid[y][x] = GameTypes.Tile.FLOOR
	var raid = Raid.new()
	raid.sim = sim
	raid.set("solid_core", true)
	raid.hero = {
		"kind": "ranger",
		"pos": Vector2i(7, 7),
		"known": {},
		"visited": {},
		"facing": Vector2i.ZERO,
		"carried_gold": 0,
		"hp": 80,
		"fleeing": false,
		"portaling": false,
	}
	return raid


func _hips_track_horizontal_span(player: AnimationPlayer) -> float:
	if player == null:
		return 0.0
	var largest := 0.0
	for clip_name in player.get_animation_list():
		var animation := player.get_animation(clip_name)
		for track in animation.get_track_count():
			var path := animation.track_get_path(track)
			if animation.track_get_type(track) != Animation.TYPE_POSITION_3D or path.get_subname_count() == 0 or path.get_subname(0) != &"Hips":
				continue
			var low := Vector2(INF, INF)
			var high := Vector2(-INF, -INF)
			for key in animation.track_get_key_count(track):
				var value: Vector3 = animation.track_get_key_value(track, key)
				low = low.min(Vector2(value.x, value.z))
				high = high.max(Vector2(value.x, value.z))
			largest = maxf(largest, low.distance_to(high))
	return largest


class WorldGame:
	extends Node
	var raid_active := false
	var grid: Array = []
	var hero := {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
