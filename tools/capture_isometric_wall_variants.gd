extends SceneTree
## Focused human visual review and placement observations, not a gameplay suite.
const OUT := "res://docs/reference/isometric-wall-variation-review/v2-subvariants/integration/"
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
const VARIANTS := ["a1", "a2", "a3", "c1", "c2", "c3", "f1", "f2", "f3"]
var viewport: SubViewport
var observations: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
	_capture.call_deferred()

func _save(name: String, dungeon: Node2D) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if viewport.get_texture().get_image().save_png(OUT+name+".png") != OK:
		failed = true
		push_error("Cannot save wall review: "+name)
	var counts := {}
	var placements := []
	for child in dungeon.get_node("PreparedSprites").get_children():
		var id := str(child.get_meta("prepared_id", ""))
		if child is Sprite2D and id.begins_with("wall-"):
			var variant: String = id.get_slice("-", 3)
			if variant.is_empty():
				variant = "base"
			counts[variant] = int(counts.get(variant, 0)) + 1
			placements.append({"name":id,"position":[child.position.x,child.position.y]})
	observations.append({"capture":name,"counts":counts,"placements":placements})

func _sample(variant: String) -> void:
	var dungeon := RENDERER.new()
	viewport.add_child(dungeon)
	dungeon._load_definition(true)
	dungeon._world = Node2D.new()
	dungeon._world.name = "PreparedSprites"
	dungeon.add_child(dungeon._world)
	for y in range(3):
		for x in range(3):
			dungeon._draw_part(dungeon._part("floor", Vector2(x,y)), 0)
	var parts: Array[Dictionary] = []
	for axis in ["h","v"]:
		for i in range(3):
			var bits := 1 if i == 0 else 2 if i == 2 else 0
			var base := "wall-%s-%d" % [axis,bits]
			var at := Vector2(i,0) if axis == "h" else Vector2(0,i)
			var part: Dictionary = dungeon._part(base if variant.begins_with("f") else base+"-"+variant, at)
			if variant.begins_with("f"):
				part["wall_ornament"] = base+"-"+variant
			parts.append(part)
	# A short fully pillar-bounded segment exercises the remaining end profile 3.
	for axis in ["h","v"]:
		var base := "wall-%s-3" % axis
		var part: Dictionary = dungeon._part(base if variant.begins_with("f") else base+"-"+variant, Vector2(2,2))
		if variant.begins_with("f"):
			part["wall_ornament"] = base+"-"+variant
		parts.append(part)
	for at in [Vector2(0,0),Vector2(3,0),Vector2(0,3),Vector2(2,2),Vector2(3,2),Vector2(2,3)]:
		parts.append(dungeon._part("pillar",at))
	for part in dungeon._ordered_parts(parts):
		dungeon._draw_part(part,1)
		if part.has("wall_ornament"):
			dungeon._draw_part(dungeon._part(part.wall_ornament, part.at),1)
	var camera := Camera2D.new()
	camera.position = Vector2(0,145)
	camera.zoom = Vector2.ONE * .75
	dungeon.add_child(camera)
	await _save("variant-"+variant+"-native",dungeon)
	camera.zoom = Vector2.ONE * 1.5
	camera.force_update_scroll()
	await _save("variant-"+variant+"-close",dungeon)
	viewport.remove_child(dungeon)
	dungeon.free()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for variant in VARIANTS:
		await _sample(variant)
	var scene: Node2D = load("res://scenes/MobileReference.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	dungeon.wall_variants = false
	await _save("reference-before",dungeon)
	dungeon.wall_variants = true
	await _save("reference-seed17",dungeon)
	dungeon.wall_variant_seed = 43
	await _save("reference-seed43",dungeon)
	dungeon.wall_variant_seed = 17
	await _save("reference-restored17",dungeon)
	dungeon.wall_corruption = false
	await _save("reference-no-corruption",dungeon)
	viewport.remove_child(scene)
	scene.free()
	var large: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(large)
	await process_frame
	await _save("six-room-native",large.get_node("Dungeon"))
	viewport.remove_child(large)
	large.free()
	var out := FileAccess.open(OUT+"observations.json",FileAccess.WRITE)
	if out == null:
		quit(1)
		return
	out.store_string(JSON.stringify(observations,"\t")+"\n")
	quit(1 if failed else 0)
