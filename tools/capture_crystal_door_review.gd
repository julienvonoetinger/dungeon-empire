extends SceneTree
## Native visual proposal, no session or save I/O.
const Stage=preload("res://tools/crystal_door_review_stage.gd")
const OUT="res://docs/reference/door-redesign/seal-v1/hero-fit-v15-iron-crystals/"
var backdrop: ColorRect
var stages: Array=[]
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	root.size=Vector2i(1200,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	backdrop=ColorRect.new(); backdrop.color=Color("101722"); backdrop.size=root.size; root.add_child(backdrop)
	for revision in [false,true]:
		var stage=Stage.new(); stage.use_proposal=revision; backdrop.add_child(stage); stage.build("nw")
		stage.scale=Vector2.ONE*1.15
		stage.position=Vector2(600,370)-stage.lock_local*1.15
		stage.review_pose("idle"); stage.actor.hide(); stage._contact.hide()
		await shot("proposal-context" if revision else "before-context")
		if revision:
			stage.scale=Vector2.ONE*2.1
			stage.position=Vector2(600,410)-stage.lock_local*2.1
			await shot("proposal-detail")
			stage.scale=Vector2.ONE*1.15
			stage.position=Vector2(600,370)-stage.lock_local*1.15
			stage.actor.show(); stage._contact.show(); stage.review_pose("lock",4)
			await shot("proposal-lockpick")
		stage.free()
	root.size=Vector2i(1200,850); backdrop.size=root.size
	for i in 4:
		var stage=Stage.new(); backdrop.add_child(stage); stage.build(["se","sw","nw","ne"][i])
		stage.scale=Vector2.ONE*.76
		stage.position=Vector2(300+(i%2)*600,210+(i/2)*410)-stage.lock_local*.76
		stage.review_pose("idle"); stage.actor.hide(); stage._contact.hide(); stages.append(stage)
	await shot("four-directions")
	for stage in stages: stage.free()
	print("Crystal door review: native context, lockpick and four directions captured; no game session.")
	quit()
