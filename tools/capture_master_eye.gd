extends SceneTree
const PREVIEW=preload("res://scenes/MasterEyePreview.tscn")
const OUT="res://docs/reference/interface-review/v16-living-eye/native/"
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: ",message)
func draw_frame() -> void:
	await process_frame; await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
func run() -> void:
	create_timer(45).timeout.connect(func(): push_error("Eye capture timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(900,650)
	var scene=PREVIEW.instantiate(); root.add_child(scene); await process_frame; scene.set_process(false)
	for index in 7:
		scene.select_mode(index)
		scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		for i in 5: scene._process(.1)
		scene.target.hide()
		await draw_frame()
		var frame:=root.get_texture().get_image()
		frame.save_png(OUT+scene.MODES[index]+".png")
		frame.get_region(Rect2i(scene.detail.get_rect())).save_png(OUT+scene.MODES[index]+"-eye.png")
	# Native pixel invariant: expression cannot repaint the runes/stone/lip.
	scene.select_mode(0); scene.header.clear_pointer(); scene.header.world_target=Vector2.INF
	scene.header.refresh(scene.session); await draw_frame()
	var baseline:=root.get_texture().get_image()
	var unchanged:=0; var altered:=0
	for index in range(1,7):
		scene.select_mode(index)
		scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		for i in 5: scene._process(.1)
		scene.target.hide()
		await draw_frame()
		var frame:=root.get_texture().get_image()
		for y in range(int(scene.detail.position.y),int(scene.detail.get_rect().end.y)):
			for x in range(int(scene.detail.position.x),int(scene.detail.get_rect().end.x)):
				var uv:Vector2=(Vector2(x,y)-scene.detail.position)/scene.detail.size
				var r:float=((uv-scene.header.EYE_CENTER)*Vector2(1,342.0/410.0)).length()
				if r>.178 and baseline.get_pixel(x,y)!=frame.get_pixel(x,y): altered+=1
				elif r>.178: unchanged+=1
	check(altered==0,"all expressions preserve outer stone/runes/lip pixels (%d changed / %d stable)" % [altered,unchanged])
	# Native held frames for review media (not extra runtime sprites).
	DirAccess.make_dir_recursive_absolute("res://artifacts/master-eye/frames")
	for index in 7:
		scene.select_mode(index); scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		if index==0:
			for i in 74: scene._process(.1)
		var count:=60 if index==2 else 20
		for frame_index in count:
			scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
			scene._process(.1); scene.target.hide(); await draw_frame()
			root.get_texture().get_image().get_region(Rect2i(scene.detail.get_rect())).save_png("res://artifacts/master-eye/frames/%s-%03d.png" % [scene.MODES[index],frame_index])
	# Actual viewport touch, no direct signal dispatch. Gaze changes smoothly.
	scene.select_mode(0)
	scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var touch:=InputEventScreenTouch.new(); touch.index=0; touch.pressed=true; touch.position=Vector2(70,300)
	root.push_input(touch,true); await process_frame
	scene.header.refresh(scene.session,.1)
	check(scene.header.behavior.look.x<0,"real left touch moves gaze left")
	var second:=InputEventScreenTouch.new(); second.index=1; second.pressed=true; second.position=Vector2(830,300)
	root.push_input(second,true); await process_frame
	check(not scene.header._pointer.is_finite(),"multitouch cancels gaze gesture")
	for event in [touch,second]: event.pressed=false; root.push_input(event,true)
	await process_frame
	scene.select_mode(2); scene.header.world_target=Vector2(830,400)
	touch.pressed=true; root.push_input(touch,true); await process_frame
	scene.header.refresh(scene.session,.1)
	check(scene.header.behavior.look.x>0,"raid ignores touch and follows target")
	var held:Vector2=scene.header.behavior.look
	scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	scene.header.refresh(scene.session,.1)
	check(scene.header.behavior.look==held and not scene.header._pointer.is_finite(),"focus loss clears input and freezes gaze")
	scene.header.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	touch.pressed=false; root.push_input(touch,true)
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(568,299),Vector2i(390,844),Vector2i(320,568)]:
		root.size=extent; await process_frame; scene.fit(); scene.select_mode(0)
		scene._process(0)
		await draw_frame()
		root.get_texture().get_image().save_png(OUT+"review-%dx%d.png" % [extent.x,extent.y])
		check(scene.controls.get_rect().end.x<=extent.x and scene.controls.get_rect().end.y<=extent.y,"preview controls fit "+str(extent))
	var file:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Eye pixel/input/layout checks: ",checks," failures: ",failures.size()); quit(0 if failures.is_empty() else 1)
