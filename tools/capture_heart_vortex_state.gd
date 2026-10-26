extends SceneTree
## Background presentation observations. Never load/write the user's save slot.
const OUT := "res://docs/reference/heart-vortex-review/v1/"
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
var observations: Array = []

func _initialize() -> void:
	call_deferred("_capture")

func _observe(name: String, view: Node2D) -> void:
	var clock = view._vortex_animator
	var items: Array = []
	if is_instance_valid(clock):
		for material in clock.materials:
			var names: Array = []
			for uniform in material.shader.get_shader_uniform_list(): names.append(str(uniform.name))
			items.append({"phase":material.get_shader_parameter("phase"),"enabled":material.get_shader_parameter("animation_enabled"),"uniforms":names})
	observations.append({"name":name,"clock_count":view.get_children().filter(func(n): return str(n.name).begins_with("VortexAnimator")).size(),"phase":clock.phase if is_instance_valid(clock) else -1,"processing":clock.is_processing() if is_instance_valid(clock) else false,"materials":items,"ground_effects":view._world.get_children().filter(func(n): return n is Sprite2D and n.has_meta("self_light")).size()})

func _capture() -> void:
	var scene: Node2D = load("res://scenes/DungeonHeart.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var view: Node2D = scene.get_node("Heart") if scene.has_node("Heart") else scene
	if not view.get("_vortex_animator"):
		for child in scene.get_children():
			if child.get("_vortex_animator"): view = child
	_observe("standalone-live",view)
	view._vortex_animator.set_process(false)
	view._vortex_animator._process(3.0)
	_observe("quarter-cycle",view)
	view.refresh_preview(false)
	view._vortex_animator.set_process(false)
	await process_frame
	_observe("rebuilt-same-phase",view)
	view._vortex_animator = null
	view.refresh_preview(false)
	view._vortex_animator.set_process(false)
	_observe("recover-existing-clock",view)
	view.vortex_animation_enabled = false
	_observe("disabled",view)
	view.vortex_animation_enabled = true
	view._vortex_animator.set_process(false)
	_observe("enabled-resume",view)
	view._vortex_animator.phase = .99
	view._vortex_animator._process(.24)
	_observe("loop-wrap",view)
	scene.queue_free()
	await process_frame
	var multi := RENDERER.new()
	root.add_child(multi)
	multi.render_plan({"cells":{},"openings":{},"hearts":PackedVector2Array([Vector2.ZERO,Vector2(2,0)])},{},false)
	multi._vortex_animator.set_process(false)
	_observe("two-hearts-one-clock",multi)
	multi.render_plan({"cells":{},"openings":{},"hearts":PackedVector2Array()},{},false)
	await process_frame
	_observe("hearts-removed",multi)
	multi.queue_free()
	await process_frame
	var game := GAME.instantiate()
	game.save_path = OUT + "never-created.save"
	root.add_child(game)
	game.set_process(false)
	game.sim.new_map()
	game.sim.grid[7][7] = TYPES.Tile.CORE
	view = game.get_node("PlayArea/World/Dungeon")
	view.rebuild()
	view._vortex_animator.set_process(false)
	_observe("game-initial",view)
	view._vortex_animator._process(1.0)
	_observe("game-running",view)
	game.paused = true
	view._vortex_animator._process(1.0)
	_observe("game-paused",view)
	game.paused = false
	game.confirmation_open = true
	view._vortex_animator._process(1.0)
	_observe("confirmation",view)
	game.confirmation_open = false
	game.result_open = true
	view._vortex_animator._process(1.0)
	_observe("raid-result",view)
	game.result_open = false
	game.save_blocked = true
	view._vortex_animator._process(1.0)
	_observe("save-blocked",view)
	game.save_blocked = false
	game.sim.game_over = true
	view._vortex_animator._process(1.0)
	_observe("game-over",view)
	game.sim.game_over = false
	view._vortex_animator._process(1.0)
	_observe("game-resumed",view)
	game.queue_free()
	await process_frame
	var file := FileAccess.open(OUT+"state-inventory.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"Static headless state observations; no GPU capture or raid simulation","observations":observations},"\t"))
	file.close()
	print("Vortex inventory: ",observations.size()," observations. No save writes.")
	quit()
