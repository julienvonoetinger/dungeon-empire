extends SceneTree
const OUT := "res://artifacts/paladin-core-attack/"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr(message)

func settle() -> void:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw

func finish() -> void:
	var f := FileAccess.open(OUT + "validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("PALADIN_CORE_ATTACK ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var file := "res://scenes/PaladinCoreAttack.tscn"
	check(ResourceLoader.exists(file),"Core attack scene exists")
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
	check(p.repeat_enabled,"Core attack repeats for inspection")
	var origins: Array[Vector2] = []
	var approach_axes := {&"se":Vector2.LEFT,&"sw":Vector2.UP,&"nw":Vector2.RIGHT,&"ne":Vector2.DOWN}
	var first_distance: float = p.rooms[0].hero_grid.length()
	for room in p.rooms:
		origins.append(room.actor.position)
		var outward: Vector2 = approach_axes[room.facing]
		check(absf(room.hero_grid.cross(outward)) < .001,"Paladin faces Core centre without lateral offset: " + str(room.facing))
		check(room.hero_grid.dot(outward) > .56,"Paladin stands on the incoming side: " + str(room.facing))
		check(absf(room.hero_grid.length()-first_distance) < .001,"Equal approach distance in all directions: " + str(room.facing))
		check(room.core_sprite.texture == room.DEFINITION.get("textures")["heart"],"Actual production core texture")
		check(room.core_sprite.scale == Vector2.ONE,"Core keeps its native scale")
		check(room.actor.scale.is_equal_approx(Vector2.ONE*.9404255319148935),"Paladin keeps approved scale")
		check(room.actor.sprite_frames == p.animation_frames,"Existing attack sprites reused")
		check(room.contact_error() < .01,"Hammer contact remains on cap surface")
		var hand_side := Vector2(outward.y,-outward.x)
		var contact: Vector2 = room.local_to_grid(room.actor.position+room.hammer_offset,.255)
		check(contact.dot(outward) >= .21 and contact.dot(outward) <= .38 and contact.dot(hand_side) >= .21 and contact.dot(hand_side) <= .38,"Impact on real near-side cap, not empty space: " + str(room.facing))
		var effects := 0
		for child in room._world.get_children():
			if child.get_meta("self_light",false): effects += 1
		check(effects == 2,"Core retains self shadow and glow")
		check(room._vortex_animator.materials.size() == 1,"Core retains vortex shader")
		var hero_bounds: Rect2 = room.footprint()
		check(not hero_bounds.intersects(Rect2(-.40625,-.40625,.8125,.8125)),"Feet outside pedestal")
		var hero_behind: bool = room.facing in [&"se",&"sw"]
		check((room.actor.get_index() < room.core_sprite.get_index()) == hero_behind,"Depth order " + str(room.facing))
	for speed in [0,1,3]:
		p.set_repeat_enabled(false)
		p.set_speed_index(speed)
		p.trigger_action()
		p._process(.46 / p.playback_speed)
		check(p.impact_count == 1 and p.actors[0].frame == 5,"Impact at each speed")
		p.set_playing(false)
		var phases: Array[float] = []
		for room in p.rooms: phases.append(room._vortex_animator.phase)
		await create_timer(.08).timeout
		p._process(1)
		for i in 4:
			check(p.rooms[i]._vortex_animator.phase == phases[i],"Pause freezes vortex")
		p.set_playing(true)
		p._process(2)
		check(not p.active and p.impact_count == 1,"One impact per attack")
		for i in 4: check(p.rooms[i].actor.position == origins[i],"Actor remains planted")
	p.set_speed_index(1)
	p.set_playing(false)
	p.set_ghost_core(true)
	p.seek_action(.45)
	await settle()
	for room in p.rooms:
		check(is_equal_approx(room.core_sprite.self_modulate.a,.28),"Ghost core keeps contact visible")
	root.get_texture().get_image().save_png(OUT+"ghost-contact.png")
	p.set_ghost_core(false)
	for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(720,960)]:
		root.size = size
		for time in [.31,.45,.51]:
			p.seek_action(time)
			await settle()
			for room in p.rooms:
				check(room.contact_error() < .01,"Contact stable after resize")
				var group: Node2D = room.get_parent()
				var panel: Control = group.get_parent()
				var bounds: Rect2 = room.get_content_rect()
				var tl: Vector2 = room.get_global_transform() * bounds.position
				var br: Vector2 = room.get_global_transform() * bounds.end
				check(panel.get_global_rect().grow(1).encloses(Rect2(tl,br-tl)),"World fits stage")
			for button in p.find_children("*","BaseButton",true,false):
				check(p.get_global_rect().encloses(button.get_global_rect()),"Controls fit")
			check(root.get_texture().get_image().save_png("%score-%dx%d-%d.png" % [OUT,size.x,size.y,int(time*1000)]) == OK,"Capture")
	root.size = Vector2i(1280,720)
	for i in 10:
		p.seek_action(p._starts[i])
		await settle()
		root.get_texture().get_image().save_png(OUT+"frame-%02d.png" % i)
	p.queue_free()
	await process_frame
	finish()
