extends Node
## No-save visual prototype, deliberately separate from the current main game.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const Targets=preload("res://scripts/dig_blocks_preview_targets.gd")
var game: IsometricGameSession
var targets: Control

func _ready() -> void:
	game=GAME.instantiate()
	game.persistence_enabled=false
	add_child(game); game.set_process(false)
	var hud=game.get_node("HUD")
	hud._welcome=false
	game.restart(true); game.notice=""; game.cancel_selection()
	var old: Control=hud.dig_targets
	old.get_parent().remove_child(old); old.queue_free()
	targets=Targets.new(); targets.hud=hud
	hud.dig_targets=targets; hud.root.add_child(targets)
	var view=game.get_node("PlayArea/World/Dungeon")
	view.assisted_dig_cells.clear(); view._floor_guide.hide()
	for node in hud.root.get_children():
		if node.has_meta("transient_feedback"): node.queue_free()
	call_deferred("center_review")

func center_review() -> void:
	var view=game.get_node("PlayArea/World/Dungeon")
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(7.5,8.5))-Vector2(0,90)
	camera.force_update_scroll()
