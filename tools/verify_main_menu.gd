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

func check_phone_dialogue(intro) -> void:
	var captions = intro.dialogue
	for extent: Vector2i in [Vector2i(575,1280), Vector2i(1280,575)]:
		root.size = extent
		await process_frame
		await process_frame
		var portrait := extent.y > extent.x
		var density := 1.5
		var pixels := Vector2(extent)
		var to_pixels: float = pixels.x / intro.root.size.x
		for bottom in [0,48]:
			var safe := Rect2(0,70 if portrait else 0,pixels.x,pixels.y - (70 if portrait else 0) - bottom)
			intro._fit_controls(pixels,safe,density)
			for label in [captions.speaker,captions.words]:
				var rect: Rect2 = label.get_global_rect()
				var gap := safe.end.y - rect.end.y * to_pixels
				var margin: float = gap / (intro.unit * to_pixels)
				check(absf(margin - (12. if portrait else 8.)) <= .5,"Speaker and dialogue keep a compact margin inside the safe area in %s (%.1f px)" % [extent,gap])
			check(captions.words.size.y >= captions.words.get_minimum_size().y,"All wrapped dialogue lines fit above the phone inset")
			var stone_end: Vector2 = captions.band.get_global_rect().end
			check(stone_end.distance_to(intro.root.size) * to_pixels <= 1.,"Dialogue stone reaches beneath the phone inset: %s / %s" % [stone_end,intro.root.size])
			if portrait and bottom==0:
				check(captions.words.get_line_count()>1,"The invoker's first line wraps on the reported portrait screen")
				await capture("invocation-dialogue-575x1280")
	intro._layout()

func check_practice_spike_depth(intro, phase: String, on_plate := true) -> void:
	var actor: Node2D = intro.volunteer
	var tile: Vector2i = intro.practice.contact
	var mechanism: Node2D
	for visual in intro.view._trap_visuals:
		if visual.cell != tile: continue
		if visual.layer == "floor":
			check(visual.node.z_index < actor.z_index,phase+": the paving is below the Oculin")
		elif visual.layer == "mechanism":
			mechanism = visual.node.get_parent()
	check(is_instance_valid(mechanism) and mechanism.get_parent()==actor.get_parent(),phase+": the mechanism and the Oculin share a depth layer")
	if is_instance_valid(mechanism):
		check((mechanism.get_index()<actor.get_index()) == on_plate,phase+": the Oculin covers the spikes only after stepping onto the plate")
	for part in intro.view.solid_groups:
		if str(part.get("id","")).ends_with("-panel"):
			check(actor.get_index()<part.node.get_index(),phase+": the nearer closed door can still cover the Oculin")

func check_gold_bag_rings(intro, expected: Dictionary) -> void:
	var amounts := {}
	for marker in intro.view._markers:
		if marker.kind != "village_bag": continue
		var badge = marker.node.badge
		var show_ring: bool = intro.session.sim.lesson != GameTypes.Lesson.PRACTICE_RAID
		check(badge != null and badge.is_visible_in_tree()==show_ring and not marker.node.label.visible, "Gold bags use storage rings, hidden during the practice raid")
		if not badge: continue
		check(badge.glyph == "coins" and badge.protection_tier == 0 and not badge.segmented, "Bag uses the unprotected chest's coin indicator")
		check(badge.capacity == 50 and is_equal_approx(badge.ratio, badge.amount / 50.0), "Bag ring fills relative to its own capacity")
		amounts[marker.cell] = badge.amount
	check(amounts == expected, "Visible gold bag rings match the coins left on each tile")

func check_practice_routes(snapshot: Dictionary) -> void:
	var sim := DungeonSim.new()
	var raid := RaidDirector.new()
	raid.sim = sim
	raid.solid_core = true
	check(GameplaySave.apply(snapshot,sim,raid,CoreProgression.new()),"Exercise checkpoint can be restored")
	var door := Vector2i(4,8)
	var spikes := Vector2i(5,8)
	sim.door_hp[door] = 0
	var trial := preload("res://scripts/game/tutorial_raid.gd").new(sim,raid)
	check(trial.outcome == trial.Outcome.TRAP and trial.contact == spikes,"Volunteer reaches the armed spikes behind an open door")
	sim.trap_charges[spikes] = 0
	trial = preload("res://scripts/game/tutorial_raid.gd").new(sim,raid)
	check(trial.outcome == trial.Outcome.CORE and trial.contact == GameTypes.core_origin_cell(),"Spent spikes allow the volunteer to reach the Core")
	# A detour beyond the stair mouth bypasses a newly positioned closed door.
	sim.grid[8][4] = GameTypes.Tile.FLOOR
	sim.grid[8][5] = GameTypes.Tile.DOOR
	for x in range(4,7): sim.grid[7][x] = GameTypes.Tile.FLOOR
	trial = preload("res://scripts/game/tutorial_raid.gd").new(sim,raid)
	check(trial.outcome == trial.Outcome.CORE and trial.path.get_baked_length()>6., "Volunteer follows the player's open detour around the door")

func touch_cube(at: Vector2, down: bool, finger := 0, canceled := false) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = finger
	touch.position = at
	touch.pressed = down
	touch.canceled = canceled
	root.push_input(touch,true)

func drag_finger(from: Vector2, to: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.position = to
	drag.relative = to - from
	root.push_input(drag,true)

func click_page(point: Vector2) -> void:
	for down in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		root.push_input(mouse,true)
		await process_frame

func check_band_transparency(intro) -> void:
	var backdrop := ColorRect.new()
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro.root.add_child(backdrop)
	intro.root.move_child(backdrop,intro.story_band.get_index())
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var to_pixels: Vector2 = Vector2(root.size) / intro.root.size
	var top: Vector2 = intro.story_band.get_global_rect().position * to_pixels
	var point := Vector2i(3, ceili(top.y) + 12)
	var rim := Vector2i(point.x, ceili(top.y))
	var surface: Array[Color] = []
	var edge: Array[Color] = []
	for color in [Color.BLACK, Color.WHITE]:
		backdrop.color = color
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		surface.append(frame.get_pixelv(point))
		edge.append(frame.get_pixelv(rim))
	var visible_backdrop := surface[1].r - surface[0].r
	check(visible_backdrop > .20 and visible_backdrop < .45, "Scenery shows through the painted band")
	check(absf(edge[1].r - edge[0].r) < .02, "The upper rule stays opaque")
	backdrop.free()

func tap_site(intro, cell: Vector2i, raised := false) -> void:
	await process_frame
	await process_frame
	var index: int = intro.placement_sites.find(cell)
	check(index >= 0, "Chosen floor cell is offered")
	if index < 0: return
	var button = intro.site_buttons.get_child(index)
	var at: Vector2 = intro.view.get_global_transform_with_canvas() * intro.view.grid_to_local(Vector2(cell)+Vector2(.5,.5))
	var sprite := button.get_node("SitePreview") as Sprite2D
	if raised and sprite != null:
		at = sprite.get_global_transform_with_canvas().origin
	else:
		# The near wall can cover the middle of the diamond. Tap exposed stone.
		var floor_center := at
		for offset in [Vector2.ZERO,Vector2.UP,Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN]:
			at = floor_center + offset * button.tile_size * intro.unit * .25
			var motion := InputEventMouseMotion.new()
			motion.position = at
			root.push_input(motion,true)
			if root.gui_get_hovered_control()==button: break
	check(button._has_point(button.get_global_transform_with_canvas().affine_inverse()*at),"The visible target accepts the placement tap")
	touch_cube(at,true)
	await process_frame
	touch_cube(at,false)
	await process_frame

func check_placement_layout(intro, label: String) -> void:
	if intro.session.sim.lesson in [GameTypes.Lesson.DOOR, GameTypes.Lesson.SPIKES]:
		var tool := GameTypes.Tool.BUILD_DOOR if intro.session.sim.lesson == GameTypes.Lesson.DOOR else GameTypes.Tool.TRAP_SPIKE
		var legal: Array[Vector2i] = []
		for y in GameTypes.ROWS:
			for x in GameTypes.COLS:
				var cell := Vector2i(x,y)
				if intro.session.check_action(cell,tool).valid: legal.append(cell)
		check(legal.size() > 1 and legal == intro.placement_sites, "Every legal tutorial placement is shown simultaneously for " + label)
	for extent in [Vector2i(960,540),Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("%s-%dx%d"%[label,extent.x,extent.y])
		check(not intro.action.visible and not intro.placement_sites.is_empty(),"Player picks a build site in the dungeon")
		for i in intro.placement_sites.size():
			var button: BaseButton = intro.site_buttons.get_child(i)
			var bounds := button.get_global_rect()
			check(intro.root.get_rect().grow(1).encloses(bounds) and not bounds.intersects(intro.panel.get_global_rect()),"Placement tile clears the instructions")
			var sprite := button.get_node_or_null("SitePreview") as Sprite2D
			check(sprite != null and sprite.is_visible_in_tree(), "Each %s site has a floating preview" % label)
			if sprite == null: continue
			if intro.session.sim.lesson == GameTypes.Lesson.DOOR:
				var cell: Vector2i = intro.placement_sites[i]
				var across_y: bool = intro.session.sim._is_rock_cell(cell + Vector2i.UP) and intro.session.sim._is_rock_cell(cell + Vector2i.DOWN)
				check(sprite.flip_h == across_y, "The carpenter's door preview joins the two walls at %s" % cell)
			var floor_at: Vector2 = intro.view.get_global_transform_with_canvas() * intro.view.grid_to_local(Vector2(intro.placement_sites[i])+Vector2(.5,.5))
			var sprite_rect := sprite.get_global_transform_with_canvas() * sprite.get_rect()
			check(absf(sprite_rect.get_center().x-floor_at.x)<1 and (floor_at.y-sprite_rect.end.y)/intro.unit >= 40, "Preview clears its tile in " + label)
			var motion := InputEventMouseMotion.new()
			motion.position = sprite_rect.get_center()
			root.push_input(motion,true)
			check(root.gui_get_hovered_control()==button, "The raised preview takes priority over neighbouring tiles in " + label)

func check_english_intro() -> void:
	var game: IsometricGameSession = preload("res://scenes/game/DungeonGame.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.restart(false, true)
	var intro = game.get_node("Introduction")
	check(intro.title.text.ends_with("Far from the World") and intro.line.text.begins_with("Deep in the mountains"), "English prologue opens in English")
	for chapter in intro.PROLOGUE.size():
		intro._show_page(chapter)
		check(intro.line.text == intro.PROLOGUE[chapter][1], "English chapter body %d" % (chapter + 1))
	intro.dialogue.present("ritual", 11.0)
	check(intro.dialogue.speaker.text == "The Invoker" and intro.dialogue.words.text.begins_with("Aldren has taken our lands."), "English subtitles identify the speaker")
	game.free()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	check(ProjectSettings.get_setting("application/run/main_scene")==Menu.resource_path,"Project launches the title menu")
	TranslationServer.set_locale("en")
	var menu = await open_menu()
	check(menu.primary.atr(menu.primary.text) == "New game" and menu.language_picker.selected == 0, "The English menu offers a new game")
	check_english_intro()
	TranslationServer.set_locale("fr")
	await process_frame
	check(menu.language_picker.selected == 1 and menu.language_picker.accessibility_name == "Langue", "The language selector follows the active locale")
	check(not FileAccess.file_exists(slot) and menu.primary.atr(menu.primary.text)=="Nouvelle partie" and not menu.secondary.visible,"First launch offers a new game without writing a save")
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
			var image_variant := "-portrait" if extent.y > extent.x else ""
			var expected_art := "res://assets/game/introduction/prologue-%s%s.webp" % [scene_name,image_variant]
			check(intro.page==index and intro.story.texture.resource_path==expected_art and not intro.line.text.is_empty(),"Page waits for the reader with matching art and text")
			check(intro.reading_area.scroll_vertical==0,"Each chapter starts at its first line")
			if index < story_scenes.size()-1:
				check(intro.page_turn.is_visible_in_tree() and intro.page_turn.accessibility_name=="Page suivante" and not intro.action.visible,"The strip is the next-page action")
				check(intro.page_turn.text.is_empty() and intro.page_turn.icon != null and intro.page_turn.icon.resource_path=="res://assets/ui/master/stone-menu/story-next.png","The next-page cue shows the painted arrow by itself")
				var cue: Rect2 = intro.page_turn.get_global_rect()
				check(intro.heading.get_global_rect().grow(.01).encloses(cue) and not cue.intersects(intro.reading_area.get_global_rect()),"The next-page control fits beside the chapter title: %s in %s at %s" % [cue,intro.heading.get_global_rect(),extent])
			else:
				check(not intro.page_turn.visible and intro.action.visible and intro.action.text=="Répondre à l’appel","The final choice is written out")
			var quote := intro.get("story_quote") as RichTextLabel
			check(not intro.dialogue.is_visible_in_tree(),"The prologue uses a single reading surface")
			if scene_name == "envoy":
				check(not quote.visible and not intro.after_line.visible,"The elders speak within the narration without a separate portrait or speaker label")
				check(intro.line.text.contains("\n« Ces montagnes sont notre foyer. Nous ne céderons aucune terre. Vos gens ne passeront pas. »\nLes envoyés repartirent sous leur surveillance."),"The elders’ words and the envoys’ departure remain in reading order")
			elif index in [8,9]:
				check(quote != null and quote.is_visible_in_tree(), "Dialogue is typeset in the reading column")
				if quote != null:
					var passage: Array = intro.PROLOGUE[index][4]
					var text := quote.get_parsed_text()
					check(text.contains(tr(passage[0])) and text.contains("« %s »" % tr(passage[1])), "Speaker and original words appear together in French quotation marks")
					check(quote.get_parent()==intro.reading_column and intro.after_line.text==tr(passage[2]),"The story resumes after the quotation")
					check(quote.size.y >= quote.get_content_height(),"All wrapped lines of the quote fit")
			elif quote != null:
				check(not quote.is_visible_in_tree(), "Pure narration has no quotation")
			var footer: Rect2 = intro.story_band.get_global_rect()
			check(is_zero_approx(footer.position.x) and footer.end.is_equal_approx(intro.root.size),"Prologue reaches both edges and the bottom: %s / %s" % [footer,intro.root.size])
			check(intro.story.get_global_rect().size.is_equal_approx(intro.root.size) and footer.position.y >= intro.root.size.y*.35,"Illustration has room above the prologue")
			check(intro.root.get_rect().grow(1.).encloses(intro.panel.get_global_rect()) and not intro.panel.get_global_rect().intersects(intro.skip.get_global_rect()),"Story controls fit %s: %s / %s" % [extent,intro.panel.get_global_rect(),intro.root.size])
			var pixels_per_unit: float = intro.line.get_global_transform().get_scale().y * extent.x / intro.root.size.x
			check(intro.line.get_theme_font_size("font_size") * pixels_per_unit >= 17.9,"Story body is readable at "+str(extent))
			for button in [intro.page_turn if intro.page_turn.visible else intro.action,intro.skip]:
				if button is Button and not button.text.is_empty(): check(button.get_theme_font_size("font_size") * pixels_per_unit >= 15.9,"Story button is readable at "+str(extent))
				check(button.size.y >= 48. and button.focus_mode == Control.FOCUS_ALL,"Story navigation remains touchable and keyboard focusable")
			if index == 0 and extent == Vector2i(1024,680): await check_band_transparency(intro)
			if extent.y > extent.x:
				var phone_pixels := Vector2(extent) * 3
				var safe_pixels := Rect2(18,90,phone_pixels.x-48,phone_pixels.y-150)
				intro._fit_controls(phone_pixels,safe_pixels,3.)
				var to_pixels: float = phone_pixels.x / intro.root.size.x
				var panel_rect: Rect2 = intro.panel.get_global_rect()
				check(intro.line.get_theme_font_size("font_size") * intro.panel.scale.y * to_pixels >= 59.9,"High-density phone renders 20 logical pixels per story character")
				var panel_pixels := Rect2(panel_rect.position*to_pixels,panel_rect.size*to_pixels)
				check(safe_pixels.grow(.001).encloses(panel_pixels),"Phone dialogue stays inside safe insets: %s in %s on page %d" % [panel_pixels,safe_pixels,index+1])
				check(intro.story_band.get_global_rect().end.is_equal_approx(intro.root.size),"Only the painted stone extends beneath the phone insets")
				intro._layout()
			if extent.y <= 320:
				intro.reading_area.scroll_vertical = ceili(intro.reading_column.size.y)
				await process_frame
				check(intro.reading_column.get_global_rect().end.y <= intro.reading_area.get_global_rect().end.y+2,"Last line can be read "+scene_name)
				if quote != null and quote.visible:
					var bounds := quote.get_global_rect()
					check(intro.line.get_global_rect().end.y <= bounds.position.y + 1 and bounds.end.y <= intro.after_line.get_global_rect().position.y + 1,"Scrolling keeps narration, speech and closing line in order")
		if index == 0:
			var next_button: Vector2 = intro.reading_area.get_global_rect().get_center()
			touch_cube(next_button,true)
			touch_cube(next_button,false,0,true)
			touch_cube(next_button,true)
			touch_cube(next_button+Vector2.RIGHT*15,true,1)
			touch_cube(next_button+Vector2.RIGHT*15,false,1)
			touch_cube(next_button,false)
			var outside := Vector2.ONE*4
			touch_cube(outside,true)
			touch_cube(next_button,false)
			await process_frame
			check(intro.page==0,"Canceled, two-finger and outside touches do not turn the page")
			touch_cube(next_button,true)
			await process_frame
			touch_cube(next_button,false)
			await process_frame
			check(intro.page==1,"Tap on the prologue strip advances one chapter")
		elif index in [1,8]:
			if index == 8:
				root.size = Vector2i(390,844)
				await process_frame
				await process_frame
			intro.page_turn.grab_focus()
			for down in [true,false]:
				var key := InputEventKey.new()
				key.keycode = KEY_ENTER
				key.pressed = down
				root.push_input(key,true)
				await process_frame
			var next_action = intro.action if index==8 else intro.page_turn
			check(intro.page==index+1 and next_action.has_focus(),"Enter advances one chapter and keeps focus on the story action")
			next_action.release_focus()
		elif index == 2:
			root.size = Vector2i(390,844)
			await process_frame
			await process_frame
			var cue_center: Vector2 = intro.page_turn.get_global_rect().get_center()
			touch_cube(cue_center,true)
			touch_cube(cue_center,false)
			await process_frame
			check(intro.page==3,"Tapping the next-page icon on L’audience turns exactly one page in portrait")
		elif index == 3:
			intro.reading_area.scroll_vertical = 0
			await process_frame
			var start: Vector2 = intro.reading_area.get_global_rect().get_center()
			var end: Vector2 = start - Vector2(0,32)*intro.unit
			touch_cube(start,true)
			drag_finger(start,end)
			await process_frame
			drag_finger(end,end-Vector2(0,16)*intro.unit)
			await process_frame
			touch_cube(end-Vector2(0,16)*intro.unit,false)
			check(intro.page==index,"Dragging inside a long passage never advances it")
			check(intro.reading_area.scroll_vertical>0,"Dragging the long passage scrolls the text")
			touch_cube(start,true)
			drag_finger(start,end)
			drag_finger(end,start)
			touch_cube(start,false)
			check(intro.page==index,"A drag returning to its starting point does not become a tap")
			var bar: VScrollBar = intro.reading_area.get_v_scroll_bar()
			await click_page(bar.get_global_rect().get_center())
			check(intro.page==index,"Using the scrollbar keeps the current chapter")
			await click_page(intro.heading.get_global_rect().get_center())
			check(intro.page==index+1,"Clicking the title also advances the story")
		elif index == 9:
			await click_page(intro.reading_area.get_global_rect().get_center())
			check(intro.shot==intro.Shot.PROLOGUE and intro.page==9,"The final page waits for the explicit answer")
			await click_page(intro.action.get_global_rect().get_center())
		else:
			await click_page(intro.reading_area.get_global_rect().get_center())
	root.size = Vector2i(1024,680)
	await process_frame
	check(intro.shot==intro.Shot.RITUAL and not intro.story.visible and intro.story.texture==null,"Answering the call enters the ritual and releases the story image")
	check(intro.film.master.player.has_animation(intro.film.master.clip) and not intro.film.master.model.find_children("*","Skeleton3D",true,false).is_empty(),"Manifestation uses the animated Wraith skeleton")
	check(intro.find_children("*","AudioStreamPlayer",true,false).is_empty(),"Written dialogue adds no voice playback")
	check(not intro.panel.visible,"Ritual begins without the lesson controls")
	root.size = Vector2i(390,844)
	intro.set_process(false)
	for moment in [1., 10., 16., 21., 24., 28., 32., 38.]:
		intro._process(moment-intro.elapsed)
		check(is_equal_approx(intro.film.seconds,moment),"Scene follows the ritual clock")
		check(intro.film.actors.size()==5 and intro.film.visible,"Live procession remains present through the ritual")
		await capture("invocation-iso-%02d" % int(moment))
		if moment in [10., 24.]:
			if moment==10.: await check_phone_dialogue(intro)
			root.size = Vector2i(1280,720)
			await capture("invocation-dialogue-full-width" if moment == 10. else "master-dialogue-full-width")
			var strip: Rect2 = intro.dialogue.band.get_global_rect()
			check(is_zero_approx(strip.position.x) and strip.end.is_equal_approx(intro.root.size),"The dialogue strip meets both screen edges and the bottom of the game")
			root.size = Vector2i(390,844)
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
	await tap_site(intro,first_bag,true)
	check(game.sim.floor_gold=={first_bag:50} and game.sim.gold==50 and game.progression.level()==0,"First tap deposits exactly one bag without a promotion")
	check_gold_bag_rings(intro,{first_bag:50})
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
	check(game.get_node("HUD").dig_targets.blocks.size()>1 and intro.title.text.contains("pioche"),"Excavation lesson immediately offers the floating picks")
	var chosen := Vector2i(8,6)
	var finger := Vector2.INF
	for extent in [Vector2i(960,540),Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("first-lesson-%dx%d"%[extent.x,extent.y])
		var targets = game.get_node("HUD").dig_targets
		check(not intro.action.visible and not intro.reading_area.visible,"Tap directly in the dungeon")
		var legal_count := 0
		for y in GameTypes.ROWS:
			for x in GameTypes.COLS:
				if game.sim.dig_failure_reason(Vector2i(x,y)).is_empty(): legal_count += 1
		check(targets.blocks.size() == legal_count,"Every legal excavation has a marker")
		var picks_over_scenery := 0
		for block in targets.blocks:
			var point: Vector2 = block.get_global_transform_with_canvas() * block.top_center
			check(block.is_visible_in_tree() and intro.root.get_rect().has_point(point) and not intro.panel.get_global_rect().has_point(point), "Landing ring is framed above the lesson hint")
			check(game.check_action(block.cell, GameTypes.Tool.DIG).valid,"Each marked tile can actually be excavated")
			var reachable: bool = targets.hit_cell(point / intro.hud.scale.x) == block.cell
			if not intro.view.solid_covers_point(block.top_center):
				check(reachable, "Exposed tile centre selects its own cell at %s in %s" % [block.cell,extent])
			for corner: Vector2 in block.footprint:
				if reachable: break
				var surface_point: Vector2 = block.get_global_transform_with_canvas() * block.top_center.lerp(corner,.8)
				reachable = targets.hit_cell(surface_point / intro.hud.scale.x) == block.cell
			check(reachable, "An exposed part of the ground tile selects %s in %s" % [block.cell,extent])
			var pick := block.get_node_or_null("SitePreview") as Sprite2D
			check(is_instance_valid(pick), "Each dig site has a floating pick")
			if is_instance_valid(pick):
				var pick_bounds := pick.get_global_transform_with_canvas() * pick.get_rect()
				check(pick_bounds.end.y < point.y, "Pick floats clear of its landing ring")
				check(intro.root.get_rect().encloses(pick_bounds) and not intro.skip.get_global_rect().intersects(pick_bounds) and not intro.panel.get_global_rect().intersects(pick_bounds), "The entire pick is framed clear of the lesson UI")
				var pick_point := pick_bounds.get_center()
				check(targets.hit_cell(pick_point / intro.hud.scale.x) == block.cell, "Raised pick selects its own cell at %s in %s" % [block.cell,extent])
				if intro.view.scenery_covers_point(pick.position): picks_over_scenery += 1
				if block.cell == chosen: finger = pick_point
		check(picks_over_scenery > 0, "A floating pick over solid scenery remains tappable")
	check(finger.is_finite(), "A dig option beyond the historical alcove exists")
	if finger.is_finite():
		touch_cube(finger,true)
		await process_frame
		touch_cube(finger,false)
		await process_frame
	check(not intro.film.visible,"Sanctuary is hidden during play")
	check(game.sim.grid[chosen.y][chosen.x]==GameTypes.Tile.FLOOR and game.sim.gold==95 and game.sim.floor_gold=={first_bag:45,second_bag:50},"Excavation costs five pieces from the first bag")
	check_gold_bag_rings(intro,{first_bag:45,second_bag:50})
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
	check(not game.progression.allows(GameTypes.Tool.TRAP_SPIKE) and not intro.placement_sites.has(Vector2i(7,7)),"Spikes remain locked and an unsupported door is excluded")
	await check_placement_layout(intro,"door-placements")
	await tap_site(intro,Vector2i(4,8),true)
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
	check(intro.placement_sites.has(chosen) and not intro.placement_sites.has(Vector2i(4,8)) and not intro.placement_sites.has(first_bag),"The dug tile can take spikes while the door and bags remain protected")
	await check_placement_layout(intro,"spike-placements")
	await tap_site(intro,Vector2i(5,8))
	check(game.sim.grid[8][5]==GameTypes.Tile.SPIKE and game.sim.trap_charges.get(Vector2i(5,8))==GameTypes.TRAP_MAX_CHARGES and game.sim.gold==20 and game.sim.floor_gold=={first_bag:0,second_bag:20},"The spike exhausts the first bag and leaves twenty in the second")
	check_gold_bag_rings(intro,{first_bag:0,second_bag:20})
	check(game.sim.lesson==GameTypes.Lesson.PRACTICE_RAID and intro.shot==intro.Shot.ARTISAN_EXIT and not intro.panel.visible and intro.artisans.size()==3,"Spikes immediately send the artisans home")
	var restored := DungeonSim.new()
	check(GameplaySave.apply(GameplaySave.capture(game.sim,game.raid,game.progression),restored,RaidDirector.new(),CoreProgression.new()), "Both village bags round-trip after the last paid build")
	check(restored._deposit_gold(200)==80 and restored.bag_gold_total()==100 and restored.gold==100, "Restored bags receive only their remaining capacity")
	restored._spend_gold(100)
	check(restored.gold==0 and restored.floor_gold.size()==2 and restored._storage_capacity()==100,"Empty bags remain usable storage")
	restored._deposit_gold(100)
	restored.selected_tool=GameTypes.Tool.DIG
	restored._build_at(first_bag)
	check(restored.gold==50 and restored._storage_capacity()==50 and restored._unsecured_loot_total()==50,"Removing a full bag leaves overflow as recoverable loot")
	intro.set_process(false)
	var departure_at: Vector2 = intro.artisans[2].position
	var guide_at: Vector2 = intro.invoker.position
	intro._process(5.)
	check(intro.shot==intro.Shot.ARTISAN_EXIT and intro.artisans[2].position.distance_to(departure_at)>30. and intro.invoker.position==guide_at, "Artisans walk out while the invoker stays beside the Core")
	await capture("practice-departure")
	intro._process(12.)
	check(intro.shot==intro.Shot.PRACTICE_OFFER and intro.artisans.is_empty() and intro.invoker.position==guide_at and intro.dialogue.words.text.contains("l’un des nôtres"),"The invoker calls a volunteer after all three artisans have left")
	await capture("practice-offer")
	var prepared := GameplaySave.capture(game.sim,game.raid,game.progression)
	check_practice_routes(prepared)
	var old_treasure_screen: Dictionary = prepared.duplicate(true)
	old_treasure_screen.lesson = 3 # Serialized checkpoint from 0.1.16.
	old_treasure_screen.lesson_alcove = chosen
	intro.skip.pressed.emit()
	intro.set_process(false)
	var timer: float = game.raid.raid_timer
	intro._process(.65)
	game.start_raid()
	game.advance_simulation(1.)
	check(intro.volunteer.visible and intro.volunteer.modulate.a==1. and not game.can_edit() and not game.raid.raid_active and game.raid.raid_timer==timer, "Only the Oculin moves during the exercise")
	game.set_paused(true)
	var frozen_at: Vector2 = intro.volunteer.position
	intro._process(3.)
	check(intro.volunteer.position==frozen_at,"Pause freezes the volunteer")
	game.set_paused(false)
	# Continue on a pre-update save stranded at the final treasure prompt.
	menu = await open_menu()
	check(GameplaySave.write_save(slot,old_treasure_screen),"Legacy treasure checkpoint is readable")
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	check(intro.shot==intro.Shot.ARTISAN_EXIT and GameplaySave.capture(game.sim,game.raid,game.progression)==prepared,"Continue migrates the old treasure screen to the exercise with the same balances, defences and XP")
	await process_frame
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	intro.set_process(false)
	intro._process(intro.practice.travel_time+.15)
	check(intro.practice.contact==Vector2i(4,8) and intro.practice.outcome==intro.practice.Outcome.DOOR and intro.volunteer.modulate.a==1., "The approach stops at the player's first closed door")
	await capture("practice-door")
	var stopped_at: Vector2 = intro.volunteer.position
	intro._process(intro.practice.INSPECT_TIME+.12)
	check(intro.volunteer.position.distance_to(stopped_at)>1.,"The volunteer turns back toward the stair")
	intro._process(intro.practice.duration())
	check(intro.shot==intro.Shot.PRACTICE_REPORT and intro.volunteer==null and intro.dialogue.words.text.contains("votre porte"),"The invoker reports the observed defense after the return")
	check(GameplaySave.capture(game.sim,game.raid,game.progression)==prepared and game.raid.hero.is_empty() and not game.result_open,"Exercise preserves balances, HP, charges, XP, roster and raid history")
	intro.skip.pressed.emit()
	check(not intro.visible and game.get_node("HUD").visible and game.sim.invoker_resident and intro.invoker.is_visible_in_tree(), "Free play opens with the invoker still present")
	menu = await open_menu()
	menu.primary.pressed.emit()
	await scene_changed
	game = current_scene
	intro = game.get_node("Introduction")
	check(game.sim.lesson==GameTypes.Lesson.FREE and not intro.visible and intro.invoker.is_visible_in_tree() and intro.artisans.is_empty(),"Continue keeps the invoker in free play without repeating the exercise")
	game.progression.xp = 60
	game.restart(true)
	var original := FileAccess.get_sha256(slot)
	menu = await open_menu()
	check(menu.primary.atr(menu.primary.text)=="Continuer" and menu.secondary.visible,"Existing game gets Continue")
	for extent in [Vector2i(1280,720),Vector2i(390,844),Vector2i(568,320)]:
		root.size = extent
		await capture("menu-%dx%d"%[extent.x,extent.y])
		check(menu.backdrop.get_rect().is_equal_approx(menu.get_rect()) and menu.backdrop.texture==menu.SANCTUM,"Illustration covers viewport at "+str(extent))
		check(menu.logo.texture==menu.LOGO and menu.get_rect().encloses(menu.logo.get_global_rect()) and menu.logo.get_global_rect().end.y < menu.size.y*.45 and menu.get_rect().encloses(menu.actions.get_global_rect()) and menu.actions.position.y > menu.size.y*.52,"Logo and controls leave the painted Core visible at "+str(extent))
	menu.secondary.pressed.emit()
	check(menu.confirming and menu.primary.atr(menu.primary.text)=="Annuler","New game asks before replacing")
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
	check(menu.primary.atr(menu.primary.text)=="Continuer","Backup enables Continue after primary corruption")
	DirAccess.remove_absolute(slot+".bak")
	menu = await open_menu()
	check(not menu.resumable and menu.message.visible,"Unreadable save is signalled")
	menu.primary.pressed.emit()
	check(menu.confirming and FileAccess.get_file_as_string(slot)=="invalid","Unreadable slot still requires replacement confirmation")
	DirAccess.remove_absolute(slot)
	change_scene_to_packed(preload("res://scenes/previews/OculinPracticeRaid.tscn"))
	await scene_changed
	game = current_scene.game
	intro = game.get_node("Introduction")
	check(not game.persistence_enabled and game.sim.lesson==GameTypes.Lesson.PRACTICE_RAID and intro.shot==intro.Shot.ARTISAN_EXIT and game.sim.gold==20,"F6 preview starts at departure immediately after spike placement")
	intro.skip.pressed.emit()
	intro.skip.pressed.emit()
	intro.set_process(false)
	root.size = Vector2i(960,540)
	await process_frame
	var before_spikes := GameplaySave.capture(game.sim,game.raid,game.progression)
	intro._process(intro.practice.travel_time-.85)
	check_practice_spike_depth(intro,"Behind the spikes",false)
	intro._process(.60)
	check_practice_spike_depth(intro,"Approaching across the spike plate")
	intro._process(.30)
	check_practice_spike_depth(intro,"Raised spikes")
	check(intro.view._trap_state(Vector2i(5,8),GameTypes.Tile.SPIKE)=="triggered","The volunteer visibly triggers the practice spikes")
	for marker in intro.view._markers:
		if marker.node.badge: check(not marker.node.badge.is_visible_in_tree(),"A status ring cannot hide the volunteer during the rehearsal")
	await capture("practice-spikes")
	root.size = Vector2i(390,844)
	await process_frame
	intro._process(0.)
	await capture("practice-spikes-portrait")
	intro.view._advance_trap_effects(1.)
	check_practice_spike_depth(intro,"Retracted spikes")
	root.size = Vector2i(960,540)
	await process_frame
	intro._process(0.)
	await capture("practice-spikes-retracted")
	intro._process(intro.practice.INSPECT_TIME+.20)
	check_practice_spike_depth(intro,"Leaving the plate")
	intro._process(intro.practice.duration())
	check(intro.dialogue.words.text.contains("pointes") and GameplaySave.capture(game.sim,game.raid,game.progression)==before_spikes,"Spike report costs no charges, HP, gold or XP")
	intro.skip.pressed.emit()
	game.start_raid()
	check(game.raid.raid_active and game.raid.raid_index==1 and intro.invoker.is_visible_in_tree(),"First real raid remains raid one with a resident invoker")
	print("%d main menu checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
