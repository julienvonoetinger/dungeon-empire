extends SceneTree
const OUT := "res://artifacts/mycean-unlock/spell/"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); printerr(message)
func settle() -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
func update(spell: Node2D, t: float) -> void:
	spell.seconds = t
	spell.channel = t>=.45 and t<1.5
	spell.charge = clampf((t-.2)/.25,0,1) if t<1.5 else maxf(0,1-(t-1.5)/.1)
	spell.release = clampf((t-1.5)/.2,0,1) if t>=1.5 and t<1.7 else 0.0
	spell.releasing = t>=1.5 and t<1.7
	if spell.has_method("refresh"): spell.refresh()
	spell.queue_redraw()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var preview = load("res://scenes/MyceanArcaneDoor.tscn").instantiate()
	root.add_child(preview)
	await settle()
	preview.set_process(false)
	preview.set_playing(false)
	var view := SubViewport.new()
	view.size = Vector2i(300,180)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var spell: Node2D = preview.rooms[0].spell.get_script().new()
	spell.origin = Vector2(45,90)
	spell.target = Vector2(245,90)
	view.add_child(spell)
	update(spell,.9)
	await settle()
	var image := view.get_texture().get_image()
	image.save_png(OUT+"channel.png")
	var outside := 0
	for x in range(100,191):
		for y in range(55,126):
			if abs(y-90)>9 and image.get_pixel(x,y).a>.05: outside+=1
	check(outside>120,"Arcane flow has visible volume away from a straight laser (pixels %d)"%outside)
	await create_timer(.15).timeout
	await settle()
	check(view.get_texture().get_image().get_data()==image.get_data(),"Paused spell has no independent clock")
	update(spell,1.1)
	await settle()
	check(view.get_texture().get_image().get_data()!=image.get_data(),"Flow animates within a held casting pose")
	update(spell,.9)
	await settle()
	check(view.get_texture().get_image().get_data()==image.get_data(),"Seeking to same time exactly reproduces effect")
	# Shader-displaced geometry must still render when its unmodified unit mesh
	# is offscreen, as can happen when a stage is fitted/panned into the viewport.
	spell.position = Vector2(-350,0)
	spell.origin += Vector2(350,0)
	spell.target += Vector2(350,0)
	update(spell,.9)
	await settle()
	var moved := view.get_texture().get_image()
	var alpha_error := 0.0
	var alpha_total := 0.0
	for x in image.get_width():
		for y in image.get_height():
			alpha_total += image.get_pixel(x,y).a
			alpha_error += absf(image.get_pixel(x,y).a-moved.get_pixel(x,y).a)
	check(alpha_error/maxf(alpha_total,1)<.02,"Displaced filament remains visible after viewport translation")
	spell.position = Vector2.ZERO
	spell.origin -= Vector2(350,0)
	spell.target -= Vector2(350,0)
	for t in [.19,.35,.45,.7,1.1,1.499,1.5,1.6,1.7,1.85]:
		update(spell,t)
		await settle()
		var frame := view.get_texture().get_image()
		var used := frame.get_used_rect()
		if is_equal_approx(t,1.5):
			var seal_alpha := 0.0
			for x in range(210,281):
				for y in range(50,131): seal_alpha += frame.get_pixel(x,y).a
			check(seal_alpha>10,"Seal dissolution is visible on its very first frame")
		if t<.2 or t>=1.7: check(used.size==Vector2i.ZERO,"Spell is silent outside ritual at%s"%t)
		else:
			check(used.size.x>0,"Visible ritual at%s"%t)
			check(used.position.x>2 and used.position.y>2 and used.end.x<298 and used.end.y<178,"Effect stays within padded support")
		frame.save_png(OUT+"phase-%d.png"%int(t*1000))
	view.queue_free()
	preview.queue_free()
	await process_frame
	var f := FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"off_axis_pixels":outside},"\t"))
	print("MYCEAN_SPELL ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
