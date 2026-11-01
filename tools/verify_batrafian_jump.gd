extends SceneTree
## Isolated scene only: no game session and no player saves.
var failures: Array[String] = []
var checks := 0
var output_dir := "res://artifacts/batrafian-jump/"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	check(ResourceLoader.exists("res://scenes/BatrafianJump.tscn"), "Missing Batrafian jump scene")
	if not failures.is_empty():
		print("BATRAFIAN_JUMP: ", checks, " checks, ", failures.size(), " failures")
		quit(1)
		return
	call_deferred("verify")

func settle() -> void:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw

func verify() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280,720)
	var preview = load("res://scenes/BatrafianJump.tscn").instantiate()
	root.add_child(preview)
	await settle()
	preview.set_playing(false)
	preview.set_process(false)
	check(is_equal_approx(preview.action_duration,1.0), "One-second jump")
	check(preview.actors.size()==4 and preview.stages.size()==4, "Four directions")
	for actor in preview.actors:
		check(actor.sprite_frames.get_frame_count(actor.animation)==12, "Twelve held poses")
		check(not actor.sprite_frames.get_animation_loop(actor.animation), "One-shot clip")
		check(actor.sprite_frames.get_frame_texture(actor.animation,0).region==actor.sprite_frames.get_frame_texture(actor.animation,11).region,"Reuse identical rest endpoint")
	for t in [0.0,.1,.199,.2,.26,.34,.435,.52,.6,.67,.74,.9,1.0,2.0]:
		preview.seek_action(t)
		for stage in preview.stages:
			var flight := clampf((t-.2)/.47,0,1)
			check(stage.hero_grid.is_equal_approx(stage.start_grid.lerp(stage.end_grid,flight)), "Ground path " + str(t))
			var height := 4.0*.55*flight*(1-flight)
			check(is_equal_approx(stage.root_height,height), "Physical height " + str(t))
			check(stage.contact_shadow.position.is_equal_approx(stage.grid_to_local(stage.hero_grid)), "Shadow stays on floor")
			check(stage.actor.position.is_equal_approx(stage.contact_shadow.position-Vector2(0,height*stage.model_z_to_pixels)), "Height applied once")
			check(stage.actor.frame==preview.actors[0].frame, "All directions share pose clock")
	preview.seek_action(.435)
	check(is_equal_approx(preview.stages[0].root_height,.55), "Apex")
	preview.seek_action(.34)
	var frozen: Vector2 = preview.actors[0].position
	preview._process(.1)
	check(preview.actors[0].position==frozen and is_equal_approx(preview.action_time,.34), "Pause holds frame and translation")
	preview.next_pose()
	check(preview.actors[0].frame==6 and is_equal_approx(preview.action_time,.43), "Step moves one full pose")
	preview.trigger_action()
	preview.set_speed_index(1)
	preview._process(.26)
	var normal: Vector2 = preview.actors[0].position
	preview.trigger_action()
	preview.set_speed_index(3)
	preview._process(.13)
	check(preview.actors[0].position.is_equal_approx(normal) and preview.actors[0].frame==4, "Double speed shares trajectory and pose clock")
	preview._process(2.0)
	check(not preview.active and preview.actors[0].frame==11, "Finish rests at landing")
	var landed: Vector2 = preview.actors[0].position
	preview._process(2.0)
	check(preview.actors[0].position==landed, "No automatic restart without Repeat")
	preview.set_repeat_enabled(true)
	var triggers: int = preview.trigger_count
	preview._process(.41)
	check(preview.trigger_count==triggers+1 and preview.actors[0].frame==0, "Repeat restarts after gap")
	preview.set_repeat_enabled(false)
	preview.set_speed_index(1)
	preview.set_playing(false)
	for view_size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size=view_size
		await settle()
		for t in [0.13,.435,.74]:
			preview.seek_action(t)
			await settle()
			for actor in preview.actors:
				var host: Control=actor.get_parent().get_parent().get_parent().get_parent()
				var texture: Texture2D=actor.sprite_frames.get_frame_texture(actor.animation,actor.frame)
				var used:=Rect2(texture.get_image().get_used_rect())
				var ink: Rect2=actor.get_global_transform()*Rect2(actor.offset+used.position,used.size)
				check(host.get_global_rect().grow(.5).encloses(ink), "Sprite fits stage "+str(view_size))
			check(root.get_texture().get_image().save_png(output_dir+"jump-%dx%d-%d.png"%[view_size.x,view_size.y,roundi(t*1000)])==OK,"Capture")
		for button in preview.find_children("*","BaseButton",true,false):
			check(preview.get_global_rect().encloses(button.get_global_rect()),"Controls fit "+str(view_size))
	preview.set_playing(true)
	preview.trigger_action()
	preview.set_process(true)
	await create_timer(.3).timeout
	check(preview.action_time>.2 and preview.actors[0].frame>=3,"Live playback")
	var file:=FileAccess.open(output_dir+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("BATRAFIAN_JUMP: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
