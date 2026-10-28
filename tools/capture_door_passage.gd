extends SceneTree
const STAGE = preload("res://tools/integrated_compact_door_stage.gd")
const DIRECTIONS := ["se", "sw", "nw", "ne"]
var out := "res://docs/reference/door-redesign/seal-v1/hero-fit-v14-passage/after/"
var stages: Array = []
var failures: Array[String] = []
var cases := 0
var before := false

func _initialize() -> void:
	before = "--before" in OS.get_cmdline_user_args()
	if before: out = out.replace("/after/", "/before/")
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	cases += 1
	if not ok and not failures.has(message): failures.append(message)

func inspect(stage: Node, center: bool, kind: String, frame: int) -> void:
	var jambs: Array = []
	var crowns: Array = []
	var bounds: Dictionary = {}
	for sample in stage.samples:
		if sample.kind == kind and int(sample.pose) == frame: bounds = sample.bounds[stage.facing]
	var origin := Vector3(stage.hero_grid.x,stage.hero_grid.y,0)
	var support := {"min":origin+Vector3(bounds.min[0],bounds.min[1],bounds.min[2]),"max":origin+Vector3(bounds.max[0],bounds.max[1],bounds.max[2]),"rect":Rect2(stage.actor.position-stage._anchor*.85,Vector2.ONE*256*.85)}
	for part in stage._solids:
		var role: String = stage._definition.entries[part.id].get("door_part", "")
		if role.begins_with("jamb"): jambs.append(part)
		if role == "crown": crowns.append(part)
		if role.is_empty() or not part.rect.intersects(support.rect): continue
		var behind: bool = stage._behind(support,part)
		var in_front: bool = stage._behind(part,support)
		if behind != in_front:
			check((stage.actor.get_index()<part.node.get_index())==behind,stage.facing+": separated actor/"+role+" "+kind+str(frame)+" at "+str(stage.hero_grid))
	check(jambs.size() == 2, stage.facing + ": independently sortable jambs")
	if not center or jambs.size() != 2: return
	jambs.sort_custom(func(a, b): return a.depth < b.depth)
	var index: int = stage.actor.get_index()
	check(jambs[0].node.get_index() < index, stage.facing + ": far jamb behind passing hero")
	check(index < jambs[1].node.get_index(), stage.facing + ": near jamb in front of passing hero")
	for crown in crowns: check(index < crown.node.get_index(), stage.facing + ": passing hero below crown")

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out+name+".png") == OK, "Save "+name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280,900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_factor = 1.0
	var bg := ColorRect.new()
	bg.color = Color("101722")
	bg.size = root.size
	root.add_child(bg)
	var title := Label.new()
	title.text = "Traversée — " + ("ancien découpage" if before else "montants indépendants")
	title.position = Vector2(24,16)
	title.add_theme_font_size_override("font_size",24)
	bg.add_child(title)
	for i in 4:
		var card := ColorRect.new()
		card.color = Color("172130")
		card.position = Vector2(12+(i%2)*634,65+(i/2)*412)
		card.size = Vector2(622,400)
		bg.add_child(card)
		var stage := STAGE.new()
		stage.opened = true
		card.add_child(stage)
		stage.build(DIRECTIONS[i])
		stage.scale = Vector2.ONE*.61
		stage.position = Vector2(311,240)-stage.grid_to_local(Vector2(1.5,.5) if i%2==0 else Vector2(.5,1.5))*.61
		stages.append(stage)
	for kind in ["walk","run"]:
		for frame in 8:
			for stage in stages:
				stage.review_pose(kind, frame, 0)
				inspect(stage,true,kind,frame)
			if frame == 0: await shot(kind+"-center")
	for step in 49:
		var travel: float = lerpf(.85,-.85,step/48.0)
		for stage in stages:
			stage.review_pose("walk",step%8,travel)
			inspect(stage,step==24,"walk",step%8)
		await shot("walk-%02d"%step)
	FileAccess.open(out+"validation.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":cases,"failures":failures,"directions":4,"positions":49,"center_poses":16},"\t"))
	print("DOOR_PASSAGE checks=",cases," failures=",failures)
	quit(0 if failures.is_empty() else 1)
