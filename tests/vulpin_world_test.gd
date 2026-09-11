extends SceneTree

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

	var vulpin: Node = world.find_child("VulpinHero", true, false)
	var lithide: Node = world.find_child("LithideHero", true, false)
	var proxy: Node = world.find_child("HeroProxy", true, false)
	var hero_visual := world.find_child("HeroVisual", true, false) as Node3D
	_check(vulpin != null and vulpin.visible, "thief raids must show the animated Vulpin")
	_check(lithide != null and not lithide.visible, "thief raids must hide the animated Lithide")
	_check(proxy != null and not proxy.visible, "thief raids must hide the capsule proxy")
	if vulpin != null:
		_check(_playing_clip(vulpin).contains("walking"), "an advancing thief must walk")
		_check(absf((vulpin as Node3D).global_position.y - world.FLOOR_H) <= 0.01,
			"Vulpin bottom origin must stand on the dungeon floor")

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
		_check(_playing_clip(vulpin).contains("running"), "a fleeing thief must run")

	game.hero["fleeing"] = false
	game.hero["collecting_gold"] = true
	world._sync_hero(game)
	if vulpin != null:
		var collect := vulpin.find_child("Collect", true, false) as Node3D
		_check(collect != null and collect.visible, "a thief taking vault gold must show the collect model")
		_check(_playing_clip(vulpin).contains("collect"), "a thief taking vault gold must play the collect animation")
	game.hero.erase("collecting_gold")
	game.hero["kind"] = "paladin"
	world._sync_hero(game)
	_check(lithide != null and lithide.visible, "paladin raids must show the animated Lithide")
	_check(vulpin != null and not vulpin.visible, "paladin raids must hide the animated Vulpin")
	_check(proxy != null and not proxy.visible, "paladin raids must hide the capsule proxy")
	if lithide != null:
		_check(_playing_clip(lithide).contains("walking"), "an advancing paladin must walk")
		_check(absf((lithide as Node3D).global_position.y - world.FLOOR_H) <= 0.01,
			"Lithide bottom origin must stand on the dungeon floor")

	game.hero["fleeing"] = true
	world._sync_hero(game)
	if lithide != null:
		_check(_playing_clip(lithide).contains("running"), "a fleeing paladin must run")
	game.hero["fleeing"] = false
	game.hero["core_striking"] = true
	world._sync_hero(game)
	if lithide != null:
		var attack := lithide.find_child("Attack", true, false) as Node3D
		_check(attack != null and attack.visible, "a paladin striking the Core must play its attack animation")
		_check(_playing_clip(lithide).contains("spin") or _playing_clip(lithide).contains("attack"),
			"a paladin striking the Core must play the axe spin attack clip")
		var attack_player := attack.find_child("AnimationPlayer", true, false) as AnimationPlayer
		_check(attack_player != null and attack_player.get_animation(attack_player.current_animation).loop_mode != Animation.LOOP_NONE,
			"the core strike must loop while the paladin is striking")
	game.hero.erase("core_striking")

	game.hero["fleeing"] = false
	game.hero["kind"] = "ranger"
	world._sync_hero(game)
	_check(vulpin != null and vulpin.visible, "ranger heroes must still show the animated Vulpin")
	_check(lithide != null and not lithide.visible, "ranger heroes must hide the animated Lithide")
	_check(proxy != null and not proxy.visible, "ranger heroes must hide the capsule proxy")
	if vulpin != null:
		_check(_playing_clip(vulpin).contains("walking"), "ranger heroes must use the Vulpin walking clip")

	game.raid_active = false
	game.hero = {}
	world._sync_hero(game)
	_check(world.find_child("CoreAttackPreview", true, false) == null,
		"preparation must not spawn a paladin test preview")

	game.free()
	world.queue_free()
	await process_frame
	if failures == 0:
		print("OK: DungeonWorld selects animated hero models by archetype")
	quit(1 if failures else 0)


func _playing_clip(hero: Node) -> String:
	for player in hero.find_children("*", "AnimationPlayer", true, false):
		if player.is_playing():
			return String(player.current_animation).to_lower()
	return ""


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
