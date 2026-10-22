extends SceneTree

var failures: Array[String] = []
var images: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check_tree(scene.get_node("Dungeon"))
	_check_atlas_gutters()
	print("Native alpha regression: ",failures.size()," failures")
	for failure in failures.slice(0,12):
		print("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _check_tree(node: Node) -> void:
	if node is Polygon2D:
		failures.append("Production cutout polygon remains: "+str(node.get_path()))
	if node is Sprite2D and node.get_meta("kind", "effect") != "effect":
		if node.region_enabled or node.material != null:
			failures.append("Clipping/material remains: "+str(node.get_path()))
		var texture: Texture2D = node.texture
		if texture is AtlasTexture:
			texture = texture.atlas
		if texture != null and not images.has(texture.resource_path):
			var img := Image.new()
			img.load_png_from_buffer(FileAccess.get_file_as_bytes(texture.resource_path))
			images[texture.resource_path] = img
		var source: Image = images.get(texture.resource_path) if texture != null else null
		if source == null or source.detect_alpha() == Image.ALPHA_NONE:
			failures.append("Missing source alpha: "+str(node.get_path()))
		if not is_equal_approx(node.scale.x,node.scale.y):
			failures.append("Non-uniform sprite scale: "+str(node.get_path()))
	for child in node.get_children():
		_check_tree(child)

func _check_atlas_gutters() -> void:
	var kit = load("res://scripts/alpha_kit.gd")
	for id: String in kit.PARTS:
		var definition: Array = kit.PARTS[id]
		var path: String = kit.ROOT+kit.SHEETS[definition[0]][0]
		var source: Image = images[path]
		var region := Rect2i(definition[1])
		if not Rect2i(Vector2i.ZERO,source.get_size()).encloses(region):
			failures.append("Atlas region outside source: "+id)
			continue
		var edge_alpha := 0.0
		for x in range(region.position.x,region.end.x):
			edge_alpha = maxf(edge_alpha,maxf(source.get_pixel(x,region.position.y).a,source.get_pixel(x,region.end.y-1).a))
		for y in range(region.position.y,region.end.y):
			edge_alpha = maxf(edge_alpha,maxf(source.get_pixel(region.position.x,y).a,source.get_pixel(region.end.x-1,y).a))
		# Generated sheets can contain a 1/255 trace. No painted silhouette may
		# cross a selected cell boundary; this reads pixels and never changes them.
		if edge_alpha > 2.0/255.0+0.000001:
			failures.append("Painted silhouette crosses atlas boundary: "+id)
