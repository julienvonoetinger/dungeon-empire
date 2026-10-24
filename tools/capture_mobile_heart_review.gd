extends SceneTree
## User-requested visual trials and focused placement/occlusion checks.
const REVIEW = preload("res://tools/mobile_heart_review.gd")
const OUTPUT := "res://docs/reference/mobile-heart-review/"
var viewport: SubViewport
var checks: Array[Dictionary] = []
var captures: Array[String] = []
var failures := 0
var output := OUTPUT
var definition_path := OUTPUT + "prepared.json"

func _initialize() -> void:
	_run.call_deferred()

func _check(label: String, passed: bool) -> void:
	checks.append({"check":label,"passed":passed})
	if not passed:
		failures += 1
		push_error(label)

func _capture(id: String, density: int, placement: String, location: Vector2) -> void:
	var study = REVIEW.create_study(id,density,location,definition_path)
	viewport.add_child(study)
	study.build()
	_check("%s-%d-%s: texture loaded" % [id,density,placement],study.heart_texture!=null)
	if study.heart_texture == null:
		viewport.remove_child(study)
		study.free()
		return
	var camera := Camera2D.new()
	camera.position = Vector2(256,256)
	camera.zoom = Vector2.ONE * .75
	viewport.add_child(camera)
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var file := "%s-%d-%s.png" % [id,density,placement]
	var result := viewport.get_texture().get_image().save_png(output + "captures/" + file)
	_check(file+": capture saved",result==OK)
	captures.append(file)
	var sprite: Sprite2D = study.get_node("PreparedSprites/ReviewHeart")
	_check(file+": complete prepared texture",sprite.texture.get_size()==Vector2(study.texture_info.size[0],study.texture_info.size[1]))
	_check(file+": uniform scale",is_equal_approx(sprite.scale.x,sprite.scale.y))
	_check(file+": no sprite rotation",is_zero_approx(sprite.rotation))
	_check(file+": fixed camera",camera.zoom==Vector2(.75,.75))
	var heart_index := -1
	for i in study.order_report.size():
		if study.order_report[i].id == "review-heart":
			heart_index = i
	if placement in ["north","south"]:
		var intersections := 0
		for i in study.order_report.size():
			var entry: Dictionary = study.order_report[i]
			var wall_y := 0 if placement=="north" else 2
			if str(entry.id).begins_with("wall-h-") and is_equal_approx(float(entry.at[1]),float(wall_y)) and entry.overlaps_heart:
				intersections += 1
				_check(file+": heart/wall draw order "+str(i),i<heart_index if placement=="north" else i>heart_index)
		_check(file+": meaningful wall overlap",intersections>0)
	viewport.remove_child(study)
	study.free()
	viewport.remove_child(camera)
	camera.free()

func _run() -> void:
	var ids := ["a","b","c"]
	var north_y := .42
	var south_y := 1.62
	var ritual := OS.get_cmdline_user_args().has("--ritual-v3")
	if ritual or OS.get_cmdline_user_args().has("--perspective-v2"):
		output = OUTPUT + ("ritual-v3/" if ritual else "perspective-v2/")
		definition_path = output + "prepared.json"
		ids = ["a"]
		north_y = .52
		south_y = 1.48
	DirAccess.make_dir_recursive_absolute(output+"captures")
	viewport = SubViewport.new()
	viewport.size = Vector2i(420,500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for id: String in ids:
		for density in [256,128]:
			await _capture(id,density,"center",Vector2.ONE)
		for trial: Array in [["north",Vector2(1,north_y)],["south",Vector2(1,south_y)],["west",Vector2(.52,1)],["east",Vector2(1.48,1)]]:
			await _capture(id,256,trial[0],trial[1])
	_check("All requested trials completed",captures.size()==ids.size()*6)
	_check("All trial checks executed",checks.size()>=ids.size()*36)
	var file := FileAccess.open(output+"godot-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":captures,"checks":checks,"failures":failures,"scope":"Visual proposals and isolated support-depth checks, not production promotion or device profiling."},"\t")+"\n")
	print("Heart review: ",captures.size()," captures, ",checks.size()," checks, ",failures," failures.")
	quit(1 if failures else 0)
