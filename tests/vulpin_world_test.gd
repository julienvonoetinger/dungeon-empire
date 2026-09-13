extends SceneTree

const NodeProbes := preload("res://tests/probes/node_probes.gd")

class FakeGame:
	extends Node
	const PORTAL_HOLD := 1.0
	var raid_active := true
	var hero := {
		"kind": "thief",
		"pos": Vector2i(2, 3),
		"hp": 50,
		"max_hp": 50,
		"trait": "Cunning",
		"fleeing": false,
		"void_absorbing": false,
		"portal_t": 0.0,
		"facing": Vector2i.DOWN,
	}

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: Node3D = load("res://scripts/world/dungeon_world.gd").new() as Node3D
	root.add_child(world)
	await process_frame
	world.set_process(false)
	var game := FakeGame.new()
	world._sync_hero(game)

	var vulpin: Node = NodeProbes.child(world, "VulpinHero")
	var lithide: Node = NodeProbes.child(world, "LithideHero")
	var mycean: Node = NodeProbes.child(world, "MyceanHero")
	var batrafian: Node = NodeProbes.child(world, "BatrafianHero")
	var proxy: Node = NodeProbes.child(world, "HeroProxy")
	var hero_visual := NodeProbes.child(world, "HeroVisual") as Node3D
	_check(vulpin != null and vulpin.visible, "thief raids must show the animated Vulpin")
	_check(lithide != null and not lithide.visible, "thief raids must hide the animated Lithide")
	_check(proxy != null and not proxy.visible, "thief raids must hide the capsule proxy")
	if vulpin != null:
		_check(NodeProbes.playing_clip(vulpin).contains("walking"), "an advancing thief must walk")
		_check_stands_on_floor(vulpin, world, "Vulpin")

	game.hero["pos"] = Vector2i(3, 3)
	game.hero["facing"] = Vector2i.RIGHT
	world._sync_hero(game)
	_check(hero_visual.position.is_equal_approx(Vector3(2.5, 0.48, 3.5)),
		"a new simulation cell must not teleport the visual hero")
	_check(is_equal_approx(hero_visual.rotation.y, PI * 0.5), "the hero must face the direction of travel")
	world._process(0.24)
	_check(hero_visual.position.is_equal_approx(Vector3(3.0, 0.48, 3.5)),
		"the visual hero must be halfway across after half a turn")
	_check(world._hero_bar.position.is_equal_approx(Vector3(3.0, 0.96, 3.5)),
		"the health bar must follow an interpolated hero")
	_check(world._hero_tag.position.is_equal_approx(Vector3(3.0, 1.20, 3.5)),
		"the trait label must follow an interpolated hero")
	world._process(0.24)
	_check(hero_visual.position.is_equal_approx(Vector3(3.5, 0.48, 3.5)),
		"the visual hero must reach the target at the end of a turn")

	game.hero["fleeing"] = true
	world._sync_hero(game)
	if vulpin != null:
		_check(NodeProbes.playing_clip(vulpin).contains("running"), "a fleeing thief must run")

	game.hero["fleeing"] = false
	game.hero["collecting_gold"] = true
	world._sync_hero(game)
	if vulpin != null:
		var collect := NodeProbes.child(vulpin, "Collect") as Node3D
		_check(collect != null and collect.visible, "a thief taking vault gold must show the collect model")
		_check(NodeProbes.playing_clip(vulpin).contains("collect"), "a thief taking vault gold must play the collect animation")
	game.hero.erase("collecting_gold")
	game.hero["lockpicking"] = true
	game.hero["lockpick_pos"] = Vector2i(4, 3)
	world._sync_hero(game)
	if vulpin != null:
		var lockpicking := NodeProbes.child(vulpin, "Lockpicking") as Node3D
		_check(lockpicking != null and lockpicking.visible,
			"a thief opening a door must show the lockpicking animation")
		_check(hero_visual.position.is_equal_approx(Vector3(3.82, 0.48, 3.5)),
			"a thief lockpicking a door must stand close to that door")
	game.hero.erase("lockpicking")
	game.hero["dying"] = true
	world._sync_hero(game)
	if vulpin != null:
		var dying := NodeProbes.child(vulpin, "Dying") as Node3D
		_check(dying != null and dying.visible,
			"a defeated thief must show the dying animation before the raid ends")
	game.hero.erase("dying")
	game.hero["kind"] = "paladin"
	world._sync_hero(game)
	_check(lithide != null and lithide.visible, "paladin raids must show the animated Lithide")
	_check(vulpin != null and not vulpin.visible, "paladin raids must hide the animated Vulpin")
	_check(proxy != null and not proxy.visible, "paladin raids must hide the capsule proxy")
	if lithide != null:
		_check(NodeProbes.playing_clip(lithide).contains("walking"), "an advancing paladin must walk")
		_check_stands_on_floor(lithide, world, "Lithide")

	game.hero["fleeing"] = true
	world._sync_hero(game)
	if lithide != null:
		_check(NodeProbes.playing_clip(lithide).contains("running"), "a fleeing paladin must run")
	game.hero["fleeing"] = false
	game.hero["core_striking"] = true
	world._sync_hero(game)
	if lithide != null:
		var attack := NodeProbes.child(lithide, "Attack") as Node3D
		_check(attack != null and attack.visible, "a paladin striking the Core must play its attack animation")
		_check(NodeProbes.playing_clip(lithide).contains("spin") or NodeProbes.playing_clip(lithide).contains("attack"),
			"a paladin striking the Core must play the axe spin attack clip")
		var attack_player := NodeProbes.first_animation_player(attack)
		_check(attack_player != null and attack_player.get_animation(attack_player.current_animation).loop_mode != Animation.LOOP_NONE,
			"the core strike must loop while the paladin is striking")
	game.hero.erase("core_striking")
	game.hero["door_striking"] = true
	world._sync_hero(game)
	if lithide != null:
		var door_attack := NodeProbes.child(lithide, "Attack") as Node3D
		_check(door_attack != null and door_attack.visible,
			"a paladin forcing a door must show the attack model")
		_check(NodeProbes.playing_clip(lithide).contains("spin") or NodeProbes.playing_clip(lithide).contains("attack"),
			"a paladin forcing a door must play the attack clip")
	game.hero.erase("door_striking")

	game.hero["fleeing"] = false
	game.hero["kind"] = "ranger"
	world._sync_hero(game)
	_check(vulpin != null and not vulpin.visible, "ranger heroes must not be mistaken for the Vulpin")
	_check(lithide != null and not lithide.visible, "ranger heroes must hide the animated Lithide")
	_check(mycean != null and not mycean.visible, "ranger heroes must hide the Mycean Mage")
	_check(batrafian != null and batrafian.visible, "ranger heroes must show the animated Batrafian Ranger")
	_check(batrafian != null and batrafian.has_method("has_imported_model")
			and batrafian.call("has_imported_model"),
		"ranger raids must use the imported Batrafian Ranger GLB")
	_check(proxy != null and not proxy.visible, "ranger heroes must hide the capsule proxy")
	if batrafian != null:
		_check(NodeProbes.playing_clip(batrafian).contains("walking"), "an advancing ranger must walk")
		_check_stands_on_floor(batrafian, world, "Batrafian")

	game.hero["fleeing"] = true
	world._sync_hero(game)
	if batrafian != null:
		_check(NodeProbes.playing_clip(batrafian).contains("running"), "a fleeing ranger must run")
	game.hero["fleeing"] = false
	game.hero["jumping_trap"] = true
	world._sync_hero(game)
	if batrafian != null:
		var jumping := NodeProbes.child(batrafian, "JumpTrap") as Node3D
		_check(jumping != null and jumping.visible, "a ranger jumping a trap must show the jump animation")
		_check(NodeProbes.playing_clip(batrafian).contains("jump") or NodeProbes.playing_clip(batrafian).contains("obstacle"),
			"a ranger jumping a trap must play its jump clip")
	game.hero.erase("jumping_trap")
	game.hero["ranged_attacking"] = true
	world._sync_hero(game)
	if batrafian != null:
		var ranger_attack := NodeProbes.child(batrafian, "Attack") as Node3D
		_check(ranger_attack != null and ranger_attack.visible,
			"a ranger firing must show the archery attack animation")
		_check(NodeProbes.playing_clip(batrafian).contains("archery") or NodeProbes.playing_clip(batrafian).contains("shot")
				or NodeProbes.playing_clip(batrafian).contains("attack"),
			"a ranger firing must play its archery clip")
	game.hero.erase("ranged_attacking")
	game.hero["dying"] = true
	world._sync_hero(game)
	if batrafian != null:
		var dead := NodeProbes.child(batrafian, "Dead") as Node3D
		_check(dead != null and dead.visible, "a defeated ranger must show the death animation")
	game.hero.erase("dying")

	game.hero["kind"] = "mage"
	game.hero["fleeing"] = false
	game.hero["arcane_opening"] = true
	world._sync_hero(game)
	_check(mycean != null and mycean.visible, "mage raids must show the Mycean Mage")
	_check(mycean != null and mycean.has_method("has_imported_model")
			and mycean.call("has_imported_model"),
		"mage raids must use the imported Mycean Mage GLB")
	_check(proxy != null and not proxy.visible, "mage raids must hide the capsule proxy")
	if mycean != null:
		_check_stands_on_floor(mycean, world, "Mycean")

	game.raid_active = false
	game.hero = {}
	world._sync_hero(game)
	_check(NodeProbes.child(world, "CoreAttackPreview") == null,
		"preparation must not spawn a paladin test preview")

	game.free()
	world.queue_free()
	await process_frame
	if failures == 0:
		print("OK: DungeonWorld selects animated hero models by archetype")
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _check_stands_on_floor(hero_root: Node, world: Node3D, label: String) -> void:
	_check(absf((hero_root as Node3D).global_position.y - world.FLOOR_H) <= 0.01,
		"%s bottom origin must stand on the dungeon floor" % label)
