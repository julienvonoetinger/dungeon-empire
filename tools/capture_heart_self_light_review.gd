extends SceneTree
## Throwaway visual comparison on the real DungeonPreview scene.
const OUT := "res://docs/reference/isometric-review/painted-v1/heart-self-light-v1/"
var viewport: SubViewport
var camera: Camera2D

func _initialize() -> void:
	_capture.call_deferred()

func _save(name: String) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image().save_png(OUT+name+".png") == OK

func _capture() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(640,420)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/DungeonPreview.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	camera = scene.get_node("Camera2D")
	var origin: Vector2 = dungeon.grid_to_local(Vector2(12,14))
	camera.position = origin
	camera.zoom = Vector2.ONE*.75
	camera.force_update_scroll()
	if not await _save("current"):
		quit(1)
		return
	var world := dungeon.get_node("PreparedSprites")
	for child in world.get_children():
		if child is Sprite2D and str(child.name).begins_with("heart_shadow"):
			child.visible = false
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"prepared.json"))
	for entry: Dictionary in data.entries:
		var sprite := Sprite2D.new()
		sprite.name = "SelfLight_"+str(entry.id)
		sprite.texture = ImageTexture.create_from_image(Image.load_from_file("res://"+str(entry.file)))
		sprite.centered = false
		sprite.position = origin+Vector2(entry.frame[0],entry.frame[1])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.light_mask = 0
		sprite.z_index = 0
		if entry.blend == "add":
			var material := CanvasItemMaterial.new()
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			sprite.material = material
		world.add_child(sprite)
	if not await _save("self-lit"):
		quit(1)
		return
	print("Two views captured. Same geometry, heart, camera and floors; no torches or production changes.")
	quit()
