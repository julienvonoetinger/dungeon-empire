extends SceneTree
const STAGE = preload("res://tools/integrated_compact_door_stage.gd")
var OUT := "res://docs/reference/door-redesign/seal-v1/hero-fit-v12-integrated/native-sizing/"
const FACINGS := ["se", "sw", "nw", "ne"]
const LABELS := ["Southeast", "Southwest", "Northwest", "Northeast"]
var stages: Array = []
var containers: Array[Control] = []
var title: Label
var background: Control
var failures: Array[String] = []
var common_bounds := Rect2()

func _initialize() -> void: call_deferred("capture")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "Save " + name)

func populate(revision: String, opened := false) -> void:
	for stage in stages: stage.free()
	stages.clear()
	for i in 4:
		var stage = STAGE.new()
		stage.revision = revision
		stage.opened = opened
		containers[i].add_child(stage)
		stage.build(FACINGS[i])
		stages.append(stage)
		if common_bounds == Rect2(): common_bounds = stage.get_content_rect()
		else: common_bounds = common_bounds.merge(stage.get_content_rect())
	for stage in stages:
		stage.scale = Vector2.ONE * minf(752.0 / common_bounds.size.x, 414.0 / common_bounds.size.y)
		stage.position = Vector2(376,207) - common_bounds.get_center() * stage.scale.x
		check(stage.actor.scale == Vector2.ONE * .85, "Hero kept at accepted scale")
		check(stage.registration_error() < .01, "Lock position " + stage.facing)

func capture() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			OUT = arg.trim_prefix("--output=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1600,1060)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor = 1.0
	check(root.get_visible_rect().size == Vector2(1600,1060), "Capture has unscaled logical coordinates")
	background = ColorRect.new()
	background.color = Color("101722")
	background.size = root.size
	root.add_child(background)
	title = Label.new()
	title.position = Vector2(28,18)
	title.add_theme_font_size_override("font_size",26)
	background.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(28,57)
	subtitle.text = "Vulpin à la même échelle · porte plus basse · montants affinés · serrure abaissée"
	subtitle.add_theme_font_size_override("font_size",18)
	background.add_child(subtitle)
	for i in 4:
		var card := ColorRect.new()
		card.color = Color("172130")
		card.position = Vector2(24+(i%2)*788,100+(i/2)*468)
		card.size = Vector2(764,452)
		background.add_child(card)
		var caption := Label.new()
		caption.position = Vector2(16,8)
		caption.text = LABELS[i]
		caption.add_theme_font_size_override("font_size",20)
		card.add_child(caption)
		var content := Control.new()
		content.position = Vector2(6,34)
		content.size = Vector2(752,414)
		card.add_child(content)
		containers.append(content)
	populate("after")
	# Establish one immutable frame for both revisions and all four directions.
	common_bounds = common_bounds.grow(12)
	for revision in ["after"]:
		populate(revision)
		title.text = ("Essai précédent — porte trop massive" if revision == "before" else "Porte intégrée — proportions validées")
		for stage in stages: stage.review_pose("idle")
		await shot(revision + "-standing")
	populate("after")
	title.text = "Crochetage — serrure abaissée, bras avancés"
	for frame in 8:
		for stage in stages:
			stage.review_pose("lock",frame)
			check(stage.registration_error()<.01,"Lock contact pose %d"%frame)
		await shot("lock-%02d"%frame)
	for stage in stages:
		stage.set_guides(true)
		stage.set_ghost(true)
	await shot("lock-guides")
	populate("after",true)
	title.text = "Porte déverrouillée — cadre conservé, battant retiré"
	for stage in stages:
		stage.actor.hide()
		stage._contact.hide()
	await shot("open-frame")
	for stage in stages:
		stage.actor.show()
		stage._contact.show()
	for kind in ["walk","run"]:
		title.text = "Passage ouvert — " + ("marche" if kind == "walk" else "course") + " au centre de l’ouverture"
		for frame in 8:
			for stage in stages: stage.review_pose(kind,frame,0)
			await shot(kind+"-%02d"%frame)
	# Large single-direction view for validating wall-to-column continuity.
	for child in background.get_children(): child.visible = false
	root.size = Vector2i(1280,900)
	background.size = root.size
	title.visible = true
	title.text = "Porte intégrée — texture et raccords aux murs"
	var detail := STAGE.new()
	detail.revision = "after"
	background.add_child(detail)
	detail.build("nw")
	detail.scale = Vector2.ONE * 1.45
	detail.position = Vector2(640,540) - detail.lock_local * 1.45
	detail.review_pose("idle")
	await shot("detail-standing")
	detail.review_pose("lock",4)
	await shot("detail-lock")
	var file := FileAccess.open(OUT+"validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"scale":stages[0].scale.x,"common_frame":str(common_bounds),"directions":4,"lock_samples":32,"passage_samples":64,"limits":"Static held poses at centre, no runtime traversal or opening mechanics; native solid ordering is reused."},"\t"))
	file.close()
	print("INTEGRATED_COMPACT_DOOR failures=",failures.size())
	quit(0 if failures.is_empty() else 1)


