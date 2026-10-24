extends SceneTree
## Focused user-authorized heart integration trials against production code.
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
const STUDY = preload("res://scripts/wireframe_cell_study.gd")
const OUT := "res://docs/reference/mobile-heart-review/ritual-v3/integration/"
var viewport: SubViewport
var checks: Array[Dictionary] = []
var failures := 0
var captures: Array[String] = []
var horizontal_textures: Array = []

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"check":label,"passed":passed})
	if not passed:
		failures += 1
		print("FAIL: ",label)

func finish() -> void:
	var report := FileAccess.open(OUT+"godot-report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t")+"\n")
	print("Approved heart: ",checks.size()," checks, ",failures," failures, ",captures.size()," captures.")
	quit(1 if failures else 0)

func save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	check(name+": image saved",viewport.get_texture().get_image().save_png(OUT+"captures/"+name+".png")==OK)
	captures.append(name)

func heart_count(dungeon: Node) -> int:
	var count := 0
	for child in dungeon.get_node("PreparedSprites").get_children():
		if str(child.name).begins_with("heart"):
			count += 1
	return count

func trial(name: String, at: Vector2) -> void:
	var dungeon := RENDERER.new()
	viewport.add_child(dungeon)
	var cells := {}
	for y in 2:
		for x in 2:
			cells[Vector2i(x,y)] = true
	var plan := {"cells":cells,"openings":{},"hearts":PackedVector2Array([at])}
	dungeon.render_plan(plan,{},false)
	check(name+": one prepared heart",heart_count(dungeon)==1)
	var heart: Sprite2D = dungeon.get_node_or_null("PreparedSprites/heart")
	if heart != null:
		check(name+": approved dimensions",heart.texture.get_size()==Vector2(289,289))
		check(name+": ground anchor",heart.position.is_equal_approx(at*256-Vector2(144.5,155.792663476874)))
		check(name+": no scale or rotation",heart.scale==Vector2.ONE and is_zero_approx(heart.rotation))
		if name in ["north","south"]:
			var overlaps := 0
			var rect := Rect2(heart.position,heart.texture.get_size())
			for child in dungeon.get_node("PreparedSprites").get_children():
				if child.texture in horizontal_textures and rect.intersects(Rect2(child.position,child.texture.get_size())):
					var is_relevant: bool = child.position.y < 100 if name=="north" else child.position.y > 300
					if is_relevant:
						overlaps += 1
						check(name+": shared-layer ordering",child.z_index==heart.z_index and (child.get_index()<heart.get_index() if name=="north" else child.get_index()>heart.get_index()))
			check(name+": actual wall overlap",overlaps>0)
	var camera := Camera2D.new()
	camera.position = Vector2(256,256)
	camera.zoom = Vector2.ONE*.75
	viewport.add_child(camera)
	camera.force_update_scroll()
	await save(name)
	dungeon.render_plan(plan,{},false)
	check(name+": rebuild does not duplicate heart",heart_count(dungeon)==1)
	viewport.remove_child(dungeon)
	dungeon.free()
	viewport.remove_child(camera)
	camera.free()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT+"captures")
	var definition: Resource = load("res://assets/dungeon/mobile-kit/catalog.tres")
	check("Production atlas supplies approved heart",definition.entries.has("heart"))
	if failures:
		finish()
		return
	for id: String in definition.textures:
		if id.begins_with("wall-h-"):
			horizontal_textures.append(definition.textures[id])
	viewport = SubViewport.new()
	viewport.size = Vector2i(420,500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for entry: Array in [["center",Vector2.ONE],["north",Vector2(1,.52)],["south",Vector2(1,1.48)],["west",Vector2(.52,1)],["east",Vector2(1.48,1)]]:
		await trial(entry[0],entry[1])
	var standalone: Node2D = load("res://scenes/DungeonHeart.tscn").instantiate()
	viewport.add_child(standalone)
	await process_frame
	check("Standalone uses same prepared heart",heart_count(standalone)==1)
	var standalone_sprite: Sprite2D = standalone.get_node_or_null("PreparedSprites/heart")
	check("Standalone uses ground origin",standalone_sprite!=null and standalone_sprite.position.is_equal_approx(Vector2(-144.5,-155.792663476874)))
	viewport.remove_child(standalone)
	standalone.free()
	var study := STUDY.new()
	study.layout = load("res://assets/layouts/single_cell.tres") if ResourceLoader.exists("res://assets/layouts/single_cell.tres") else null
	viewport.add_child(study)
	await process_frame
	check("Layout study defaults to no heart",heart_count(study)==0)
	study.set("heart_positions",PackedVector2Array([Vector2(99,99)]))
	await process_frame
	check("Off-floor heart omitted",heart_count(study)==0)
	study.set("heart_positions",PackedVector2Array([Vector2(.1,.5)]))
	await process_frame
	check("Partly off-floor support omitted",heart_count(study)==0)
	study.render_plan({"cells":{Vector2i.ZERO:true},"openings":{},"hearts":PackedVector2Array([Vector2(.5,.5)])},{Vector2i.ZERO:"entrances/south"},false)
	check("Heart cannot share stair cell",heart_count(study)==0)
	study.render_plan({"cells":{Vector2i.ZERO:true},"openings":{},"hearts":PackedVector2Array([Vector2(.5,.5)])},{Vector2i.ZERO:"doors/south"},false)
	check("Heart cannot share door cell",heart_count(study)==0)
	viewport.remove_child(study)
	study.free()
	viewport.size = Vector2i(1280,720)
	for name: String in ["MobileReference","SixRoomPreview","DungeonPreview"]:
		var scene: Node2D = load("res://scenes/"+name+".tscn").instantiate()
		viewport.add_child(scene)
		await process_frame
		var dungeon: Node2D = scene.get_node("Dungeon")
		check(name+": heart present",heart_count(dungeon)==1)
		var camera: Camera2D = scene.get_node("Camera2D")
		check(name+": fixed camera",camera.zoom==Vector2(.75,.75))
		await save(name+"-native")
		var heart: Sprite2D = dungeon.get_node_or_null("PreparedSprites/heart")
		if heart:
			camera.position = heart.position+Vector2(144.5,155.792663476874)
			camera.force_update_scroll()
			await save(name+"-heart")
		dungeon.refresh_preview()
		check(name+": refresh preserves single heart",heart_count(dungeon)==1)
		viewport.remove_child(scene)
		scene.free()
	check("All requested captures completed",captures.size()==11)
	finish()
