extends SceneTree
const MODEL := preload("res://scripts/dungeon_probes.gd")
const FIXTURES := preload("res://scripts/probe_fixtures.gd")
var scope := "six_rooms"
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(3008,2048)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon: Node2D = scene.get_node("Dungeon")
	var snapshot := MODEL.inspect(dungeon)
	check(snapshot.failures.is_empty(),"All 644 independent placement probes: "+str(snapshot.failures))
	check(dungeon.get_content_rect() == Rect2(0,0,3008,2048),"Composition bounds")
	check(dungeon.layout.get_floor_cells().size() == 255,"255 logical floor cells retained")
	check(dungeon.get_surface_pieces().all(func(p): return p is Sprite2D),"Only complete sprites in production masonry")
	check(snapshot.elements.size() == 858,"855 sprites plus three lights in default composition")
	check(snapshot.probes.size() == 644,"644 independent spatial probes retained")
	check(dungeon.get_node("Heart").position == Vector2(2368,784),"Authored heart placement")
	check(dungeon.get_node("Heart").get_child_count() == 2,"One heart sprite and its static light")
	if scope == "variations":
		await variation_checks(dungeon)
	if scope == "six_rooms":
		for dimensions in [Vector2i(1280,720),Vector2i(720,1280),Vector2i(800,800),Vector2i(640,360)]:
			viewport.size = dimensions
			await process_frame
			await process_frame
			var transform := dungeon.get_global_transform_with_canvas()
			var start := transform*Vector2.ZERO
			var end := transform*Vector2(3008,2048)
			check(start.x >= -1 and start.y >= -1 and end.x <= dimensions.x+1 and end.y <= dimensions.y+1,"Camera fits "+str(dimensions))
			check(is_equal_approx(transform.x.length(),transform.y.length()),"Camera preserves aspect")
		viewport.size = Vector2i(3008,2048)
		await process_frame
		await process_frame
	if "--gpu" in OS.get_cmdline_user_args():
		await gpu_checks(dungeon,viewport,scene)
	viewport.queue_free()
	await process_frame
	for failure in failures:
		push_error("FAIL: "+failure)
	print("Alpha ",scope," checks: ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func variation_checks(dungeon: Node2D) -> void:
	var heart := dungeon.get_node("Heart")
	var baseline := signature(dungeon)
	dungeon._rebuild()
	check(signature(dungeon) == baseline,"Rebuild is deterministic")
	dungeon.variation_seed = 590
	dungeon._rebuild()
	check(signature(dungeon) != baseline,"Seed changes actual art/tint")
	dungeon.variation_seed = 173
	dungeon._rebuild()
	check(signature(dungeon) == baseline,"Seed restore restores exact sprite arrangement")
	dungeon.stone_variation = false
	dungeon._rebuild()
	check(signature(dungeon) != baseline,"Variation off changes art")
	check(MODEL.inspect(dungeon).failures.is_empty(),"Variation off preserves coverage")
	dungeon.stone_variation = true
	dungeon._rebuild()
	check(signature(dungeon) == baseline,"Variation restored")
	check(dungeon.get_node("Heart") == heart,"Authored heart survives")

func signature(dungeon: Node2D) -> Array:
	var result: Array = []
	for part: Sprite2D in dungeon.get_surface_pieces():
		result.append([part.name,part.get_meta("asset_id"),part.position,part.scale,part.self_modulate])
	return result

func gpu_checks(dungeon: Node2D,viewport: SubViewport,scene: Node2D) -> void:
	for e in MODEL.inspect(dungeon).elements:
		if e.kind == "light":
			e.node.enabled = false
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var elements: Array = MODEL.inspect(dungeon).elements.filter(func(e): return e.node is Sprite2D)
	for i in range(elements.size()):
		elements[i]["draw_order"] = i
	elements.sort_custom(func(a,b): return a.draw_order < b.draw_order if a.z == b.z else a.z < b.z)
	var points: Array[Vector2] = []
	if scope == "six_rooms":
		points.append_array(FIXTURES.floor_points(dungeon))
		points.append_array(FIXTURES.side_points())
		points.append_array(FIXTURES.volume_points())
	elif scope == "entry_seams":
		for y in range(265,492,7):
			for x in range(190,1000,7):
				points.append(Vector2(x,y))
	elif scope == "heart":
		for y in range(624,888,5):
			for x in range(2235,2500,5):
				points.append(Vector2(x,y))
	var worst := 0.0
	var bad := 0
	for point in points:
		var expected := Color("080e19")
		for e: Dictionary in elements:
			if not e.visible or not e.bounds.has_point(point+Vector2(0.5,0.5)):
				continue
			var uv: Vector2 = MODEL._uv_at(e,point+Vector2(0.5,0.5))
			var paint: Color = linear_sample(e.alpha_image,uv)*e.tint
			expected = expected.lerp(Color(paint.r,paint.g,paint.b,1),paint.a)
		var actual := image.get_pixelv(Vector2i(point))
		var error := maxf(absf(actual.r-expected.r),maxf(absf(actual.g-expected.g),absf(actual.b-expected.b)))
		worst = maxf(worst,error)
		if error > 4.0/255.0:
			bad += 1
			if bad < 8:
				print("PIXEL ",point," actual ",actual," expected ",expected)
	check(bad == 0,"GPU native RGBA blend: "+str(bad)+" mismatches out of "+str(points.size())+"; max "+str(worst*255)+"/255")
	print("GPU ",scope," samples ",points.size()," max error ",worst*255,"/255")
	var report := {"scope":scope,"samples":points.size(),"failures":bad,"max_error_255":worst*255,"limit":"Pixel probes do not replace visual seam inspection"}
	var file := FileAccess.open("res://artifacts/"+("entry-seams-report" if scope == "entry_seams" else "alpha-"+scope+"-report")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	if scope == "heart":
		for e in MODEL.inspect(dungeon).elements:
			if e.kind == "light": e.node.enabled = true
		var camera: Camera2D = scene.get_node("Camera2D")
		viewport.size = Vector2i(640,600)
		await process_frame
		camera.position = Vector2(2368,752)
		camera.zoom = Vector2.ONE*2
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/heart-detail.png")

func linear_sample(image: Image,uv: Vector2) -> Color:
	var point := uv-Vector2(0.5,0.5)
	var start := Vector2i(point.floor())
	var fraction := point-Vector2(start)
	var colors: Array[Color] = []
	for d in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
		var p: Vector2i = start+d
		# Texture sampling clamps to the transparent padding of a whole sprite.
		p.x = clampi(p.x,0,image.get_width()-1)
		p.y = clampi(p.y,0,image.get_height()-1)
		colors.append(image.get_pixelv(p))
	return colors[0].lerp(colors[1],fraction.x).lerp(colors[2].lerp(colors[3],fraction.x),fraction.y)

func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
