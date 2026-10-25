extends SceneTree
## Render evidence and placement observations, not an automated gameplay suite.
const OUT := "res://docs/reference/isometric-prop-review/v1/integration/"
const RENDERER = preload("res://scripts/mobile_dungeon_renderer.gd")
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
	var sprites := []
	var lights := []
	for child in dungeon.get_node("PreparedSprites").get_children():
		if child is Sprite2D:
			sprites.append({"id":str(child.get_meta("prepared_id", "")),"position":[child.position.x,child.position.y],"scale":[child.scale.x,child.scale.y],"z":child.z_index,"index":child.get_index()})
		elif child is PointLight2D:
			lights.append({"name":str(child.name),"position":[child.position.x,child.position.y]})
	observations.append({"capture":name,"sprites":sprites,"lights":lights,"issues":Array(dungeon.get_decoration_issues())})

func _scene(name: String) -> Node2D:
	var scene: Node2D = load("res://scenes/"+name+".tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	return scene

func _remove(scene: Node2D) -> void:
	viewport.remove_child(scene)
	scene.free()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var gallery := await _scene("DungeonDecorations")
	var dungeon: Node2D = gallery.get_node("Dungeon")
	var camera: Camera2D = gallery.get_node("Camera2D")
	await _save("gallery-mobile",dungeon)
	dungeon.decoration_lights_enabled = false
	await _save("gallery-unlit",dungeon)
	dungeon.decoration_lights_enabled = true
	await _save("gallery-restored",dungeon)
	dungeon.torch_lights_enabled = false
	await _save("gallery-torches-disabled",dungeon)
	dungeon.decorations_enabled = false
	await _save("gallery-bare",dungeon)
	dungeon.decorations_enabled = true
	camera.zoom = Vector2.ONE*1.5
	camera.force_update_scroll()
	await _save("gallery-close",dungeon)
	_remove(gallery)
	for name in ["MobileReference","DungeonPreview","SixRoomPreview"]:
		var scene := await _scene(name)
		dungeon = scene.get_node("Dungeon")
		camera = scene.get_node("Camera2D")
		await _save(name+"-native",dungeon)
		if name != "MobileReference":
			camera.position = dungeon.grid_to_local(Vector2(12,14))
			camera.force_update_scroll()
			await _save(name+"-heart-room",dungeon)
		_remove(scene)
	# Negative-coordinate floor, rear/front walls, then invalid authoring probes.
	dungeon = RENDERER.new()
	viewport.add_child(dungeon)
	var cells := {}
	for y in range(-1,2):
		for x in range(-1,2):
			cells[Vector2i(x,y)] = true
	var authored: Dictionary[Vector2,String] = {Vector2(-.6,-.6):"prop-idol",Vector2(1.6,1.6):"prop-stele",Vector2(.1,.9):"prop-candles"}
	var plan := {"cells":cells,"openings":{},"floor_variants":true,"decoration_positions":authored}
	dungeon.render_plan(plan,{},true)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE*1.5
	camera.position = Vector2(0,45)
	dungeon.add_child(camera)
	await _save("wall-order-negative-coordinates",dungeon)
	var invalid: Dictionary[Vector2,String] = {
		Vector2(-.78,-.2):"prop-crystals", # floor exists but wall overlaps support
		Vector2(5,5):"prop-crystals", # void
		Vector2(.5,.5):"prop-basin", # special
		Vector2(1.5,.5):"missing-prop", # unknown ID
		Vector2(.5,1.5):"prop-idol", # heart
		Vector2(1.4,1.5):"prop-candles",Vector2(1.41,1.51):"prop-candles" # duplicate support
	}
	plan.decoration_positions = invalid
	plan.hearts = PackedVector2Array([Vector2(.5,1.5)])
	dungeon.render_plan(plan,{Vector2i(0,0):"doors/north"},false)
	await _save("invalid-authoring",dungeon)
	_remove(dungeon)
	var file := FileAccess.open(OUT+"observations.json",FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify({"captures":observations},"\t")+"\n")
	quit(1 if failed else 0)
