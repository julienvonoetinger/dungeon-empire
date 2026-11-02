extends SceneTree
const OUT := "res://artifacts/mycean-attack/spores/"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); printerr(message)
func settle() -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var view := SubViewport.new()
	view.size = Vector2i(420,220)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var effect = load("res://scripts/mycean_spore_burst.gd").new()
	effect.origin = Vector2(70,110)
	effect.target = Vector2(340,110)
	view.add_child(effect)
	for kind in 3:
		effect.kind = kind
		effect.seconds = .8
		effect.progress = [.9,.5,.35][kind]
		effect.refresh()
		await settle()
		var frame: Image = view.get_texture().get_image()
		frame.save_png(OUT+"kind-%d.png"%kind)
		var used := frame.get_used_rect()
		check(used.size.x>10 and used.size.y>10,"Visible phase %d"%kind)
		check(used.position.x>0 and used.position.y>0 and used.end.x<420 and used.end.y<220,"Phase fits support")
		await create_timer(.12).timeout
		await settle()
		check(view.get_texture().get_image().get_data()==frame.get_data(),"No independent clock")
		effect.seconds = .88
		effect.refresh()
		await settle()
		check(view.get_texture().get_image().get_data()!=frame.get_data(),"Surface flow moves at same pose")
		effect.seconds = .8
		effect.refresh()
		await settle()
		check(view.get_texture().get_image().get_data()==frame.get_data(),"Same time restores exact effect")
		if kind == 1:
			var upstream := frame.get_region(Rect2i(40,60,70,100))
			check(upstream.get_used_rect().size == Vector2i.ZERO,"Projectile detached: no beam left at caster")
			var core := frame.get_pixelv(Vector2i(effect.position))
			check(core.r>.8 and core.g>.8 and core.a>.7,"Orb has a luminous opaque nucleus")
	view.queue_free()
	await process_frame
	var f := FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("MYCEAN_SPORES ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
