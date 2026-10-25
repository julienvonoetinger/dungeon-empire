extends SceneTree
## Human appearance review of the integrated scene and inspector settings.
const OUT := "res://docs/reference/isometric-decoration-review/v2-edge-cracks/integration/"
var viewport: SubViewport
var observations: Array[Dictionary] = []
var failed := false

func _initialize() -> void:
	_capture.call_deferred()

func _save(name: String, dungeon: Node2D) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png(OUT+name+".png")
	if result != OK:
		failed = true
		push_error("Cannot save decoration capture: "+name)
	var placements := []
	for child in dungeon.get_node("PreparedSprites").get_children():
		if child is Sprite2D and str(child.name).begins_with("detail_"):
			placements.append({"name":str(child.name),"position":[child.position.x,child.position.y],"z":child.z_index})
	observations.append({"capture":name,"enabled":dungeon.surface_details,"seed":dungeon.surface_detail_seed,"count":placements.size(),"placements":placements})

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/MobileReference.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	dungeon.surface_details = false
	await _save("reference-bare", dungeon)
	dungeon.surface_details = true
	await _save("reference-decorated", dungeon)
	dungeon.surface_detail_seed = 43
	await _save("reference-seed-43", dungeon)
	dungeon.surface_detail_seed = 17
	await _save("reference-restored", dungeon)
	viewport.remove_child(scene)
	scene.free()
	var large: Node2D = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(large)
	await process_frame
	await _save("six-room-native", large.get_node("Dungeon"))
	viewport.remove_child(large)
	large.free()
	var out := FileAccess.open(OUT+"observations.json", FileAccess.WRITE)
	if out == null:
		push_error("Cannot write decoration observations.")
		quit(1)
		return
	out.store_string(JSON.stringify(observations,"\t")+"\n")
	quit(1 if failed else 0)
