extends SceneTree
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const OUT="res://docs/reference/interface-review/v16-living-eye/native/"
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: ",message)
func settle() -> void:
	for i in 6: await process_frame
func run() -> void:
	create_timer(45).timeout.connect(func(): push_error("Eye world timeout"); quit(2))
	var game=GAME.instantiate(); game.persistence_enabled=false; root.add_child(game); game.set_process(false)
	await process_frame; game.restart(true); game.selected=Vector2i(-1,-1); game.notice=""
	var hud=game.get_node("HUD"); hud._welcome=false; game.changed.emit(true)
	game.start_raid()
	var view=game.get_node("PlayArea/World/Dungeon")
	var camera=game.get_node("PlayArea/World/Camera2D")
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(568,299),Vector2i(390,844),Vector2i(320,568)]:
		root.size=extent; await settle(); game.get_node("Input").center_core(); await settle()
		for side in [-1,1]:
			camera.position=view._actor.position-Vector2(side*180,-80); camera.force_update_scroll()
			await settle(); hud._update_eye_target()
			hud.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
			for frame in 12: hud.header.refresh(game,.05)
			var eye= hud.header.eye
			var origin:Vector2=eye.get_global_transform_with_canvas()*(hud.header.EYE_CENTER*eye.size)
			check(signf(hud.header.world_target.x-origin.x)==side,"rendered hero projection after pan "+str(extent)+str(side))
			check(signf(hud.header.behavior.look.x)==side,"gaze follows projected hero "+str(extent)+str(side))
			check(hud.header.behavior.mode=="traque","real raid activates tracking "+str(extent))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"game-%dx%d.png" % [extent.x,extent.y])
	# Real viewport pan still works with eye observing all input.
	game.raid.raid_active=false; game.raid.hero={}; game.changed.emit(false)
	var touch:=InputEventScreenTouch.new(); touch.index=0; touch.pressed=true; touch.position=Vector2(80,300)
	root.push_input(touch,true); await process_frame
	check(hud.header._touches.has(0),"fixture holds real touch before rotation")
	root.size=Vector2i(390,844); await settle()
	check(hud.header._touches.is_empty() and not hud.header._pointer.is_finite(),"rotation cancels stale eye touch even without a release")
	root.size=Vector2i(1280,720); await settle()
	# Existing mobile input intentionally suppresses synthetic mouse for 500ms
	# after an interrupted touch; exercise the next real desktop gesture later.
	await create_timer(.55).timeout
	var start:Vector2=camera.position
	var p:=Vector2(480,430)
	var press:=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=p
	root.push_input(press,true); await process_frame
	var motion:=InputEventMouseMotion.new(); motion.position=p+Vector2(90,30); motion.relative=Vector2(90,30); motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true); await process_frame
	press.position=motion.position; press.pressed=false; root.push_input(press,true); await process_frame
	check(camera.position.distance_to(start)>10,"eye input listener does not swallow world pan")
	# UI events still open the domain exactly once, with no construction.
	var before:int=game.sim.gold
	var eye_point:Vector2=hud.header.eye_button.get_global_transform_with_canvas()*(hud.header.eye_button.size/2)
	for down in [true,false]:
		var click:=InputEventMouseButton.new(); click.button_index=MOUSE_BUTTON_LEFT; click.pressed=down; click.position=eye_point
		root.push_input(click,true); await process_frame
	check(game.paused and game.sim.gold==before,"eye click pauses, never builds underneath")
	var file:=FileAccess.open(OUT+"world-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Eye world checks: ",checks," failures: ",failures.size()); quit(0 if failures.is_empty() else 1)
