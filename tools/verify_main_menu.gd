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
	check(game is IsometricGameSession and not game.sim._has_core() and not game.get_node("HUD").shade.visible,"New game goes directly to Core placement")
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
	check(not game.sim._has_core() and not game.get_node("HUD").shade.visible and game.progression.xp==60,"Confirmed replacement keeps Core XP and allows placement")
	check(not GameplaySave.read_save(slot).is_empty() and FileAccess.get_sha256(slot)!=original,"New dungeon persisted")
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
