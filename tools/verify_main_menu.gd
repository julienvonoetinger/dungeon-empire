extends SceneTree

const Menu = preload("res://scenes/game/MainMenu.tscn")
const OUT := "res://artifacts/main-menu/"
var slot := OUT+"test-%d.save" % Time.get_ticks_usec()
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func open_menu():
	var menu = Menu.instantiate()
	menu.save_path = slot
	change_scene_to_node(menu)
	await scene_changed
	return menu

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+label+".png")==OK,"Capture "+label)

func check_lesson_dialogue(intro, phrase: String, speaker := "L’invocateur") -> void:
	var speech = intro.get("reading_dialogue")
	check(speech != null and speech.is_visible_in_tree() and speech.speaker.text == speaker and speech.words.text.contains(phrase), "The correct artisan speaks the current lesson")

func touch_cube(at: Vector2, down: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = at
	touch.pressed = down
	root.push_input(touch,true)

func tap_site(intro, cell: Vector2i) -> void:
	await process_frame
	await process_frame
	var index: int = intro.placement_sites.find(cell)
	check(index >= 0, "Chosen floor cell is offered")
	if index < 0: return
	var button = intro.site_buttons.get_child(index)
	var at: Vector2 = button.get_global_rect().get_center() + button.icon_offset * intro.camera.zoom
	check(button._has_point(button.get_global_transform_with_canvas().affine_inverse()*at),"The displayed icon is on reachable floor")
	touch_cube(at,true)
	await process_frame
	touch_cube(at,false)
	await process_frame

func check_placement_layout(intro, label: String) -> void:
	for extent in [Vector2i(960,540),Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("%s-%dx%d"%[label,extent.x,extent.y])
		check(not intro.target.visible and not intro.action.visible and not intro.placement_sites.is_empty(),"Player picks a build site in the dungeon")
		for i in intro.placement_sites.size():
			var button: BaseButton = intro.site_buttons.get_child(i)
			var bounds := button.get_global_rect()
			check(intro.root.get_rect().grow(1).encloses(bounds) and not bounds.intersects(intro.panel.get_global_rect()),"Placement tile clears the instructions")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	check(ProjectSettings.get_setting("application/run/main_scene")==Menu.resource_path,"Project launches the title menu")
	var menu = await open_menu()
	check(not FileAccess.file_exists(slot) and menu.primary.text=="Nouvelle partie" and not menu.secondary.visible,"First launch offers a new game without writing a save")
	await capture("first-launch")
	menu.primary.pressed.emit()
	await scene_changed
	var game = current_scene
	check(game is IsometricGameSession and game.sim._core_origin()==Vector2i(8,8) and game.phase()=="Preparation" and not game.get_node("HUD").shade.visible,"New game opens in preparation with the Core at the centre")
	check(game.sim.gold==0 and not game.can_undo() and not game.ready_for_raid(),"The newly summoned Master awaits the villagers' gold")
	for y in range(7,10):
		for x in range(7,10):
			if Vector2i(x,y)!=Vector2i(8,8): check(game.sim.grid[y][x]==GameTypes.Tile.FLOOR,"Open passage around starting Core")
	check(game.sim._find_tile(GameTypes.Tile.ENTRANCE)==Vector2i(3,8),"New game contains the tutorial stair")
	check(game.has_node("Introduction"),"New game includes the Oculin introduction")
	var intro = game.get_node("Introduction")
	check(intro.shot==intro.Shot.PROLOGUE and intro.visible,"New game opens the illustrated story")
	check(game.progression.level()==0 and not game.can_edit() and not game.progression.allows(GameTypes.Tool.DIG),"New Master has no actions before the miner")
	root.size = Vector2i(390,844)
	for i in 8: intro._process(.1)
	await capture("prologue-village-portrait")
	var story_scenes := ["basalt","lookout","audience","envoy","decree","assault","pass","occupation","council","oath"]
	for index in story_scenes.size():
		check(intro.shot==intro.Shot.PROLOGUE,"Story includes chapter %d" % (index+1))
		if intro.shot != intro.Shot.PROLOGUE: break
		var scene_name: String = story_scenes[index]
		for extent in [Vector2i(1024,680),Vector2i(390,844),Vector2i(568,320)]:
			root.size = extent
			for i in 80: intro._process(.1)
			await capture("prologue-%d-%dx%d" % [index+1,extent.x,extent.y])
			var image_variant := "-portrait" if extent.y > extent.x or extent.y <= 320 else ""
			var expected_art := "res://assets/game/introduction/prologue-%s%s.webp" % [scene_name,image_variant]
			check(intro.page==index and intro.story.texture.resource_path==expected_art and not intro.line.text.is_empty(),"Page waits for the reader with matching art and text")
			check(intro.reading_area.scroll_vertical==0,"Each chapter starts at its first line")
			var speech = intro.get("reading_dialogue")
			if index in [3,8,9]:
				check(speech != null and speech.is_visible_in_tree(), "Spoken prologue passage has a portrait")
				if speech != null:
					check(speech.speaker.text == ("Les anciens" if index == 3 else "L’invocateur"), "Prologue speaker is identified")
					check(speech.portrait.texture.resource_path.ends_with("/elders.webp" if index == 3 else "/invoker.webp"), "Prologue uses the speaker's portrait")
					check(not intro.line.text.contains(speech.words.text), "Narration does not repeat the quote")
			elif speech != null:
				check(not speech.is_visible_in_tree(), "Pure narration has no portrait")
			if extent.y <= 320:
				check(not intro.story.get_global_rect().intersects(intro.panel.get_global_rect()),"Short landscape keeps the prayer visible beside the text")
			check(intro.root.get_rect().encloses(intro.panel.get_global_rect()) and not intro.panel.get_global_rect().intersects(intro.skip.get_global_rect()),"Story controls fit "+str(extent))
			var pixels_per_unit: float = intro.line.get_global_transform().get_scale().y * extent.x / intro.root.size.x
			check(intro.line.get_theme_font_size("font_size") * pixels_per_unit >= 17.9,"Story body is readable at "+str(extent))
			for button in [intro.action,intro.skip]:
				check(button.get_theme_font_size("font_size") * pixels_per_unit >= 15.9,"Story button is readable at "+str(extent))
			if extent.y > extent.x:
				var phone_pixels := Vector2(extent) * 3
				var safe_pixels := Rect2(0,90,phone_pixels.x,phone_pixels.y-150)
				intro._fit_controls(phone_pixels,safe_pixels,3.)
				var to_pixels: float = phone_pixels.x / intro.root.size.x
				var panel_rect: Rect2 = intro.panel.get_global_rect()
				check(intro.line.get_theme_font_size("font_size") * intro.panel.scale.y * to_pixels >= 59.9,"High-density phone renders 20 logical pixels per story character")
				check(safe_pixels.encloses(Rect2(panel_rect.position*to_pixels,panel_rect.size*to_pixels)),"Phone dialogue stays inside safe insets")
				intro._layout()
			if extent.y <= 320:
				intro.reading_area.scroll_vertical = ceili(intro.reading_column.size.y)
				await process_frame
				check(intro.reading_column.get_global_rect().end.y <= intro.reading_area.get_global_rect().end.y+2,"Last line can be read "+scene_name)
		intro.action.pressed.emit()
	root.size = Vector2i(1024,680)
	await process_frame
	check(intro.shot==intro.Shot.RITUAL and not intro.story.visible and intro.story.texture==null,"Answering the call enters the ritual and releases the story image")
	check(intro.film.master.player.has_animation(intro.film.master.clip) and not intro.film.master.model.find_children("*","Skeleton3D",true,false).is_empty(),"Manifestation uses the animated Wraith skeleton")
	check(intro.find_children("*","AudioStreamPlayer",true,false).is_empty(),"Written dialogue adds no voice playback")
	check(not intro.panel.visible and not intro.target.visible,"Ritual begins without the lesson controls")
	root.size = Vector2i(390,844)
	intro.set_process(false)
	for moment in [1., 10., 16., 21., 24., 28., 32., 38.]:
		intro._process(moment-intro.elapsed)
		check(is_equal_approx(intro.film.seconds,moment),"Scene follows the ritual clock")
		check(intro.film.actors.size()==5 and intro.film.visible,"Live procession remains present through the ritual")
		await capture("invocation-iso-%02d" % int(moment))
		if moment == 16.:
			var held: float = intro.elapsed
			game.set_paused(true)
			intro._process(.5)
			check(intro.elapsed == held and not intro.visible,"Pausing holds the ritual")
			game.set_paused(false)
			root.size = Vector2i(820,360)
			await capture("invocation-iso-gaze-landscape")
			root.size = Vector2i(390,844)
	intro._process(intro.film.DURATION-intro.elapsed)
	check(intro.shot==intro.Shot.ENTRANCE and not intro.panel.visible,"Camera opens on the entrance before the lesson")
	var guide = intro.invoker
	var stair_position: Vector2 = guide.position
	intro.set_process(false)
	intro._process(4.)
	check(guide.position.distance_to(stair_position)>1. and guide.modulate.a==1.,"Invoker walks from the stair into the passage")
	await capture("invoker-entering")
	intro._process(intro.ENTRY_DURATION-intro.elapsed)
	check(intro.invoker==guide and intro.shot==intro.Shot.GIFT and game.progression.level()==0,"The assembled villagers offer their gold before the first promotion")
	check(intro.dialogue.speaker.text=="L’invocateur" and intro.dialogue.words.text.contains("tout leur or"),"The invoker presents the villagers' donation")
	root.size = Vector2i(960,540)
	await capture("village-offer")
	intro.skip.pressed.emit()
	check(not game.check_action(GameTypes.FIRST_ALCOVE,GameTypes.Tool.DIG).valid and not game.progression.allows(GameTypes.Tool.STORE),"Neither digging nor chests are available during the gift")
	await check_placement_layout(intro,"village-gift")
	var first_bag := Vector2i(6,8)
	var second_bag := Vector2i(9,8)
	game.place_village_bag(GameTypes.FIRST_STAIR)
	check(game.sim.gold==0,"The stair cannot hold a bag")
	await tap_site(intro,first_bag)
	check(game.sim.floor_gold=={first_bag:50} and game.sim.gold==50 and game.progression.level()==0,"First tap deposits exactly one bag without a promotion")
	game.place_village_bag(first_bag)
	game.leave_tutorial()
	check(game.sim.gold==50 and game.sim.lesson==GameTypes.Lesson.VILLAGE_GIFT and not intro.placement_sites.has(first_bag),"An occupied cell or skip cannot duplicate or bypass the gift")
	var invalid := GameplaySave.capture(game.sim,game.raid,game.progression)
	invalid.floor_gold[first_bag] = 51
	check(not GameplaySave._valid(invalid),"An overfilled bag cannot be loaded")
	invalid.floor_gold[first_bag] = 50
	invalid.gold = 0
	check(not GameplaySave._valid(invalid),"Saved bags cannot exceed spendable gold")
	root.size = Vector2i(960,540)
	await capture("village-first-bag")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	intro.set_process(false)
	check(game.sim.floor_gold=={first_bag:50} and game.progression.level()==0 and intro.title.text.contains("second"),"Continue retains the chosen cell and prompts for the second bag")
	await tap_site(intro,second_bag)
	check(game.sim.floor_gold=={first_bag:50,second_bag:50} and game.sim.gold==100 and game.progression.level()==0,"Two distinct paid-in bags precede the miner")
	game.place_village_bag(Vector2i(8,7))
	check(game.sim.gold==100 and game.sim.vault_gold.is_empty(),"The gift can only be claimed once and requires no chest")
	check(intro.artisans.size()==3 and intro.dialogue.speaker.text=="Le mineur" and intro.dialogue.words.text.contains("agrandir"),"Assembled miner offers to excavate")
	check(intro.dialogue.portrait.texture.resource_path.ends_with("/miner.webp"),"Miner uses his own portrait")
	check(not game.check_action(GameTypes.FIRST_ALCOVE,GameTypes.Tool.DIG).valid,"Level zero cannot excavate")
	await capture("miner-offer")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	intro.set_process(false)
	check(intro.shot==intro.Shot.ARTISAN and game.progression.level()==0,"A pending tutorial save resumes at the miner's offer")
	intro._process(intro.ARTISAN_OFFER_DURATION + .8 - intro.elapsed)
	check(game.progression.level()==1 and intro.level_up.visible and not intro.panel.visible,"Promotion precedes the first action")
	await capture("miner-level-up")
	intro._process(intro.ARTISAN_BEAT_DURATION-intro.elapsed)
	intro.set_process(false)
	check(intro.shot==intro.Shot.LESSON and game.sim.lesson==GameTypes.Lesson.ALCOVE,"The miner unlocks the excavation lesson")
	check(not game.check_action(GameTypes.FIRST_DOOR,GameTypes.Tool.BUILD_DOOR).valid,"First lesson only accepts the indicated excavation")
	check(game.get_node("HUD").dig_targets.blocks.size()>1 and not intro.target.visible,"Excavation lesson immediately shows the dig cubes instead of a diamond")
	var chosen := GameTypes.FIRST_DOOR + Vector2i.UP
	var finger := Vector2.INF
	for extent in [Vector2i(960,540),Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("first-lesson-%dx%d"%[extent.x,extent.y])
		var targets = game.get_node("HUD").dig_targets
		check(not intro.action.visible and not intro.target.visible and not intro.reading_area.visible,"Tap directly in the dungeon")
		var legal_count := 0
		for y in GameTypes.ROWS:
			for x in GameTypes.COLS:
				if game.sim.dig_failure_reason(Vector2i(x,y)).is_empty(): legal_count += 1
		check(targets.blocks.size() == legal_count,"Every legal excavation has a cube")
		for block in targets.blocks:
			var point: Vector2 = block.get_global_transform_with_canvas() * block.top_center
			check(block.is_visible_in_tree() and intro.root.get_rect().has_point(point) and not intro.panel.get_global_rect().has_point(point), "Purple cube is framed above the lesson hint")
			check(game.check_action(block.cell, GameTypes.Tool.DIG).valid,"Each highlighted cube can actually be excavated")
			if block.cell == chosen:
				finger = point
				check(targets.hit_cell(point / intro.hud.scale.x) == chosen, "Chosen cube accepts a map tap")
	check(finger.is_finite(), "A dig option beyond the historical alcove exists")
	if finger.is_finite():
		touch_cube(finger,true)
		await process_frame
		touch_cube(finger,false)
		await process_frame
	check(not intro.film.visible,"Sanctuary is hidden during play")
	check(game.sim.grid[chosen.y][chosen.x]==GameTypes.Tile.FLOOR and game.sim.gold==95 and game.sim.floor_gold=={first_bag:45,second_bag:50},"Excavation costs five pieces from the first bag")
	check(intro.dialogue.visible and intro.dialogue.speaker.text=="Le menuisier" and game.progression.level()==1,"The carpenter speaks before the second promotion")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	intro.set_process(false)
	check(intro.shot==intro.Shot.ARTISAN and game.progression.level()==1 and intro.dialogue.speaker.text=="Le menuisier","Continue resumes the carpenter's offer after digging")
	check(not game.progression.allows(GameTypes.Tool.BUILD_DOOR) and not game.can_edit(), "Wooden doors wait for the carpenter")
	await capture("carpenter-offer")
	intro._process(intro.ARTISAN_OFFER_DURATION+1.-intro.elapsed)
	check(intro.level_up.visible and intro.level_up.title.text=="Niveau 2" and game.progression.level()==2,"Carpenter grants the second level before building")
	await capture("carpenter-level-up")
	intro._process(intro.ARTISAN_BEAT_DURATION-intro.elapsed)
	intro.set_process(false)
	check(intro.shot==intro.Shot.LESSON and game.sim.lesson==GameTypes.Lesson.DOOR,"Door placement follows the promotion")
	check(not game.progression.allows(GameTypes.Tool.TRAP_SPIKE) and not intro.placement_sites.has(GameTypes.FIRST_DOOR),"Spikes remain locked and an unsupported door is excluded")
	await check_placement_layout(intro,"door-placements")
	await tap_site(intro,Vector2i(4,8))
	check(game.sim.grid[8][4]==GameTypes.Tile.DOOR and game.sim.gold==55 and game.sim.floor_gold=={first_bag:5,second_bag:50},"The door costs forty pieces from the bags")
	check(intro.dialogue.speaker.text=="Le scientifique" and intro.dialogue.portrait.texture.resource_path.ends_with("/scientist.webp") and game.progression.level()==2,"Scientist offers traps after the built door")
	await capture("scientist-offer")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	intro.set_process(false)
	check(game.sim.lesson==GameTypes.Lesson.MEET_SCIENTIST and not game.can_edit(),"Reload preserves the scientist's offer and the built door")
	intro._process(intro.ARTISAN_OFFER_DURATION+.85-intro.elapsed)
	check(game.progression.level()==3 and intro.level_up.title.text=="Niveau 3" and game.progression.allows(GameTypes.Tool.TRAP_SPIKE),"Scientist unlocks spikes at level three")
	await capture("scientist-level-up")
	# Reload after the promotion, before building the trap. The save must
	# start at placement and keep exactly one XP grant.
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	intro.set_process(false)
	check(intro.shot==intro.Shot.LESSON and game.sim.lesson==GameTypes.Lesson.SPIKES and game.progression.xp==150,"Level-three save resumes at spike placement")
	game.learn_from_artisan(GameTypes.Lesson.MEET_SCIENTIST)
	check(game.progression.xp==150,"The scientist's reward cannot be claimed twice")
	check(not intro.placement_sites.has(chosen) and not intro.placement_sites.has(Vector2i(4,8)),"Spikes protect a free tile, reserving the alcove and door")
	await check_placement_layout(intro,"spike-placements")
	await tap_site(intro,Vector2i(5,8))
	check(game.sim.grid[8][5]==GameTypes.Tile.SPIKE and game.sim.trap_charges.get(Vector2i(5,8))==GameTypes.TRAP_MAX_CHARGES and game.sim.gold==20 and game.sim.floor_gold=={second_bag:20},"The spike exhausts the first bag and leaves twenty in the second")
	check_lesson_dialogue(intro,"votre or")
	intro.target.pressed.emit()
	check(game.sim.grid[chosen.y][chosen.x]==GameTypes.Tile.VAULT and not intro.visible and game.get_node("HUD").visible,"Chest follows the chosen excavation across a save and reload")
	check(game.sim.gold==20 and game.sim.floor_gold.is_empty() and game.sim.vault_gold.get(chosen)==20,"The first chest secures the remaining twenty exactly once")
	game.progression.xp = 60
	game.restart(true)
	var original := FileAccess.get_sha256(slot)
	menu = await open_menu()
	check(menu.primary.text=="Continuer" and menu.secondary.visible,"Existing game gets Continue")
	for extent in [Vector2i(1280,720),Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("menu-%dx%d"%[extent.x,extent.y])
		check(menu.backdrop.get_rect().is_equal_approx(menu.get_rect()) and menu.backdrop.texture==menu.SANCTUM,"Illustration covers viewport at "+str(extent))
		check(menu.logo.texture==menu.LOGO and menu.get_rect().encloses(menu.logo.get_global_rect()) and menu.logo.get_global_rect().end.y < menu.size.y*.45 and menu.get_rect().encloses(menu.actions.get_global_rect()) and menu.actions.position.y > menu.size.y*.52,"Logo and controls leave the painted Core visible at "+str(extent))
	menu.secondary.pressed.emit()
	check(menu.confirming and menu.primary.text=="Annuler","New game asks before replacing")
	await capture("confirm")
	check(menu.get_rect().encloses(menu.actions.get_global_rect()) and menu.actions.get_global_rect().encloses(menu.secondary.get_global_rect()),"Both confirmation actions fit")
	menu.primary.pressed.emit()
	check(not menu.confirming and FileAccess.get_sha256(slot)==original,"Cancel preserves the save")
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	check(game.sim._has_core() and game.sim.gold==245 and game.progression.xp==60,"Continue restores dungeon and progression")
	menu = await open_menu()
	menu.secondary.pressed.emit()
	menu.secondary.pressed.emit()
	await scene_changed
	game = current_scene
	check(game.sim._core_origin()==Vector2i(8,8) and not game.get_node("HUD").shade.visible and game.progression.level()==0 and game.progression.xp==60,"A newly summoned Master starts at zero and retains the Core's lifetime XP")
	check(not GameplaySave.read_save(slot).is_empty() and FileAccess.get_sha256(slot)!=original,"New dungeon persisted")
	intro = game.get_node("Introduction")
	intro.skip.pressed.emit()
	check(intro.shot==intro.Shot.RITUAL,"Skipping the story leads directly to the ritual")
	intro.skip.pressed.emit()
	check(game.sim.lesson==GameTypes.Lesson.INVOKER_OFFER and game.sim.gold==0,"Skipping the ritual still requires the village gift")
	intro.skip.pressed.emit()
	game.place_village_bag(first_bag)
	game.place_village_bag(second_bag)
	intro.skip.pressed.emit()
	check(game.progression.level()==1 and game.progression.xp==60 and game.progression.next_threshold()==120 and intro.level_up.visible,"Skipping the offer grants one level without erasing lifetime XP")
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	check(not intro.visible and game.sim.lesson==GameTypes.Lesson.FREE,"Free play can be chosen before building")
	var hud = game.get_node("HUD")
	game.set_paused(true)
	hud.modal_new.pressed.emit()
	hud.modal_resume.pressed.emit()
	check(intro.shot==intro.Shot.PROLOGUE and intro.page==0 and intro.visible,"Confirmed new dungeon in the pause menu starts the story too")
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	game.place_village_bag(first_bag)
	game.place_village_bag(second_bag)
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	game.sim.new_map()
	game.sim._place_core(Vector2i(2,4))
	check(game._save(),"Store an older layout with an off-centre Core")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	check(current_scene.sim._core_origin()==Vector2i(2,4),"Continue preserves the saved Core position")
	var corrupt := FileAccess.open(slot,FileAccess.WRITE)
	corrupt.store_string("invalid")
	corrupt.close()
	menu = await open_menu()
	check(menu.primary.text=="Continuer","Backup enables Continue after primary corruption")
	DirAccess.remove_absolute(slot+".bak")
	menu = await open_menu()
	check(not menu.resumable and menu.message.visible,"Unreadable save is signalled")
	menu.primary.pressed.emit()
	check(menu.confirming and FileAccess.get_file_as_string(slot)=="invalid","Unreadable slot still requires replacement confirmation")
	DirAccess.remove_absolute(slot)
	print("%d main menu checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
