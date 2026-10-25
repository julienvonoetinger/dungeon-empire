extends SceneTree
const OUT := "res://docs/reference/isometric-review/painted-v1/dungeon-preview-shadow-diagnostic/"
func _initialize() -> void:
	inspect.call_deferred()
func inspect() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 420)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var scene: Node2D = load("res://scenes/DungeonPreview.tscn").instantiate()
	vp.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position = dungeon.grid_to_local(Vector2(12, 14))
	camera.zoom = Vector2.ONE * .75
	camera.force_update_scroll()
	var effects: Array[Dictionary] = []
	var shadows: Array[Sprite2D] = []
	var lights := 0
	for child in dungeon.get_node("PreparedSprites").get_children():
		if child is PointLight2D:
			lights += 1
		if child is Sprite2D and str(child.name).begins_with("heart_shadow"):
			shadows.append(child)
			effects.append({"name":str(child.name),"visible":child.visible,"source":child.get_meta("shadow_source", "contact only"),"position":[child.position.x,child.position.y],"z":child.z_index})
	for label in ["contact", "without-contact"]:
		for shadow in shadows:
			shadow.visible = label == "contact"
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var result := vp.get_texture().get_image().save_png(OUT+label+".png")
		if result != OK:
			quit(1)
			return
	var report := {"scene":"DungeonPreview","lights":lights,"north_torches":dungeon.torch_north_cells.size(),"west_torches":dungeon.torch_west_cells.size(),"effects":effects}
	var output := FileAccess.open(OUT+"observations.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t")+"\n")
	print(JSON.stringify(report))
	quit()
