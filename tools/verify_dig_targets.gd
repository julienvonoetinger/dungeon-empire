extends SceneTree
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const OUT = "res://artifacts/dig-targets/"
var game
var hud
var view
var hints
var checks := 0
var failures: Array[String] = []
var layouts: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func touch(point: Vector2, pressed: bool, index := 0, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position=point; event.pressed=pressed; event.index=index; event.canceled=canceled
	root.push_input(event,true)
func finish() -> void:
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":layouts},"\t"))
	print("Dig targets: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	game.queue_free(); await process_frame; quit(0 if failures.is_empty() else 1)
func fresh(extent: Vector2i) -> void:
	root.size=extent; game.restart(true); game.notice=""; game.cancel_selection()
	for node in hud.root.get_children():
		if node.has_meta("transient_feedback"): node.queue_free()
	await settle()
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	# Keep the rear wall comfortably below the HUD in short landscape too.
	camera.position=view.grid_to_local(Vector2(7.5,8.5))-Vector2(0,100)
	camera.force_update_scroll(); await settle()
func capture(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game=GAME.instantiate(); game.persistence_enabled=false
	root.add_child(game); game.set_process(false); await settle()
	hud=game.get_node("HUD"); hud._welcome=false
	view=game.get_node("PlayArea/World/Dungeon")
	await fresh(Vector2i(1280,720))
	hints=hud.get("dig_targets")
	check(hints != null,"Hard-to-reach rock needs accessible excavation targets")
	if hints == null: await finish(); return
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(568,320),Vector2i(390,844),Vector2i(320,568)]:
		await fresh(extent)
		hints._signature=0
		var started:=Time.get_ticks_usec()
		hints.refresh()
		layouts.append({"viewport":str(extent),"targets":hints.targets.size(),"layout_ms":(Time.get_ticks_usec()-started)/1000.0})
		check(not hints.targets.is_empty(),"Obscured rock has targets at "+str(extent))
		for target in hints.targets:
			check(game.sim.dig_failure_reason(target.cell).is_empty(),"Targets only refer to legal affordable rock")
			check(hud._safe.has_point(target.anchor) and view.pick_cell(hints._world(target.anchor))==target.cell and not view.solid_covers_point(hints._world(target.anchor)),"Leader ends on a visible part of its own rock cell")
			check(hints.hit_cell(target.center)==target.cell,"Target centre identifies its cell")
			check(hints.hit_cell(target.center+Vector2(23,0))==target.cell,"Target keeps a 48-unit touch diameter")
			check(hud._safe.encloses(Rect2(target.center-Vector2(24,24),Vector2(48,48))),"Whole target fits the safe area")
			check(not hud.blocks_pointer(target.center*hud.scale.x),"HUD does not block excavation targets")
			for angle in range(0,360,15):
				var local_point: Vector2=hints._world(target.center+Vector2.from_angle(deg_to_rad(angle))*23)
				var cell: Vector2i=view.pick_cell(local_point)
				check(game.sim._inside(cell) and game.sim.grid[cell.y][cell.x]==TYPES.Tile.ROCK and not view.solid_covers_point(local_point),"Entire touch disc avoids floor and visible structures")
			for other in hints.targets:
				if target.cell!=other.cell: check(target.center.distance_to(other.center)>=52-.01,"Adjacent touch targets stay separate")
		await capture("%dx%d" % [extent.x,extent.y])
		if hints.targets.is_empty(): continue
		var target: Dictionary=hints.targets[0]
		var gold: int=game.sim.gold
		var point: Vector2=target.center*hud.scale.x
		touch(point,true); await process_frame; touch(point,false); await settle()
		check(game.sim.grid[target.cell.y][target.cell.x]==TYPES.Tile.FLOOR and game.sim.gold==gold-TYPES.COST_DIG,"One native tap digs exactly the connected cell: "+str(extent))
		check(game.tool==TYPES.Tool.NONE and not hud.radial.visible,"Assisted digging stays one-shot")
		game.undo_build(); await settle()
		check(game.sim.grid[target.cell.y][target.cell.x]==TYPES.Tile.ROCK and game.sim.gold==gold,"Assisted digging supports Undo")
	await fresh(Vector2i(844,390))
	if hints.targets.is_empty(): await finish(); return
	var target: Dictionary=hints.targets[0]
	var point: Vector2=target.center*hud.scale.x
	var gold: int=game.sim.gold
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	var before:=camera.position
	touch(point,true); await process_frame
	var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=point+Vector2(70,0)*hud.scale.x
	root.push_input(drag,true); await process_frame
	touch(drag.position,false); await settle()
	check(camera.position!=before and game.sim.gold==gold,"Dragging a target pans without digging")
	await fresh(Vector2i(844,390)); target=hints.targets[0]; point=target.center*hud.scale.x; gold=game.sim.gold
	touch(point,true); await process_frame; touch(point,false,0,true); await settle()
	check(game.sim.gold==gold,"Canceled target press never digs")
	touch(point,true); await process_frame
	var header_point: Vector2=hud.header.get_global_rect().get_center()*hud.scale.x
	touch(header_point,false); await settle()
	check(hints.pressed_cell.x<0 and game.sim.gold==gold,"Release consumed by HUD clears the pressed target")
	touch(point,true); await process_frame; game.set_paused(true); await settle()
	check(hints.pressed_cell.x<0 and game.sim.gold==gold,"Pause cancels target feedback")
	touch(point,false); game.set_paused(false); await settle()
	touch(point,true); touch(point+Vector2(60,0),true,1); await process_frame
	touch(point,false); touch(point+Vector2(60,0),false,1); await settle()
	check(game.sim.gold==gold,"Two fingers never dig a target")
	touch(point,true); await process_frame
	root.size=Vector2i(390,844); await settle(); touch(point,false); await settle()
	check(game.sim.gold==gold,"Rotation cancels a target press")
	hud._open_catalog(); await settle(); check(hints.targets.is_empty(),"Catalog hides targets")
	hud._close_catalog(); game.choose_tool(TYPES.Tool.TRAP_SPIKE); await settle(); check(hints.targets.is_empty(),"Armed tool hides targets")
	game.cancel_selection(); game.set_paused(true); await settle(); check(hints.targets.is_empty(),"Pause hides targets")
	game.set_paused(false); game.start_raid(); await settle(); check(hints.targets.is_empty(),"Raid hides targets")
	await finish()
