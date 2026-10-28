extends SceneTree
var failures: Array[String]=[]
var checks:=0
var app: Node2D
var out: String
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	out=OS.get_cmdline_user_args()[0]
	app=load("res://preview/preview.tscn").instantiate();root.add_child(app)
	for i in 5:await process_frame
	check(app.ready_for_test,"Viewer initialized")
	for profile in app.PROFILES:
		app.set_profile(profile)
		for state in app.STATES:
			app.set_action(state);app.elapsed=100;app._update_actors()
			for i in 4:
				var a: AnimatedSprite2D=app.actors[i]
				check(a.animation==app.DIRS[i]+"-"+state,"Facing/state "+profile+state)
				check(a.sprite_frames.get_frame_texture(a.animation,a.frame)!=null,"Texture "+profile+state)
				if not app.data.clips[String(a.animation)].loop:check(a.frame==a.sprite_frames.get_frame_count(a.animation)-1,"Final hold "+profile+state)
	app.set_profile("balanced");app.set_action("walk")
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(667,375),Vector2i(568,320),Vector2i(390,844),Vector2i(320,568)]:
		root.size=size
		for i in 4:await process_frame
		app.layout_ui();await process_frame
		check(app.panel.get_global_rect().encloses(app.info.get_global_rect()),"Info inside panel "+str(size))
		for control in app.controls:
			var r: Rect2=control.get_global_rect()
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(r),"Control contained "+str(size)+str(control))
			check(r.size.y>=48 and r.size.x>=48,"Touch target "+str(size))
			if control is Button:check(control.get_theme_font("font").get_string_size(control.text,HORIZONTAL_ALIGNMENT_LEFT,-1,control.get_theme_font_size("font_size")).x+20<=r.size.x,"Text inset "+str(size)+control.text)
			for other in app.controls:
				if control!=other:check(not r.intersects(other.get_global_rect()),"Controls do not overlap "+str(size))
		var before: float=app.elapsed;app.pause_button.pressed.emit();await create_timer(.1).timeout;check(is_equal_approx(before,app.elapsed),"Pause "+str(size));app.pause_button.pressed.emit()
		app.replay_button.pressed.emit();check(app.elapsed==0,"Replay "+str(size))
		app.slow_button.pressed.emit();check(app.slow,"Slow "+str(size));app.slow_button.pressed.emit()
		app.detail_button.pressed.emit();check(app.detail,"Zoom "+str(size));app.detail_button.pressed.emit()
		# Exercise an actual touch press/release through the viewport.
		var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=app.pause_button.get_global_rect().get_center();touch.pressed=true;Input.parse_input_event(touch)
		await process_frame
		var release:=InputEventScreenTouch.new();release.index=0;release.position=touch.position;release.pressed=false;Input.parse_input_event(release)
		await process_frame;check(app.paused,"Real touch pause "+str(size));app.pause_button.pressed.emit()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+"-%dx%d.png"%[size.x,size.y])
	check(not FileAccess.file_exists("user://isometric_run_v1.save"),"No game save in separate viewer")
	FileAccess.open(out+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"profiles":3,"states":9,"directions":4,"sizes":6},"\t"))
	print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
