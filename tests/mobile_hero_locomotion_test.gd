extends SceneTree

const Probes := preload("res://tests/probes/node_probes.gd")

class FakeGame:
	extends Node
	const PORTAL_HOLD := 1.0
	var raid_active := true
	var sim := DungeonSim.new()
	var grid: Array:
		get:
			return sim.grid

	func _init() -> void:
		sim.new_map()
	var hero := {"kind": "thief", "pos": Vector2i(2, 3), "hp": 50,
		"max_hp": 50, "trait": "Test", "fleeing": false, "facing": Vector2i.DOWN}

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://scripts/world/dungeon_world.gd").new()
	world.mobile_mode = true
	root.add_child(world)
	world.set_process(false)
	var game := FakeGame.new()
	for pair in [["thief", "VulpinHero"], ["paladin", "LithideHero"],
		["ranger", "BatrafianHero"], ["mage", "MyceanHero"]]:
		for running in [false, true]:
			game.raid_active = false
			world._sync_hero(game)
			game.raid_active = true
			game.hero.kind = pair[0]
			game.hero.fleeing = running
			game.hero.pos = Vector2i(2, 3)
			world._sync_hero(game)
			game.hero.pos = Vector2i(2, 4)
			world._sync_hero(game)
			var actor := Probes.child(world._hero, pair[1])
			var model := Probes.child(actor, "Running" if running else "Walking")
			var player := Probes.first_animation_player(model)
			var skeleton := Probes.first_skeleton(model)
			var clip := player.current_animation
			var animation := player.get_animation(clip)
			var label := "%s %s" % [pair[0], "run" if running else "walk"]
			# Sample mid-stance: the planted foot should stay nearly still in world space.
			player.seek(animation.length * (0.40 if running else 0.50), true)
			skeleton.force_update_all_bone_transforms()
			var foot := skeleton.find_bone("LeftFoot")
			var before := skeleton.to_global(skeleton.get_bone_global_pose(foot).origin)
			player.advance(0.01)
			world._advance_hero_visual(0.01)
			skeleton.force_update_all_bone_transforms()
			var after := skeleton.to_global(skeleton.get_bone_global_pose(foot).origin)
			_check(absf(after.z - before.z) < 0.005, label + ": planted foot must not slide with the hero")
			player.advance(animation.length / player.speed_scale * 2.0)
			_check(player.is_playing(), label + ": locomotion must continue over multiple cycles")
			world._advance_hero_visual(1.0)
			world._sync_hero(game)
			var stopped_at := player.current_animation_position
			player.advance(0.1)
			_check(is_equal_approx(player.current_animation_position, stopped_at),
				label + ": stationary heroes must not keep stepping")
			game.hero.pos = Vector2i(2, 5)
			world._sync_hero(game)
			player.advance(0.01)
			_check(not is_equal_approx(player.current_animation_position, stopped_at),
				label + ": stepping must resume when movement resumes")
	# These movements are driven by simulation timers, outside normal interpolation.
	for timer in ["trap_arrival_t", "vault_arrival_t", "exit_arrival_t", "exit_t"]:
		game.raid_active = false
		world._sync_hero(game)
		game.raid_active = true
		game.hero.kind = "thief"
		game.hero.fleeing = timer.begins_with("exit")
		game.hero.pos = Vector2i(2, 3)
		world._sync_hero(game)
		game.hero.pos = Vector2i(2, 4)
		game.hero[timer] = 0.24
		if timer == "exit_t":
			game.hero.exiting = true
		world._sync_hero(game)
		var model := Probes.child(world._vulpin, "Running" if game.hero.fleeing else "Walking")
		var player := Probes.first_animation_player(model)
		var skeleton := Probes.first_skeleton(model)
		player.seek(player.get_animation(player.current_animation).length * (0.40 if game.hero.fleeing else 0.50), true)
		skeleton.force_update_all_bone_transforms()
		var foot := skeleton.find_bone("LeftFoot")
		var before := skeleton.to_global(skeleton.get_bone_global_pose(foot).origin)
		player.advance(0.01)
		game.hero[timer] -= 0.01
		world._sync_hero(game)
		skeleton.force_update_all_bone_transforms()
		var after := skeleton.to_global(skeleton.get_bone_global_pose(foot).origin)
		_check(absf(after.z - before.z) < 0.005, timer + ": planted foot must follow scripted movement")
		game.hero.erase(timer)
		game.hero.erase("exiting")
	game.hero.collecting_gold = true
	world._sync_hero(game)
	var collecting := Probes.first_animation_player(Probes.child(world._vulpin, "Collect"))
	_check(is_equal_approx(collecting.speed_scale, 1.0), "collection retains its authored action timing")
	game.free()
	world.free()
	if failures == 0:
		print("OK: hero locomotion checks pass.")
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
