extends Node
## No-save review wrapper around the actual game's shared excavation renderer.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const Terrain=preload("res://scripts/dig_terrain_preview.gd")
var game: IsometricGameSession
var targets: Control
var continuous_recess:=true
var sloped_recess:=false

func _ready() -> void:
	game=GAME.instantiate()
	game.persistence_enabled=false
	var terrain=game.get_node("PlayArea/World/Terrain")
	terrain.set_script(Terrain)
	terrain.continuous_recess=continuous_recess
	terrain.sloped_recess=sloped_recess
	add_child(game); game.set_process(false)
	var hud=game.get_node("HUD")
	hud._welcome=false
	game.restart(true); game.notice=""; game.cancel_selection()
	targets=hud.dig_targets
	for node in hud.root.get_children():
		if node.has_meta("transient_feedback"): node.queue_free()
	call_deferred("center_review")

func center_review() -> void:
	var view=game.get_node("PlayArea/World/Dungeon")
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(7.5,8.5))-Vector2(0,90)
	camera.force_update_scroll()
