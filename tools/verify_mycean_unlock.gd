extends SceneTree
const OUT := "res://artifacts/mycean-unlock/native/"
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
	print("MYCEAN_UNLOCK ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var file := "res://scenes/MyceanArcaneDoor.tscn"
	check(ResourceLoader.exists(file),"Arcane door scene exists")
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
	check(p.preview_title.contains("arcane door"),"Correct action title")
	check(is_equal_approx(p.action_duration,1.85),"1850ms including recovery")
	check(is_equal_approx(p.channel_time,.45) and is_equal_approx(p.unlock_time,1.5),"Matches mage opening hold")
	var game_source := FileAccess.get_file_as_string("res://scripts/game/raid_director.gd")
	check(game_source.contains("MAGE_ARCANE_OPEN_HOLD := 1.5"),"Gameplay hold remains unchanged")
	for room in p.rooms:
		check(room._definition == room.DEFINITION,"Spell preview uses the shared production catalogue")
		var prefix := "door-%s-" % room.CONFIG[room.facing].door
		var expected_closed := [prefix+"leaf",prefix+"jamb-right",prefix+"arch",prefix+"arcane-panel"]
		var expected_open := [prefix+"open-leaf",prefix+"open-jamb-right",prefix+"open-arch"]
		check(room.spell.z_index==room.actor.z_index and room.spell.get_index()==room.actor.get_index()+1,"Spell shares caster depth rather than overlaying masonry")
		for part in room._closed:
			var id: String = part.get_meta("prepared_id")
			check(expected_closed.has(id) and room.DEFINITION.textures.get(id)==part.texture,"Closed frame and arcane seal from production atlas: "+id)
			expected_closed.erase(id)
		check(expected_closed.is_empty(),"All four approved closed parts are present")
		check(room._door_wall_junctions.is_empty(),"Arcane door mounts on intact corridor walls")
		var normal: Vector2 = room.CONFIG[room.facing].normal
		check(room.hero_grid.is_equal_approx(room.seal_grid+normal*1.05),"Hero stands back facing seal")
		check(room.actor.scale.is_equal_approx(Vector2.ONE*.9404255319148935),"Approved hero scale")
		check(room.actor.sprite_frames.get_frame_count(room.facing)==12,"Twelve timing slots")
		check(not room.actor.sprite_frames.get_animation_loop(room.facing),"One-shot resource")
		check(room.seal_point.is_equal_approx(room.grid_to_local(room.seal_grid,.64)),"Seal target on actual door plane")
		for i in 12:
			p.seek_action(p._starts[i])
			check(room.spell.origin.is_equal_approx(room.emitter_point(i)),"Emitter follows measured staff cap")
			check(room.contact_shadow.position==room.actor.position,"Fixed contact shadow")
			check(room.spell.target==room.seal_point,"Beam endpoint never drifts")
			check(room.actor.position==room.grid_to_local(room.hero_grid),"Planted root")
		for part in room._open:
			var id: String = part.get_meta("prepared_id")
			check(expected_open.has(id) and room.DEFINITION.textures.get(id)==part.texture,"Open masonry from production atlas: "+id)
			expected_open.erase(id)
		check(expected_open.is_empty(),"Open portal retains both jambs and the crown")
	for speed in [0,1,3]:
		p.set_repeat_enabled(false)
		p.set_speed_index(speed)
		p.trigger_action()
		p._process((p.channel_time-.001)/p.playback_speed)
		check(p.cast_count==0 and p.unlock_count==0,"No premature events")
		for room in p.rooms: check(not room.spell.channel and not room.opened,"Closed until channel")
		p._process(.001/p.playback_speed)
		check(p.cast_count==1 and p.unlock_count==0,"Channel starts once")
		for room in p.rooms: check(room.spell.channel and not room.opened,"Continuous beam, door still locked")
		p._process(.4/p.playback_speed)
		p.set_playing(false)
		var old_time: float = p.action_time
		var old_spell: float = p.rooms[0].spell.seconds
		p._process(1)
		check(p.action_time==old_time and p.rooms[0].spell.seconds==old_spell,"Pause freezes pose and spell")
		p.set_playing(true)
		p._process((p.unlock_time-old_time-.001)/p.playback_speed)
		check(p.unlock_count==0,"No release before ritual ends")
		p._process(.001/p.playback_speed)
		check(p.unlock_count==1,"Unseal exactly at1500ms")
		for room in p.rooms:
			check(room.opened and not room.spell.channel,"Beam ends with leaf release")
			for part in room._closed: check(not part.visible,"Closed leaf hidden")
			for part in room._open: check(part.visible,"Open arch retained")
		p._process(2)
		check(p.cast_count==1 and p.unlock_count==1 and not p.active,"Exactly one spell and release")
		for room in p.rooms: check(room.actor.frame==11,"Returns to rest")
	p.set_speed_index(3)
	p.trigger_action()
	p._process(1)
	check(p.cast_count == 1 and p.unlock_count == 1,"Large x2 tick cannot skip either event")
	p.set_playing(false)
	p.seek_action(.8)
	p.seek_action(.2)
	p.seek_action(1.0)
	check(p.cast_count == 1 and p.unlock_count == 1,"Manual seeking never emits opening events")
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
	check(p.trigger_count == count+1 and p.cast_count == 0 and p.unlock_count == 0,"Repeat resets events")
	p.set_repeat_enabled(false)
	p.set_playing(false)
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size = size
		await settle()
		for index in 12:
			p.seek_action(p._starts[index])
			for room in p.rooms:
				var actor: AnimatedSprite2D = room.actor
				var ink: Rect2i = actor.sprite_frames.get_frame_texture(actor.animation,index).get_image().get_used_rect()
				var tl := actor.to_global(actor.offset+Vector2(ink.position))
				var br := actor.to_global(actor.offset+Vector2(ink.end))
				var panel: Control = room.get_parent().get_parent()
				check(panel.get_global_rect().grow(1).encloses(Rect2(tl,br-tl)),"Hero fits stage")
		for time in [.25,.65,1.4,1.6]:
			p.seek_action(time)
			await settle()
			for room in p.rooms:
				var panel: Control = room.get_parent().get_parent()
				var bounds: Rect2 = room.get_content_rect()
				var tl: Vector2 = room.to_global(bounds.position)
				var br: Vector2 = room.to_global(bounds.end)
				check(panel.get_global_rect().grow(1).encloses(Rect2(tl,br-tl)),"Door, actor and spell fit stage")
			for button in p.find_children("*","BaseButton",true,false):
				check(p.get_global_rect().encloses(button.get_global_rect()),"Controls fit")
				check(button.size.y >= 48,"Touch control height")
			check(root.get_texture().get_image().save_png("%sshot-%dx%d-%d.png" % [OUT,size.x,size.y,int(time*1000)]) == OK,"Capture")
	root.size = Vector2i(1280,720)
	for i in 49:
		p.seek_action(minf(i*.04,p.action_duration))
		await settle()
		root.get_texture().get_image().save_png(OUT+"motion-%02d.png"%i)
	p.queue_free()
	await process_frame
	finish()
