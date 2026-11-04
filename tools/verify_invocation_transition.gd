extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/sanctuary-procession")
	var game=load("res://scenes/game/DungeonGame.tscn").instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.restart(false,true)
	game.set_process(false)
	var intro=game.get_node("Introduction")
	intro.set_process(false)
	for extent in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		root.size=extent
		await process_frame
		intro._set_shot(intro.Shot.RITUAL)
		intro.set_process(false)
		intro.elapsed=intro.Film.DURATION-.01
		intro._process(.02)
		intro.set_process(false)
		check(intro.shot==intro.Shot.ENTRANCE,"Ritual hands off to dungeon")
		check(intro.veil.color.a>.99,"Environment cut is covered")
		check(intro.dungeon_master.texture==intro.film.master_view.get_texture(),"Same master model crosses into the dungeon")
		check(intro.view.core_awakening==0.,"Only the pedestal is present on arrival")
		check(intro.dungeon_master.z_index==1,"Master shares architecture's physical sorting layer")
		for moment in [0.,1.,3.,5.5,6.5,7.8,8.8]:
			intro.elapsed=moment
			intro._walk_in(moment/intro.ENTRY_DURATION)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			check(intro.film.master_view.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"Master viewport renders inside dungeon")
			if moment<=6.5: check(intro.view.core_awakening==0.,"Sphere waits until master reaches the Core")
			var hearts := 0
			for child in intro.view._world.find_children("*","Sprite2D",true,false):
				if str(child.get_meta("prepared_id",""))=="heart":
					hearts+=1
					check(child.material.get_shader_parameter("awakening")==intro.view.core_awakening,"Actual nested Core material follows awakening")
			check(hearts==1,"Exactly one Core sprite is controlled")
			if moment==8.8: check(intro.view.core_awakening==1.,"Sphere fully awakens after arrival")
			root.get_texture().get_image().save_png("res://artifacts/sanctuary-procession/dungeon-%d-%04d.png" % [extent.x,roundi(moment*100)])
		var invoker_position: Vector2=intro.invoker.position
		intro._walk_in(3./intro.ENTRY_DURATION)
		check(intro.invoker.modulate.a==1. and intro.invoker_at.x<intro._invoker_destination().x and intro.view.core_awakening==0.,"Backward seek restores following invoker and dormant Core")
		var rotation: Vector3=intro.film.master.rotation
		var pose_time: float=intro.film.master.clock
		intro.film._fit()
		check(intro.film.master.rotation==rotation and intro.film.master.clock==pose_time and intro.film.master_view.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"Paused resize preserves shared master presentation")
		intro._walk_in(8.8/intro.ENTRY_DURATION)
		var phase: float=intro.view._vortex_animator.phase
		await process_frame
		await process_frame
		check(intro.view._vortex_animator.phase==phase,"Core clock stays still between presentation calls")
		intro._walk_in(7.8/intro.ENTRY_DURATION)
		intro._walk_in(8.8/intro.ENTRY_DURATION)
		check(intro.view._vortex_animator.phase==phase,"Seeking restores Core phase")
		var time: float=intro.elapsed
		game.paused=true
		intro._process(.5)
		check(intro.elapsed==time,"Paused entrance does not advance")
		game.paused=false
		intro._process(2.)
		intro.set_process(false)
		check(intro.shot==intro.Shot.LESSON,"Entrance reaches playable lesson")
		check(intro.dungeon_master==null and intro.arrival_light==null,"Arrival sprites cleaned up")
		check(intro.film.master_view.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Master renderer released")
		check(intro.invoker.sprite.texture.resource_path.contains("invoker-follow/se-idle"),"Tutorial invoker faces the Core")
		check(intro.invoker.position.is_equal_approx(invoker_position),"Invoker stays in place at lesson handoff")
		check(intro.view.core_awakening==1.,"Normal gameplay restores the active Core")
		check(intro.view._vortex_animator.manual_time<0.,"Gameplay restores normal Core animation")
	for state in [intro.Shot.RITUAL,intro.Shot.ENTRANCE]:
		intro._set_shot(state)
		intro.set_process(false)
		intro._skip()
		intro.set_process(false)
		check(intro.shot==intro.Shot.LESSON and intro.dungeon_master==null,"Skip cleans up either scene")
	check(not game.persistence_enabled,"Preview cannot access player saves")
	game.queue_free()
	await process_frame
	var preview=load("res://scenes/previews/SanctuaryTransition.tscn").instantiate()
	root.add_child(preview)
	preview.paused=true
	for extent in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		root.size=extent
		await process_frame
		for moment in [30.,40.,43.5]:
			preview.clock=moment
			preview.present(moment)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			check(preview.timeline.size.x>80.,"Preview timeline remains usable")
			root.get_texture().get_image().save_png("res://artifacts/sanctuary-procession/preview-transition-%d-%04d.png" % [extent.x,roundi(moment*100)])
	preview.present(preview.duration)
	var final_phase: float=preview.intro.view._vortex_animator.phase
	await process_frame
	await process_frame
	check(preview.intro.view._vortex_animator.phase==final_phase,"Completed preview remains paused")
	preview.present(24.)
	check(preview.intro.view.core_awakening==0. and preview.intro.dungeon_master==null,"Preview replay clears dungeon arrival")
	print("DUNGEON_HANDOFF_CHECK: failures=",failures)
	quit(0 if failures==0 else 1)
