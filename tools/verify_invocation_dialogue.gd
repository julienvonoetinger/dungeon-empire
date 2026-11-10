extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	TranslationServer.set_locale("fr")
	DirAccess.make_dir_recursive_absolute("res://artifacts/sanctuary-procession")
	var preview = load("res://scenes/previews/SanctuaryTransition.tscn").instantiate()
	root.add_child(preview)
	preview.paused = true
	var intro = preview.intro
	var captions = intro.dialogue
	var dungeon: float = intro.Film.DURATION
	for extent in [Vector2i(1280,720), Vector2i(390,844), Vector2i(844,390)]:
		root.size = extent
		await process_frame
		for moment in [11., 16., 23., 28., 34., 38., dungeon+2., dungeon+6., dungeon+12., dungeon+19., dungeon+25., dungeon+30., dungeon+34., dungeon+47.]:
			preview.present(moment)
			for frame in range(4): await process_frame
			check(captions.visible and not captions.words.text.is_empty(), "Dialogue shown at " + str(moment))
			if moment == dungeon + 12. or moment == dungeon + 19.:
				var subject := "éclairs du rituel" if moment == dungeon + 12. else "défenses du donjon"
				check(captions.words.text.contains(subject) and captions.speaker.text == "L’invocateur", "The invoker explains " + subject)
				check(intro.artisans.all(func(actor): return not actor.visible) and preview.game.sim.gold == 0, "The warning precedes the artisans and the donation")
			var bounds: Rect2 = captions.get_global_rect()
			var strip: Rect2 = captions.band.get_global_rect()
			check(is_zero_approx(strip.position.x) and is_equal_approx(strip.end.x,intro.root.size.x), "Stone strip spans the screen")
			check(is_equal_approx(strip.end.y,intro.root.size.y-48*intro.unit), "Stone reaches the preview controls")
			var bottom_space := 12. if extent.y > extent.x else 8.
			check(captions.band.size.y <= captions.words.get_minimum_size().y + 12. + bottom_space, "Band height follows the wrapped line plus its reading margin")
			if extent.x == 1280 and moment == 11.:
				await RenderingServer.frame_post_draw
				var frame := root.get_texture().get_image()
				var y := ceili(strip.position.y) + 5
				var repeated := 0
				# The old 128px tile repeated every stone vein across this clear row.
				for x in range(300,900):
					var a := frame.get_pixel(x,y)
					var b := frame.get_pixel(x+128,y)
					if maxi(maxi(absi(a.r8-b.r8),absi(a.g8-b.g8)),absi(a.b8-b.b8)) <= 2: repeated += 1
				check(repeated < 450, "Stone grain does not repeat at 128px intervals")
			check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= intro.root.size.x + 1, "Caption inside viewport")
			check(bounds.end.y <= intro.root.size.y - 48 * intro.unit, "Caption clears preview controls")
			check(captions.words.size.y >= captions.words.get_minimum_size().y, "No clipped text")
			var portrait := captions.get_node_or_null("Portrait") as TextureRect
			check(portrait != null, "Cinematic dialogue has a speaker portrait")
			if portrait != null:
				var asset := "master" if moment in [23.,34.,dungeon+6.] else "invoker"
				check(portrait.is_visible_in_tree() and portrait.texture.resource_path.ends_with("/"+asset+".webp"), "Portrait follows the speaking character")
				var face := portrait.get_global_rect()
				check(bounds.encloses(face) and face.end.x <= captions.words.get_global_rect().position.x, "Portrait fits to the left of the line")
				check(captions.speaker.get_global_rect().position.y >= face.end.y - 1, "Name sits under the portrait")
				check(bounds.encloses(captions.words.get_global_rect()), "Whole line fits in the dialogue")
			if moment in [11., 16., 28., dungeon+6., dungeon+12., dungeon+19.]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/sanctuary-procession/dialogue-%d-%04d.png" % [extent.x, roundi(moment*100)])
		preview.present(28.)
		var film = intro.film
		check(captions.speaker.text == "L’invocateur" and captions.words.text.contains("chercher les autres"), "The invoker dispatches the group")
		check(film.actors[0].sprite.texture.resource_path.ends_with("/s-idle.png"), "Invoker faces the messengers")
		for i in range(1,5):
			check(film.actors[i].position.is_equal_approx(film.stops[i]), "Messengers wait for the order")
		preview.present(31.6)
		for i in range(1,5):
			var runner = film.actors[i]
			check(runner.visible and runner.sprite.texture.resource_path.contains("/messengers/run-"), "Each messenger runs")
			check(runner.position.y > film.stops[i].y and film.navigation.clear(runner.position), "Messenger leaves along a clear trail")
		preview.present(dungeon-.1)
		for i in range(1,5):
			check(not film.actors[i].visible, "Messenger has left the sanctuary")
		check(film.actors[0].modulate.a == 0., "Invoker has descended")
		preview.present(23.9)
		for i in range(1,5):
			check(film.actors[i].visible and film.actors[i].sprite.texture.resource_path.ends_with("/oculin-kneel.png"), "Backward seek restores the assembly")
	for moment in [0., 9.9, 20., 21.9, 31.8, 41., dungeon+.1]:
		preview.present(moment)
		check(not captions.visible, "Silence at " + str(moment))
	preview.present(28.)
	var order_text: String = captions.words.text
	await create_timer(.15).timeout
	check(captions.words.text == order_text, "Pause preserves line")
	preview.present(11.)
	check(captions.speaker.text == "L’invocateur", "Backward seek restores speaker")
	intro._set_shot(intro.Shot.RITUAL)
	intro.elapsed = 15.5
	intro._process(.1)
	intro.set_process(false)
	check(captions.visible and captions.words.text.contains("serment"), "Live cinematic drives ritual dialogue")
	intro._set_shot(intro.Shot.ENTRANCE)
	intro._walk_in(6. / intro.ENTRY_DURATION)
	check(captions.speaker.text == "Le Maître", "Live dungeon arrival drives dialogue")
	intro._set_shot(intro.Shot.LESSON)
	check(captions.visible and captions.speaker.text=="L’invocateur","Invoker offers the villagers' gold")
	intro._skip()
	preview.game.place_village_bag(Vector2i(6,8))
	preview.game.place_village_bag(Vector2i(9,8))
	check(intro.shot==intro.Shot.ARTISAN and captions.speaker.text=="Le mineur", "Miner introduces the new ability")
	intro._process(intro.ARTISAN_BEAT_DURATION)
	intro.set_process(false)
	check(not captions.visible and intro.panel.visible, "Lesson replaces cinematic dialogue")
	intro._set_shot(intro.Shot.CLOSED)
	check(not captions.visible, "Skip clears dialogue")
	print("DIALOGUE_CHECK: failures=", failures)
	quit(0 if failures == 0 else 1)
