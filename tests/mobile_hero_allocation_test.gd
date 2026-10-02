extends SceneTree

class Game:
	extends Node
	var raid_active := true
	var grid: Array = []
	var hero := {"pos": Vector2i(2, 2), "kind": "proxy", "hp": 80,
		"max_hp": 100, "fleeing": false}

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var game := Game.new()
	for mobile in [true, false]:
		var world = load("res://scripts/world/dungeon_world.gd").new()
		world.mobile_mode = mobile
		root.add_child(world)
		world.set_process(false)
		world._sync_hero(game)
		var proxy_material: Material = world._hero_proxy.material_override
		var bar_mesh: Mesh = world._hero_bar.mesh
		var bar_material: Material = world._hero_bar.material_override
		for i in 30:
			game.hero.hp = 80 - i
			world._sync_hero(game)
		_check(world._hero_proxy.material_override == proxy_material, "hero sync reuses proxy material")
		_check(world._hero_bar.mesh == bar_mesh, "hero sync reuses health mesh")
		_check(world._hero_bar.material_override == bar_material, "hero sync reuses health material")
		if mobile:
			_check(not world._hero_bar.visible, "mobile keeps health mesh hidden")
		else:
			_check(is_equal_approx(world._hero_bar.scale.x, 0.51), "desktop health width tracks HP")
		world.free()
	game.free()
	print("Hero allocation test: ", failures, " failures")
	quit(1 if failures else 0)
