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
	check(game.sim.gold==GameTypes.START_GOLD and not game.can_undo() and not game.ready_for_raid(),"Starting Core is free and preparation is player-paced")
	for y in range(7,10):
		for x in range(7,10):
			if Vector2i(x,y)!=Vector2i(8,8): check(game.sim.grid[y][x]==GameTypes.Tile.FLOOR,"Open passage around starting Core")
	check(game.sim._find_tile(GameTypes.Tile.ENTRANCE)==Vector2i(3,8),"New game contains the tutorial stair")
	check(game.has_node("Introduction"),"New game includes the Oculin introduction")
	var intro = game.get_node("Introduction")
	check(intro.shot==intro.Shot.PROLOGUE and intro.visible,"New game opens the illustrated story")
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
				intro.reading_area.scroll_vertical = ceili(intro.line.size.y)
				await process_frame
				check(intro.line.get_global_rect().end.y <= intro.reading_area.get_global_rect().end.y+2,"Last line can be read "+scene_name)
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
	check(intro.invoker==guide and intro.shot==intro.Shot.LESSON and game.sim.lesson==GameTypes.Lesson.DOOR,"The arriving invoker gives the first door lesson")
	for extent in [Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("first-lesson-%dx%d"%[extent.x,extent.y])
		check(intro.root.get_rect().encloses(intro.panel.get_global_rect()) and intro.root.get_rect().encloses(intro.skip.get_global_rect()) and not intro.target.get_global_rect().intersects(intro.panel.get_global_rect()),"Lesson controls fit "+str(extent))
		var cell_on_screen: Vector2 = intro.view.get_global_transform_with_canvas() * intro.view.grid_to_local(intro.focus_cell)
		check(intro.target.get_global_rect().get_center().distance_to(cell_on_screen)<2,"Lesson button follows the indicated cell "+str(extent))
	intro.target.pressed.emit()
	check(not intro.film.visible,"Sanctuary is hidden during play")
	check(game.sim.grid[8][5]==GameTypes.Tile.DOOR and game.sim.gold==280,"Guided door uses real construction and cost")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	check(intro.shot==intro.Shot.LESSON and game.sim.lesson==GameTypes.Lesson.ALCOVE,"Continue resumes the next lesson without replaying the ritual")
	intro.action.pressed.emit()
	check(game.sim.grid[7][6]==GameTypes.Tile.FLOOR and game.sim.gold==275,"Player excavates the alcove")
	intro.target.pressed.emit()
	check(game.sim.grid[7][6]==GameTypes.Tile.VAULT and not intro.visible and game.get_node("HUD").visible,"Guided chest stays on the playable map")
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
	check(game.sim._core_origin()==Vector2i(8,8) and not game.get_node("HUD").shade.visible and game.progression.xp==60,"Confirmed replacement centres the Core and keeps its XP")
	check(not GameplaySave.read_save(slot).is_empty() and FileAccess.get_sha256(slot)!=original,"New dungeon persisted")
	intro = game.get_node("Introduction")
	intro.skip.pressed.emit()
	check(intro.shot==intro.Shot.RITUAL,"Skipping the story leads directly to the ritual")
	intro.skip.pressed.emit()
	check(intro.shot==intro.Shot.LESSON and game.sim._has_entrance(),"Skip leads directly to building on the same dungeon")
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
