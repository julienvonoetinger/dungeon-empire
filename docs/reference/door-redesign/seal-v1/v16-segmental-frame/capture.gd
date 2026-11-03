extends SceneTree

const Stage = preload("res://docs/reference/door-redesign/seal-v1/v16-segmental-frame/stage.gd")
const OUT := "res://docs/reference/door-redesign/seal-v1/v16-segmental-frame/vues/"
const DIRECTIONS := ["ne","nw","sw","se"]
var stage: Node2D
var failures := []

func _initialize() -> void: call_deferred("run")

func shot(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT + id + ".png") != OK: failures.append(id)

func setup(bg: Node, direction: String, current: bool, open: bool) -> void:
	if is_instance_valid(stage): stage.free()
	stage = Stage.new()
	stage.revision = "current" if current else "study"
	stage.opened = open
	bg.add_child(stage)
	stage.build(direction)
	var cell := Vector2(1.5,.5) if stage.CONFIG[direction].axis == 0 else Vector2(.5,1.5)
	stage.scale = Vector2.ONE * 1.27
	stage.position = Vector2(410,350) - stage.grid_to_local(cell) * stage.scale
	stage.review_pose("idle")
	if not current: check_wall_contacts(direction)

func check_wall_contacts(direction: String) -> void:
	var contacts := 0
	for post: Dictionary in stage._solids:
		if not str(stage._definition.entries[post.id].get("door_part","")).begins_with("jamb"): continue
		for rail: Dictionary in stage._solids:
			if not str(rail.id).begins_with("wall-"): continue
			var along := 0 if str(rail.id).begins_with("wall-h-") else 1
			var across := 1 - along
			if rail.at[across] < post.min[across] or rail.at[across] > post.max[across]: continue
			if rail.at[along] != floorf((post.min[along]+post.max[along])*.5): continue
			if rail.has("wall_segment"):
				failures.append("supporting wall cut "+direction)
				continue
			if not is_equal_approx(post.min.z,rail.max.z): failures.append("post must start on wall "+direction)
			if post.min[along] < rail.min[along] or post.max[along] > rail.max[along]: failures.append("unsupported post "+direction)
			if not is_equal_approx(post.min[across],rail.min[across]) or not is_equal_approx(post.max[across],rail.max[across]):
				failures.append("post/wall faces "+direction)
			if not is_equal_approx(post.max[along]-post.min[along],rail.max[across]-rail.min[across]):
				failures.append("post depth "+direction)
			contacts+=1
	if contacts != 2: failures.append("expected two intact supporting walls "+direction)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(820,550)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var bg := ColorRect.new()
	bg.color = Color("101724")
	bg.size = root.size
	root.add_child(bg)
	for d in DIRECTIONS:
		for current in [true,false]:
			setup(bg,d,current,false)
			stage.actor.hide()
			stage._contact.hide()
			await shot(("actuelle-" if current else "cadre-")+d)
		stage.actor.show()
		stage._contact.show()
		stage.review_pose("lock",3)
		if stage.registration_error() > .01: failures.append("contact "+d)
		await shot("crochetage-"+d)
		setup(bg,d,false,true)
		stage.review_pose("walk",3,0)
		var jambs: Array = []
		var crown: Node
		for part: Dictionary in stage._solids:
			var role: String = stage._definition.entries[part.id].get("door_part","")
			if role.begins_with("jamb"): jambs.append(part)
			if role == "crown": crown = part.node
			if role == "panel": failures.append("open panel "+d)
		jambs.sort_custom(func(a,b):return a.depth<b.depth)
		var hero: int = stage.actor.get_index()
		if jambs.size()!=2 or not crown or not (jambs[0].node.get_index()<hero and hero<jambs[1].node.get_index() and hero<crown.get_index()):
			failures.append("passage ordering "+d)
		await shot("passage-"+d)
	print("Door frame study: four directions; passage and contact failures ",failures)
	quit(0 if failures.is_empty() else 1)
