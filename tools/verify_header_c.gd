extends SceneTree
## Native geometry and rune-mask regression, without a game save.
const HEADER = preload("res://scripts/game/ui/hud_master_header.gd")
const SESSION = preload("res://scripts/game/game_session.gd")
const OUT = "res://docs/reference/interface-review/v15-dark-insignia/native/"
var checks := 0
var failures: Array[String] = []
var menu_clicks := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: ",message)

func run() -> void:
	create_timer(20.0).timeout.connect(func(): push_error("Header check timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1280,512); viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var session=SESSION.new(); session.persistence_enabled=false; root.add_child(session)
	session.set_process(false); session.restart(true)
	var header = HEADER.new(); header.theme=header.UI.create()
	viewport.add_child(header)
	check(header.has_method("rune_sample_uv"), "C header exposes calibrated rune centers")
	check(header.get("left_wing") != null and header.get("right_wing") != null, "stone wings resize independently of eye")
	if not failures.is_empty():
		header.free()
		finish()
		return
	for extent in [Vector2(760,96),Vector2(556,84),Vector2(378,96),Vector2(308,96)]:
		header.size=extent
		for amount in [225,38400]:
			session.sim.gold=amount
			for state in ["preparation","construction","raid","pause","result","dead","missing-core"]:
				session.selected=Vector2i(8,8) if state=="construction" else Vector2i(-1,-1)
				session.sim.grid[8][8]=SESSION.Types.Tile.FLOOR if state=="missing-core" else SESSION.Types.Tile.CORE
				session.paused=state=="pause"; session.result_open=state=="result"
				session.sim.game_over=state=="dead"; session.raid.raid_active=state=="raid"
				session.raid.elapsed_seconds=74
				session.sim.core_hp=60
				header.refresh(session); header._layout(); await process_frame
				var context:="%s gold=%d state=%s: " % [extent,amount,state]
				for label in [header.timer,header.gold,header.health]:
					var font: Font=label.get_theme_font("font")
					var font_size: int=label.get_theme_font_size("font_size")
					check(font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=label.size.x+.5,context+"unclipped "+label.text)
					check(Rect2(Vector2.ZERO,extent).grow(.5).encloses(label.get_rect()),context+"inside header "+label.text)
				check(header.timer_icon.get_rect().end.x+3<=header.timer.position.x,context+"timer icon gap")
				check(header.coin.get_rect().end.x+3<=header.gold.position.x,context+"gold icon gap")
				check(header.timer.get_rect().end.y<=header.time_socket.position.y,context+"timer above rail")
				check(header.gold.get_rect().end.y<=header.gold_socket.position.y,context+"gold above rail")
				check(header.eye_button.size.x>=48 and header.eye_button.size.y>=48,context+"touch target")
				check(absf(header.eye.size.x/header.eye.size.y-230.0/192.0)<.001,context+"eye aspect")
				if state=="preparation":
					await RenderingServer.frame_post_draw
					viewport.get_texture().get_image().get_region(Rect2i(Vector2i.ZERO,Vector2i(extent))).save_png(OUT+"layout-%d-%d.png" % [extent.x,amount])
	# Input is sent through the viewport, not by emitting the button signal.
	header.menu_requested.connect(func(): menu_clicks+=1)
	for pressed in [true,false]:
		var click:=InputEventMouseButton.new(); click.button_index=MOUSE_BUTTON_LEFT
		click.position=header.eye_button.get_rect().get_center(); click.pressed=pressed
		viewport.push_input(click,true); await process_frame
	check(menu_clicks==1,"eye button opens domain exactly once")
	# GPU comparison at 4x: every painted rune must dim in the right order.
	header.size=Vector2(1100,384); header._layout()
	for child in header.get_children(): child.visible=child==header.eye
	header.eye_material.set_shader_parameter("phase",0.0)
	header.eye_material.set_shader_parameter("life",1.0)
	await process_frame; await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	var full:=viewport.get_texture().get_image()
	full.get_region(Rect2i(header.eye.get_rect())).save_png(OUT+"runes-100.png")
	var source: Image=header.eye.texture.get_image()
	for uv in [Vector2(.5,.06),Vector2(.3,.12),Vector2(.5,.90)]:
		var rendered:=full.get_pixelv(Vector2i(header.eye.position+uv*header.eye.size))
		var painted:=source.get_pixelv(Vector2i(uv*Vector2(source.get_size())))
		check(absf(rendered.r-painted.r)+absf(rendered.g-painted.g)+absf(rendered.b-painted.b)<.12,"central masonry preserves source color at "+str(uv))
	var samples: Array[Vector2i]=[]
	for sector in 10:
		var center: Vector2=header.eye.position+header.rune_sample_uv(sector)*header.eye.size
		var best:=Vector2i(center); var peak:=-1.0
		for y in range(int(center.y)-9,int(center.y)+10):
			for x in range(int(center.x)-9,int(center.x)+10):
				var pixel:=full.get_pixel(x,y)
				var purple:=pixel.r+pixel.b-pixel.g
				if purple>peak: peak=purple; best=Vector2i(x,y)
		check(peak>1.0,"painted rune %d has a visible illuminated stroke" % sector)
		samples.append(best)
	for hp in [0,1,10,11,20,30,40,50,60,61,70,80,90,91,99,100]:
		header.eye_material.set_shader_parameter("life",hp/100.0)
		await process_frame; await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
		var frame:=viewport.get_texture().get_image()
		for sector in 10:
			var p:=samples[sector]; var before:=full.get_pixelv(p); var after:=frame.get_pixelv(p)
			var difference:=absf(after.r-before.r)+absf(after.g-before.g)+absf(after.b-before.b)
			check((difference<.02) if sector<ceili(hp/10.0) else (difference>.3),"HP%d rune%d on/off matches clockwise tranche" % [hp,sector])
		if hp in [0,60]:
			frame.get_region(Rect2i(header.eye.get_rect())).save_png(OUT+"runes-%d.png" % hp)
			for uv in [Vector2(.5,.90),Vector2(.5,.03),Vector2(.1,.5),Vector2(.5,.49)]:
				var p:=Vector2i(header.eye.position+uv*header.eye.size)
				check(frame.get_pixelv(p).is_equal_approx(full.get_pixelv(p)),"HP%d leaves housing/lip/pupil unchanged" % hp)
	header.free(); session.free(); viewport.free()
	finish()

func finish() -> void:
	print(JSON.stringify({"checks":checks,"failures":failures}))
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures.is_empty() else 1)
