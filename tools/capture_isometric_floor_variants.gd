extends SceneTree
## Visual evidence at game scale, plus stable placement observations.
const OUT := "res://docs/reference/isometric-floor-variation-review/v1/integration/"
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
const FLOOR = preload("res://scripts/dungeon_floor_variants.gd")
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
		push_error("Cannot save floor review: "+name)
	var counts := {}
	var placements := []
	var other := []
	for child in dungeon.get_node("PreparedSprites").get_children():
		if not child is Sprite2D:
			continue
		var id := str(child.get_meta("prepared_id", ""))
		var record := {"id":id,"position":[child.position.x,child.position.y],"z":child.z_index}
		if id.begins_with("floor"):
			counts[id] = int(counts.get(id,0)) + 1
			placements.append(record)
		else:
			other.append(record)
	observations.append({"capture":name,"counts":counts,"placements":placements,"nonFloor":other})


func _patch(seed: int, suffix: String) -> void:
	var dungeon := RENDERER.new()
	viewport.add_child(dungeon)
	dungeon._load_definition(true)
	dungeon._world = Node2D.new()
	dungeon._world.name = "PreparedSprites"
	dungeon.add_child(dungeon._world)
	for y in range(-3,3):
		for x in range(-3,3):
			var at := Vector2i(x,y)
			dungeon._draw_part(dungeon._part(FLOOR.select(at,seed),Vector2(at)),0)
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE*.75
	dungeon.add_child(camera)
	await _save("patch-"+suffix,dungeon)
	if seed == 17 and suffix == "seed17":
		camera.zoom = Vector2.ONE*1.5
		camera.force_update_scroll()
		await _save("patch-close",dungeon)
	viewport.remove_child(dungeon)
	dungeon.free()


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	await _patch(17,"seed17")
	await _patch(43,"seed43")
	await _patch(17,"restored17")
	var scene: Node2D = load("res://scenes/MobileReference.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	dungeon.floor_variants = false
	await _save("reference-before",dungeon)
	dungeon.floor_variants = true
	await _save("reference-seed17",dungeon)
	dungeon.floor_variant_seed = 43
	await _save("reference-seed43",dungeon)
	dungeon.floor_variant_seed = 17
	await _save("reference-restored17",dungeon)
	viewport.remove_child(scene)
	scene.free()
	var large: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(large)
	await process_frame
	await _save("six-room-native",large.get_node("Dungeon"))
	viewport.remove_child(large)
	large.free()
	var file := FileAccess.open(OUT+"observations.json",FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(observations,"\t")+"\n")
	quit(1 if failed else 0)
