extends SceneTree
## Actual HUD/camera renderer, no player-save read or write.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const OUT="res://docs/reference/interface-review/v15-dark-insignia/native/"
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for frame in 6: await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game=GAME.instantiate(); game.persistence_enabled=false
	root.add_child(game); game.set_process(false); await process_frame
	game.restart(true)
	var hud=game.get_node("HUD"); hud._welcome=false
	game.raid.raid_timer=74; game.sim.core_hp=60
	game.selected=Vector2i(-1,-1); game.notice="Aménagement"
	hud._last_hp=60; game.changed.emit(true)
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(568,299),Vector2i(390,844),Vector2i(320,568)]:
		root.size=extent; await settle(); game.get_node("Input").center_core(); await settle()
		hud.header.refresh(game); await settle()
		for child in hud.root.get_children():
			if child.has_meta("transient_feedback"): child.queue_free()
		await settle(); await RenderingServer.frame_post_draw
		var frame:=root.get_texture().get_image()
		frame.save_png(OUT+"game-%dx%d.png" % [extent.x,extent.y])
		frame.get_region(Rect2i(hud.header.position,hud.header.size)).save_png(OUT+"header-%dx%d.png" % [extent.x,extent.y])
	root.size=Vector2i(1280,720); await settle()
	game.raid.raid_active=true; game.raid.elapsed_seconds=74
	hud.header.refresh(game); await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().get_region(Rect2i(hud.header.position,hud.header.size)).save_png(OUT+"header-raid.png")
	game.queue_free(); await process_frame
	print("Captured C header at five sizes, persistence disabled."); quit()
