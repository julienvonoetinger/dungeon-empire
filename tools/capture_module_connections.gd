extends SceneTree

## Actual rendered construction/rebuild scenarios. No artistic scores or probes.
const PREFIX := "res://artifacts/connections/"

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREFIX))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/3x3RoomFourCorridors.tscn").instantiate()
	viewport.add_child(scene)
	var dungeon = scene.get_node("Dungeon")
	var initial_length: int = dungeon.corridor_length
	var initial_vertical_length: int = dungeon.vertical_corridor_length
	var paths: Array[String] = []
	var labels: Array[String] = []
	for mask in range(16):
		dungeon.connections = mask
		await process_frame
		await process_frame
		var path := PREFIX + "mask-%02d.png" % mask
		await _save(viewport, dungeon, path)
		paths.append(path)
		var active: Array[String] = []
		for side in [[1,"N"],[2,"E"],[4,"S"],[8,"W"]]:
			if mask & side[0]:
				active.append(side[1])
		labels.append("%02d — " % mask + ("Closed" if active.is_empty() else "/".join(active)))
	await _gallery(paths, labels, 4, Vector2i(420,280), "connection-masks-comparison")
	paths.clear()
	labels.clear()
	dungeon.connections = 15
	dungeon.vertical_corridor_length = 0
	for length in [1,2,3]:
		dungeon.corridor_length = length
		await process_frame
		await process_frame
		var path := PREFIX + "length-%d.png" % length
		await _save(viewport, dungeon, path)
		paths.append(path)
		labels.append("Length %d — N/E/S/W" % length)
	await _gallery(paths, labels, 3, Vector2i(520,360), "connection-lengths-comparison")
	# Return the SAME instance through closed -> four-way at the initial length.
	dungeon.corridor_length = initial_length
	dungeon.vertical_corridor_length = initial_vertical_length
	dungeon.connections = 0
	await process_frame
	await process_frame
	dungeon.connections = 15
	await process_frame
	await process_frame
	await _save(viewport, dungeon, PREFIX + "rebuild-roundtrip.png")
	viewport.queue_free()
	await process_frame
	var baseline := await _wall_detail("2x1Corridor", "wall-profile-reference-4x")
	var connected := await _wall_detail("3x3RoomFourCorridors", "wall-profile-connected-4x")
	await _gallery([baseline,connected], ["2x1Corridor — original profile", "Connected corridor — shared profile"],
		2, Vector2i(820,700), "wall-profile-shared-comparison")
	var before := "res://artifacts/3x3RoomFourCorridors-before-shared-east-4x.png"
	var after := "res://artifacts/3x3RoomFourCorridors-east-4x.png"
	if FileAccess.file_exists(before) and FileAccess.file_exists(after):
		await _gallery([before,after], ["Before — detached square", "Current — dedicated L transitions"],
			2, Vector2i(820,960), "junction-perspective-comparison")
	var before_continuity := "res://artifacts/3x3RoomFourCorridors-before-continuity-west-4x.png"
	var current_continuity := "res://artifacts/3x3RoomFourCorridors-west-4x.png"
	if FileAccess.file_exists(before_continuity) and FileAccess.file_exists(current_continuity):
		await _gallery([before_continuity,current_continuity],
			["Avant — petites entretoises, angles gris", "Actuel — branches continues, pierre bleue"],
			2, Vector2i(820,960), "junction-continuity-comparison")
	var before_profile := "res://artifacts/3x3RoomFourCorridors-before-profile-west-4x.png"
	if FileAccess.file_exists(before_profile) and FileAccess.file_exists(current_continuity):
		await _gallery([before_profile,current_continuity],
			["Avant — marches et rebords", "Actuel — profils nord/sud, facade arretee aux angles"],
			2, Vector2i(820,960), "junction-profile-comparison")
	for detail in [["west-lower-return","junction-native-parts-comparison"],["north-side","vertical-material-comparison"]]:
		var before_detail: String = "res://artifacts/3x3RoomFourCorridors-before-native-edges-" + detail[0] + "-4x.png"
		var after_detail: String = "res://artifacts/3x3RoomFourCorridors-" + detail[0] + "-4x.png"
		if FileAccess.file_exists(before_detail) and FileAccess.file_exists(after_detail):
			await _gallery([before_detail,after_detail],
				["Avant — anciens sprites", "Actuel — modules natifs et matiere partagee"],
				2,Vector2i(820,700),detail[1])
	var return_paths: Array[String] = []
	var return_labels: Array[String] = []
	for side in ["west-upper-return","east-upper-return","west-lower-return","east-lower-return"]:
		return_paths.append("res://artifacts/3x3RoomFourCorridors-" + side + "-4x.png")
		return_labels.append(side + " — x4")
	await _gallery(return_paths,return_labels,2,Vector2i(820,700),"junction-all-returns")
	for detail in ["west-upper-return","west-lower-return","north","south"]:
		var before_ports: String = "res://artifacts/before-port-widths/3x3RoomFourCorridors-" + detail + "-4x.png"
		var after_ports: String = "res://artifacts/3x3RoomFourCorridors-" + detail + "-4x.png"
		if FileAccess.file_exists(before_ports):
			await _gallery([before_ports,after_ports], ["Avant — largeurs et centres incompatibles", "Actuel — ports calibres et composition partagee"],
				2,Vector2i(820,960 if detail in ["north","south"] else 700),"junction-ports-" + detail + "-comparison")
	print("Visual rebuild captures: all 16 connection masks, lengths 1/2/3, same-instance roundtrip, 2x1 wall comparison.")
	quit()

func _save(viewport: SubViewport, dungeon: Node2D, path: String) -> void:
	var frame: Rect2 = dungeon.get_content_rect()
	viewport.size = Vector2i(frame.size)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png(path)

func _wall_detail(scene_name: String, filename: String) -> String:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(800,640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node2D = load("res://scenes/" + scene_name + ".tscn").instantiate()
	viewport.add_child(scene)
	await process_frame
	var dungeon = scene.get_node("Dungeon")
	var camera: Camera2D = scene.get_node("Camera2D")
	if scene_name == "2x1Corridor":
		var cap: Rect2 = dungeon.get_cap_rect()
		camera.position = cap.position + Vector2(476,120) * 0.29
	else:
		camera.position = dungeon.get_regression_detail_centers()["corridor-wall-foot"]
	camera.zoom = Vector2.ONE * 4
	camera.force_update_scroll()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/" + filename + ".png"
	viewport.get_texture().get_image().save_png(path)
	viewport.queue_free()
	await process_frame
	return path

func _gallery(paths: Array, labels: Array, columns: int, panel: Vector2i, filename: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(columns * panel.x, ceili(float(paths.size()) / columns) * panel.y)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for index in range(paths.size()):
		var texture := ImageTexture.create_from_image(Image.load_from_file(paths[index]))
		var sprite := Sprite2D.new()
		sprite.texture = texture
		var origin := Vector2(index % columns, int(index / columns)) * Vector2(panel)
		var area := Vector2(panel) - Vector2(20,60)
		var factor := minf(1.0, minf(area.x / texture.get_width(), area.y / texture.get_height()))
		sprite.scale = Vector2.ONE * factor
		sprite.position = origin + Vector2(panel.x * 0.5, 40 + area.y * 0.5)
		viewport.add_child(sprite)
		var label := Label.new()
		label.text = labels[index]
		label.position = origin + Vector2(12,8)
		label.add_theme_font_size_override("font_size", 18)
		viewport.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://artifacts/" + filename + ".png")
	viewport.queue_free()
	await process_frame
