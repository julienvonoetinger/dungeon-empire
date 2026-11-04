extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/sanctuary-procession")
	var preview = load("res://scenes/previews/SanctuaryTransition.tscn").instantiate()
	root.add_child(preview)
	preview.paused = true
	var intro = preview.intro
	var captions = intro.dialogue
	for extent in [Vector2i(1280,720), Vector2i(390,844), Vector2i(844,390)]:
		root.size = extent
		await process_frame
		for moment in [11., 16., 23., 28., 32., 42.4, 46.4]:
			preview.present(moment)
			for frame in range(4): await process_frame
			check(captions.visible and not captions.words.text.is_empty(), "Dialogue shown at " + str(moment))
			var bounds: Rect2 = captions.get_global_rect()
			check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= intro.root.size.x + 1, "Caption inside viewport")
			check(bounds.end.y <= intro.root.size.y - 48 * intro.unit, "Caption clears preview controls")
			check(captions.words.size.y >= captions.words.get_minimum_size().y, "No clipped text")
			if moment in [16., 28., 46.4]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://artifacts/sanctuary-procession/dialogue-%d-%04d.png" % [extent.x, roundi(moment*100)])
	for moment in [0., 9.9, 20., 21.9, 35., 39.9, 40.5]:
		preview.present(moment)
		check(not captions.visible, "Silence at " + str(moment))
	preview.present(28.)
	var master_text: String = captions.words.text
	await create_timer(.15).timeout
	check(captions.words.text == master_text, "Pause preserves line")
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
	intro.set_process(false)
	check(not captions.visible and intro.panel.visible, "Lesson replaces cinematic dialogue")
	intro._set_shot(intro.Shot.CLOSED)
	check(not captions.visible, "Skip clears dialogue")
	print("DIALOGUE_CHECK: failures=", failures)
	quit(0 if failures == 0 else 1)
