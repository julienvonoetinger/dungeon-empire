extends SceneTree
## Focused visual evidence; no changes to authored scenes or user editor state.
const OUT := "res://docs/reference/isometric-floor-damage-review/v1/integration/"
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
const FLOOR = preload("res://scripts/dungeon_floor_variants.gd")
const DAMAGE = preload("res://scripts/dungeon_floor_damage.gd")
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


func _patch(seed: int, suffix: String, forced := false) -> void:
	var dungeon := RENDERER.new()
	viewport.add_child(dungeon)
	dungeon._load_definition(true)
	dungeon._world = Node2D.new()
	dungeon._world.name = "PreparedSprites"
	dungeon.add_child(dungeon._world)
	var floors: Array[Dictionary] = []
	for y in range(-4,4):
		for x in range(-4,4):
			var at := Vector2i(x,y)
			floors.append(dungeon._part(FLOOR.select(at,17),Vector2(at)))
	var selected := DAMAGE.select(floors,[],{},seed,true)
	if forced:
		floors.clear()
		selected.clear()
		for i in range(4):
			var at := Vector2i(i%2*2-1,i/2*2-1)
			var id := "floor-b%d" % (i+1)
			floors.append(dungeon._part(id,Vector2(at)))
			selected[at] = DAMAGE.IDS[id]
	else:
		var reverse := floors.duplicate()
		reverse.reverse()
		if DAMAGE.select(reverse,[],{},seed,true) != selected:
			failed = true
	for part in floors:
		dungeon._draw_part(part,0)
		if selected.has(Vector2i(part.at)):
			dungeon._draw_part(dungeon._part(selected[Vector2i(part.at)],part.at),0)
	var camera := Camera2D.new()
	camera.position = Vector2(0,64) if forced else Vector2.ZERO
	camera.zoom = Vector2.ONE*(.75 if forced else .5)
	dungeon.add_child(camera)
	await _save("patch-"+suffix,dungeon)
	if forced:
		camera.zoom = Vector2.ONE*1.5
		camera.force_update_scroll()
		await _save("samples-close",dungeon)
	viewport.remove_child(dungeon)
	dungeon.free()


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	await _patch(17,"samples",true)
	await _patch(17,"seed17")
	await _patch(43,"seed43")
	await _patch(17,"restored17")
	var scene: Node2D = load("res://scenes/MobileReference.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	dungeon.floor_damage = false
	await _save("reference-before",dungeon)
	dungeon.floor_damage = true
	await _save("reference-seed17",dungeon)
	dungeon.floor_damage_seed = 43
	await _save("reference-seed43",dungeon)
	dungeon.floor_damage_seed = 17
	await _save("reference-restored17",dungeon)
	dungeon.floor_corruption = false
	await _save("reference-no-corruption",dungeon)
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
	file.store_string(JSON.stringify({"captures":observations,"dictionaryOrderStable":not failed},"\t")+"\n")
	quit(1 if failed else 0)
