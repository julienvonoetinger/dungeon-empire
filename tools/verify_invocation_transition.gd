extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	TranslationServer.set_locale("fr")
	DirAccess.make_dir_recursive_absolute("res://artifacts/sanctuary-procession")
	var game=load("res://scenes/game/DungeonGame.tscn").instantiate()
	game.persistence_enabled=false
	root.add_child(game)
	game.restart(false,true)
	game.set_process(false)
	var intro=game.get_node("Introduction")
	intro.set_process(false)
	for extent in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		game.restart(false,true)
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
		var arrival: float = intro.ARTISAN_START
		for moment in [11.,19.,arrival-1.,arrival+1.,arrival+3.,arrival+5.,arrival+14.9]:
			intro.elapsed = moment
			intro._walk_in(moment/intro.ENTRY_DURATION)
			if moment < intro.ARTISAN_START:
				check(intro.dialogue.visible and intro.dialogue.speaker.text == "L’invocateur","Invoker addresses the awake Core")
				check(intro.artisans.is_empty(), "Artisans wait for their introduction")
			else:
				var count := 0
				for artisan in intro.artisans:
					if artisan.visible:
						var role: String = ["mineur","menuisier","scientifique"][count]
						check(artisan.sprite_frames.resource_path.contains("oculin-"+role+"-walk"),"Arrival order: "+role)
						count += 1
				check(count == (1 if moment==arrival+1. else 2 if moment==arrival+3. else 3),"Artisans enter one after another")
			if moment==arrival+5. or moment==arrival+14.9:
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/sanctuary-procession/artisans-%d-%d.png" % [extent.x,roundi(moment)])
		var artisan_positions := []
		for artisan in intro.artisans:
			artisan_positions.append(artisan.position)
			check(artisan.animation == &"ne" and artisan.frame == 0,"Artisans face the same way at rest")
		check((artisan_positions[1]-artisan_positions[0]).is_equal_approx(artisan_positions[2]-artisan_positions[1]),"Artisans form an evenly spaced rank")
		intro._walk_in(11./intro.ENTRY_DURATION)
		for artisan in intro.artisans: check(not artisan.visible,"Seeking back hides the artisan")
		intro._process(intro.ENTRY_DURATION-intro.elapsed)
		intro.set_process(false)
		check(game.sim.lesson==GameTypes.Lesson.INVOKER_OFFER and intro.dialogue.speaker.text=="L’invocateur","The invoker offers the villagers' gold first")
		intro._skip()
		game.place_village_bag(Vector2i(6,8))
		game.place_village_bag(Vector2i(9,8))
		check(intro.shot==intro.Shot.ARTISAN and intro.dialogue.speaker.text=="Le mineur","Miner addresses the assembled artisans")
		intro._process(intro.ARTISAN_OFFER_DURATION+.75)
		check(intro.level_up.visible and game.progression.level()==1,"Promotion announces level one")
		check(intro.artisans.size()==3 and game.get_node("HUD").dig_targets.blocks.is_empty(),"Free-build rock volumes cannot reorder the assembled artisans during the promotion")
		intro._process(intro.ARTISAN_BEAT_DURATION-intro.elapsed)
		intro.set_process(false)
		check(intro.shot==intro.Shot.LESSON,"Miner's offer leads to the playable lesson")
		check(intro.dungeon_master==null and intro.arrival_light==null,"Arrival sprites cleaned up")
		check(intro.film.master_view.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Master renderer released")
		check(intro.invoker.sprite.texture.resource_path.contains("invoker-follow/se-idle"),"Tutorial invoker faces the Core")
		check(intro.invoker.position.is_equal_approx(invoker_position),"Invoker stays in place at lesson handoff")
		for i in intro.artisans.size():
			check(intro.artisans[i].visible and intro.artisans[i].position.is_equal_approx(artisan_positions[i]),"Artisan holds place into lesson")
		check(intro.view.core_awakening==1.,"Normal gameplay restores the active Core")
		check(intro.view._vortex_animator.manual_time<0.,"Gameplay restores normal Core animation")
	for state in [intro.Shot.RITUAL,intro.Shot.ENTRANCE]:
		intro._set_shot(state)
		intro.set_process(false)
		intro._skip()
		intro.set_process(false)
		check(intro.shot==intro.Shot.LESSON and intro.dungeon_master==null,"Skip cleans up either scene")
	# The previous save format started with the door, then the alcove and chest.
	var legacy := GameplaySave.capture(game.sim, game.raid, game.progression)
	legacy.erase("floor_gold")
	legacy.gold = GameTypes.START_GOLD
	legacy.lesson = GameTypes.Lesson.DOOR
	legacy.progression = {"xp":60,"last_raid_id":0}
	check(GameplaySave.apply(legacy,game.sim,game.raid,game.progression) and game.progression.level()==2 and game.sim.gold==320 and game.sim.floor_gold.is_empty(),"Existing save retains its level and funds without a second gift")
	game.selected = GameTypes.FIRST_DOOR
	game.confirm_action(GameTypes.Tool.BUILD_DOOR)
	check(game.sim.lesson==GameTypes.Lesson.ALCOVE,"Legacy door still leads to the unexcavated rock")
	game.selected = GameTypes.FIRST_ALCOVE
	game.confirm_action(GameTypes.Tool.DIG)
	check(game.sim.lesson==GameTypes.Lesson.MEET_CARPENTER,"Legacy excavation introduces the carpenter")
	game.learn_from_artisan(GameTypes.Lesson.MEET_CARPENTER)
	check(game.sim.lesson==GameTypes.Lesson.MEET_SCIENTIST and game.progression.xp==60,"Existing door is recognised without an extra charge or XP grant")
	check(not game.persistence_enabled,"Preview cannot access player saves")
	game.queue_free()
	await process_frame
	var preview=load("res://scenes/previews/SanctuaryTransition.tscn").instantiate()
	root.add_child(preview)
	preview.paused=true
	for extent in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		root.size=extent
		await process_frame
		for moment in [31.6,preview.intro.Film.DURATION-.4,preview.intro.Film.DURATION+3.1]:
			preview.clock=moment
			preview.present(moment)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			check(preview.timeline.size.x>80.,"Preview timeline remains usable")
			root.get_texture().get_image().save_png("res://artifacts/sanctuary-procession/preview-transition-%d-%04d.png" % [extent.x,roundi(moment*100)])
		var mineral_beat: float = preview.duration-preview.intro.ARTISAN_BEAT_DURATION
		preview.present(mineral_beat-1.)
		check(preview.game.sim.gold==50 and preview.game.sim.lesson==GameTypes.Lesson.VILLAGE_GIFT and preview.game.progression.level()==0,"Preview shows the first bag before the miner")
		preview.present(mineral_beat + .5)
		check(preview.intro.dialogue.speaker.text=="Le mineur" and preview.game.progression.level()==0,"Preview restores the level-zero offer")
		preview.present(mineral_beat+preview.intro.ARTISAN_OFFER_DURATION+1.)
		await process_frame
		await RenderingServer.frame_post_draw
		check(preview.intro.level_up.visible and preview.game.progression.level()==1 and not preview.intro.panel.visible,"Preview separates promotion from digging")
		check(preview.intro.level_up.origin.distance_to(preview.intro._core_on_screen()) < 1.,"Halo is anchored to the Core after resizing")
		var held: float = preview.intro.level_up.progress
		await process_frame
		check(preview.intro.level_up.progress==held,"Pausing the preview holds the level-up animation")
		preview.present(mineral_beat+.5)
		check(not preview.intro.level_up.visible and preview.game.progression.level()==0,"Seeking back clears the promotion")
	preview.present(preview.duration)
	var final_phase: float=preview.intro.view._vortex_animator.phase
	await process_frame
	await process_frame
	check(preview.intro.view._vortex_animator.phase==final_phase,"Completed preview remains paused")
	preview.present(24.)
	check(preview.intro.view.core_awakening==0. and preview.intro.dungeon_master==null,"Preview replay clears dungeon arrival")
	print("DUNGEON_HANDOFF_CHECK: failures=",failures)
	quit(0 if failures==0 else 1)
