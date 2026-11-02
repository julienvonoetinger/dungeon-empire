extends SceneTree
const OUT := "res://artifacts/mycean-attack/native/"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr(message)
func settle() -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
func finish() -> void:
	var f := FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("MYCEAN_ATTACK ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var file := "res://scenes/MyceanCoreAttack.tscn"
	check(ResourceLoader.exists(file),"Spore Core attack scene exists")
	if not ResourceLoader.exists(file):
		finish()
		return
	root.size = Vector2i(1280,720)
	var p = load(file).instantiate()
	root.add_child(p)
	await settle()
	p.set_process(false)
	p.set_playing(false)
	check(p.rooms.size() == 4,"Four directions")
	check(is_equal_approx(p.action_duration,1.4),"1400ms clip")
	check(is_equal_approx(p.release_time,.65) and is_equal_approx(p.impact_time,.97),"Separate release and impact")
	for room in p.rooms:
		check(room.hero_grid.is_equal_approx(room.NORMALS[room.facing]*2),"Hero faces Core at two-cell range")
		check(room.core_sprite.texture == room.DEFINITION.get("textures")["heart"],"Actual Core texture")
		check(room.actor.scale.is_equal_approx(Vector2.ONE*.9404255319148935),"Approved hero scale")
		check(room.impact_point.distance_to(room.vortex_center) < .001,"Spore burst targets vortex centre")
		check(room.actor.sprite_frames.get_frame_count(room.facing) == 12,"Twelve poses")
		check(not room.actor.sprite_frames.get_animation_loop(room.facing),"One-shot sprite resource")
		check(room._vortex_animator.materials.size() == 1,"Production vortex shader")
		check(room.charge.z_index == room.actor.z_index and room.charge.get_index() == room.actor.get_index()+1,"Charge follows physical caster layer")
		check(room.launch_point.distance_to(room.emitter_point(5))<.001,"Launch is measured release cap")
		check(room.launch_point.distance_to(room.impact_point)>35,"Visible projectile travel")
	for speed in [0,1,3]:
		p.set_repeat_enabled(false)
		p.set_speed_index(speed)
		p.trigger_action()
		p._process((p.release_time-.001)/p.playback_speed)
		check(p.shot_count == 0 and p.impact_count == 0,"No premature events")
		for room in p.rooms: check(not room.projectile.visible,"No flying orb during charge")
		p._process(.001/p.playback_speed)
		check(p.shot_count == 1 and p.impact_count == 0,"One release, no instantaneous hit")
		for room in p.rooms:
			check(room.projectile.visible,"Projectile visible after release")
			check(room.projectile.position.distance_to(room.launch_point)<.01,"Exact staff-cap handoff")
			check(room.actor.frame == 5,"Body reaches forward-cast pose")
		p._process(.16/p.playback_speed)
		for room in p.rooms:
			check(room.projectile.position.distance_to(room.projectile.path_at(.5))<.01,"Continuous halfway flight")
		p.set_playing(false)
		var old_time: float = p.action_time
		var old_phase: float = p.rooms[0]._vortex_animator.phase
		var old_orb: Vector2 = p.rooms[0].projectile.position
		var old_shader: float = p.rooms[0].projectile.orb.material.get_shader_parameter("phase")
		p._process(1)
		check(p.action_time == old_time and p.rooms[0]._vortex_animator.phase == old_phase,"Pause freezes shot and vortex")
		check(p.rooms[0].projectile.position == old_orb and p.rooms[0].projectile.orb.material.get_shader_parameter("phase") == old_shader,"Pause freezes spore flow")
		p.set_playing(true)
		p._process(.159/p.playback_speed)
		check(p.impact_count == 0,"No hit before orb arrives")
		p._process(.001/p.playback_speed)
		check(p.impact_count == 1,"Hit at arrival")
		for room in p.rooms:
			check(room.projectile.position.distance_to(room.impact_point)<.01,"Orb reaches Core")
			check(not room.projectile.visible,"Projectile consumed on impact")
			check(room.burst.visible and room.burst.progress<.0001,"Burst visible on first impact instant")
		p._process(2)
		check(p.shot_count == 1 and p.impact_count == 1 and not p.active,"Exactly one shot and hit")
		for room in p.rooms:
			check(room.actor.frame == 11,"Returns to guard")
			check(not room.charge.visible and not room.projectile.visible and not room.burst.visible,"All effects end cleanly")
	p.set_speed_index(3)
	p.trigger_action()
	p._process(1)
	check(p.shot_count == 1 and p.impact_count == 1,"Large x2 tick cannot skip either event")
	p.set_playing(false)
	p.seek_action(.8)
	p.seek_action(.2)
	p.seek_action(1.0)
	check(p.shot_count == 1 and p.impact_count == 1,"Manual seeking never emits combat events")
	p.seek_action(.81)
	var saved_point: Vector2 = p.rooms[0].projectile.position
	p.seek_action(.1)
	p.seek_action(.81)
	check(p.rooms[0].projectile.position == saved_point,"Seek deterministically restores projectile")
	p.set_speed_index(1)
	p.trigger_action()
	p.set_playing(false)
	p.next_pose()
	check(p.actors[0].frame == 1,"Frame step")
	p.set_repeat_enabled(true)
	p.set_playing(true)
	p.seek_action(p.action_duration)
	var count: int = p.trigger_count
	p._process(.79)
	check(p.trigger_count == count,"Repeat waits")
	p._process(.02)
	check(p.trigger_count == count+1 and p.shot_count == 0 and p.impact_count == 0,"Repeat resets events")
	p.set_repeat_enabled(false)
	p.set_playing(false)
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size = size
		await settle()
		for index in 12:
			p.seek_action(p._starts[index])
			for room in p.rooms:
				check(room.actor.position == room.grid_to_local(room.hero_grid) and room.contact_shadow.position == room.actor.position,"Root and shadow stay planted")
			for room in p.rooms:
				var actor: AnimatedSprite2D = room.actor
				var ink: Rect2i = actor.sprite_frames.get_frame_texture(actor.animation,index).get_image().get_used_rect()
				var tl := actor.to_global(actor.offset+Vector2(ink.position))
				var br := actor.to_global(actor.offset+Vector2(ink.end))
				var panel: Control = room.get_parent().get_parent()
				check(panel.get_global_rect().grow(1).encloses(Rect2(tl,br-tl)),"Hero fits stage")
		for time in [.55,.65,.81,.97,1.08]:
			p.seek_action(time)
			await settle()
			for room in p.rooms:
				var panel: Control = room.get_parent().get_parent()
				var bounds: Rect2 = room.get_content_rect()
				var tl: Vector2 = room.to_global(bounds.position)
				var br: Vector2 = room.to_global(bounds.end)
				check(panel.get_global_rect().grow(1).encloses(Rect2(tl,br-tl)),"World and flight fit stage")
			for button in p.find_children("*","BaseButton",true,false):
				check(p.get_global_rect().encloses(button.get_global_rect()),"Controls fit")
				check(button.size.y >= 48,"Touch control height")
			check(root.get_texture().get_image().save_png("%sshot-%dx%d-%d.png" % [OUT,size.x,size.y,int(time*1000)]) == OK,"Capture")
	root.size = Vector2i(1280,720)
	for i in 36:
		p.seek_action(minf(i*.04,p.action_duration))
		await settle()
		root.get_texture().get_image().save_png(OUT+"motion-%02d.png"%i)
	p.queue_free()
	await process_frame
	finish()
