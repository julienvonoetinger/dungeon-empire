extends SceneTree
## Focused rendered checks for accepted light, floor clipping and torch independence.
const OUT := "res://docs/reference/isometric-review/painted-v1/heart-self-light-v1/integration/"
const RENDERER := preload("res://scripts/mobile_dungeon_renderer.gd")
var viewport: SubViewport
var observations: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _effects(dungeon: Node2D) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for child in dungeon.get_node("PreparedSprites").get_children():
		if child is Sprite2D and child.get_meta("self_light",false):
			result.append(child)
	return result

func _save(name: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image.save_png(OUT+name+".png") != OK:
		failures.append("Cannot save "+name)
	return image

func _observe(name: String, dungeon: Node2D, count: int) -> String:
	var effects := _effects(dungeon)
	if effects.size() != count:
		failures.append(name+": expected %d effects, found %d" % [count,effects.size()])
	var signature := []
	for effect in effects:
		var texture: AtlasTexture = effect.texture
		var receiving: Dictionary = effect.get_meta("receiving")
		signature.append({"region":[texture.region.position.x,texture.region.position.y,texture.region.size.x,texture.region.size.y],
			"position":[effect.position.x,effect.position.y],"scale":[effect.scale.x,effect.scale.y],
			"origin":[receiving.origin.x,receiving.origin.y],"mask":receiving.bits,"clip":receiving.enabled})
	observations.append({"case":name,"effects":signature})
	return JSON.stringify(signature)

func _scene(name: String, at: Vector2) -> Node2D:
	var scene: Node2D = load("res://scenes/"+name+".tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position = scene.get_node("Dungeon").grid_to_local(at)
	camera.zoom = Vector2.ONE*.75
	camera.force_update_scroll()
	return scene

func _remove(scene: Node2D) -> void:
	viewport.remove_child(scene)
	scene.free()

func _edge_case(name: String, specials: Dictionary, hearts: PackedVector2Array) -> void:
	var dungeon := RENDERER.new()
	viewport.add_child(dungeon)
	var cells := {}
	for y in range(-2,2):
		for x in range(-2,2):
			cells[Vector2i(x,y)] = true
	cells.erase(Vector2i(-2,1))
	dungeon.render_plan({"cells":cells,"openings":{},"hearts":hearts},specials,false)
	var camera := Camera2D.new()
	camera.zoom = Vector2.ONE*.75
	camera.position = dungeon.grid_to_local(hearts[0])
	viewport.add_child(camera)
	camera.force_update_scroll()
	var initial := _observe(name,dungeon,hearts.size()*2)
	await _save(name)
	# Rebuild once: no duplicates or drifting uniforms.
	dungeon.render_plan({"cells":cells,"openings":{},"hearts":hearts},specials,false,false)
	if _observe(name+"-rebuilt",dungeon,hearts.size()*2) != initial:
		failures.append(name+": rebuild changed effects")
	for child in dungeon.get_node("PreparedSprites").get_children():
		if child is CanvasItem and not child.get_meta("self_light",false):
			child.visible = false
	viewport.transparent_bg = true
	var image := await _save(name+"-effects-only")
	var outside := 0
	var visible := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a <= 0:
				continue
			visible += 1
			var screen := camera.position+(Vector2(x+.5,y+.5)-Vector2(viewport.size)*.5)/.75
			var point := dungeon.local_to_grid(screen)
			var cell := Vector2i(floori(point.x),floori(point.y))
			var fraction := point-Vector2(cell)
			# Ignore the subpixel raster edge, not entire neighbouring floor cells.
			var near_edge := minf(minf(fraction.x,1-fraction.x),minf(fraction.y,1-fraction.y)) < .015
			if (not cells.has(cell) or specials.has(cell)) and not near_edge:
				outside += 1
	observations.append({"case":name+"-clip","visible_pixels":visible,"outside_receiving_floor":outside})
	if outside != 0 or visible == 0:
		failures.append(name+": invalid floor mask, outside=%d visible=%d" % [outside,visible])
	viewport.transparent_bg = false
	_remove(dungeon)
	viewport.remove_child(camera)
	camera.free()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	viewport = SubViewport.new()
	viewport.size = Vector2i(640,420)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := await _scene("DungeonPreview",Vector2(12,14))
	_observe("dungeon-preview",scene.get_node("Dungeon"),2)
	await _save("dungeon-preview")
	_remove(scene)
	scene = await _scene("MobileReference",Vector2(1.5,1))
	var dungeon: Node2D = scene.get_node("Dungeon")
	var original := _observe("torches-on",dungeon,2)
	await _save("torches-on")
	dungeon.torch_lights_enabled = false
	await process_frame
	await process_frame
	if _observe("torches-off",dungeon,2) != original:
		failures.append("Torch toggle changed self-light")
	await _save("torches-off")
	dungeon.torch_lights_enabled = true
	var north: Array[Vector2i] = [Vector2i(0,0)]
	var west: Array[Vector2i] = []
	dungeon.torch_north_cells = north
	dungeon.torch_west_cells = west
	await process_frame
	await process_frame
	if _observe("torches-moved",dungeon,2) != original:
		failures.append("Torch placement changed self-light")
	await _save("torches-moved")
	_remove(scene)
	await _edge_case("edge-negative",{},PackedVector2Array([Vector2(-1.55,-.5)]))
	await _edge_case("special-neighbour",{Vector2i(-1,0):"stairs/north"},PackedVector2Array([Vector2(-1.55,-.5)]))
	await _edge_case("multiple-hearts",{},PackedVector2Array([Vector2(-1.55,-.5),Vector2(.75,.75)]))
	var standalone: Node2D = load("res://scenes/DungeonHeart.tscn").instantiate()
	viewport.add_child(standalone)
	await process_frame
	_observe("standalone",standalone,2)
	for effect in _effects(standalone):
		if effect.get_meta("receiving").enabled:
			failures.append("Standalone preview unexpectedly clipped")
	_remove(standalone)
	var output := FileAccess.open(OUT+"observations.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"observations":observations,"failures":failures},"\t")+"\n")
	print("Self-light checks: ",failures.size()," failures. ",failures)
	quit(0 if failures.is_empty() else 1)
