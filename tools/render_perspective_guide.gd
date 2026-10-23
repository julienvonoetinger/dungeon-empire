extends SceneTree
## Builds documentation diagrams only. No game sprites are read or modified.
## Run: godot --headless --path . --script tools/render_perspective_guide.gd

const DIRECTORY := "res://docs/reference/"
var projection: Vector2
var colors: Dictionary

func _initialize() -> void:
	var contract: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "perspective-contract.json"))
	if not contract is Dictionary:
		push_error("Cannot read perspective contract")
		quit(1)
		return
	projection = _point(contract.top_to_foot)
	colors = contract.guide_only_colors
	var svg := _start(int(contract.guide_canvas[0]), int(contract.guide_canvas[1]))
	for module: Dictionary in contract.guide_modules:
		var top: Array[Vector2] = []
		for point: Array in module.top:
			top.append(_point(point) + _point(module.origin))
		svg += _solid(top)
	if not _save("perspective-geometry", svg + "</svg>\n"):
		quit(1)
		return
	if not _save("perspective-room-guide", _room()):
		quit(1)
		return
	print("Rendered perspective geometry and assembled room guides from ", contract.id)
	quit()

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _start(width: int, height: int) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' % [width, height, width, height]

func _polygon(points: Array[Vector2], color: String) -> String:
	var values := PackedStringArray()
	for point: Vector2 in points:
		values.append("%.3f,%.3f" % [point.x, point.y])
	return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="5" stroke-linejoin="round"/>\n' % [" ".join(values), color, colors.outline]

func _face(a: Vector2, b: Vector2, color: String) -> String:
	return _polygon([a, b, b + projection, a + projection], color)

func _solid(top: Array[Vector2]) -> String:
	var faces: Array[Dictionary] = []
	for index: int in top.size():
		var a := top[index]
		var b := top[(index + 1) % top.size()]
		var edge := b - a
		# Clockwise footprint: only front/right faces face the fixed camera.
		if edge.cross(projection) < 0.0:
			faces.append({"depth": maxf(a.y, b.y), "svg": _face(a, b, colors.side if edge.y > 0.0 else colors.front)})
	faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	var svg := ""
	for face: Dictionary in faces:
		svg += face.svg
	return svg + _polygon(top, colors.top)

func _room() -> String:
	var svg := _start(1200, 880)
	svg += '<rect width="1200" height="880" fill="#101620"/>\n'
	# The inner footprint is at ground level, offset from the top contour.
	var inner: Array[Vector2] = [Vector2(214,184), Vector2(986,184), Vector2(986,606), Vector2(214,606)]
	var floor_points: Array[Vector2] = []
	for point: Vector2 in inner:
		floor_points.append(point + projection)
	svg += _polygon(floor_points, colors.floor)
	for x: int in range(310, 986, 96):
		svg += '<path d="M %.3f %.3f V %.3f" fill="none" stroke="#48576e" stroke-width="2"/>\n' % [x + projection.x, 184 + projection.y, 606 + projection.y]
	for y: int in range(264, 606, 80):
		svg += '<path d="M %.3f %.3f H %.3f" fill="none" stroke="#48576e" stroke-width="2"/>\n' % [214 + projection.x, y + projection.y, 986 + projection.x]
	# Inside north/west and outside east/south: the SAME projection everywhere.
	svg += _face(Vector2(986,184), Vector2(214,184), colors.front)
	svg += _face(Vector2(214,184), Vector2(214,606), colors.side)
	svg += _face(Vector2(1050,120), Vector2(1050,670), colors.side)
	svg += _face(Vector2(1050,670), Vector2(150,670), colors.front)
	svg += '<path d="M150 120 H1050 V670 H150 Z M214 184 V606 H986 V184 Z" fill="%s" fill-rule="evenodd" stroke="%s" stroke-width="5" stroke-linejoin="round"/>\n' % [colors.top, colors.outline]
	# Colored construction arrows, not artwork: corresponding top/foot points.
	for start: Vector2 in [Vector2(214,390), Vector2(1050,390), Vector2(600,184), Vector2(600,670)]:
		var finish := start + projection
		svg += '<path d="M %.3f %.3f L %.3f %.3f" fill="none" stroke="#edc971" stroke-width="3"/>\n' % [start.x,start.y,finish.x,finish.y]
		svg += '<circle cx="%.3f" cy="%.3f" r="5" fill="#edc971"/>\n' % [start.x,start.y]
		var back := finish - projection.normalized() * 14.0
		var normal := Vector2(-projection.y, projection.x).normalized() * 5.0
		svg += '<path d="M %.3f %.3f L %.3f %.3f L %.3f %.3f Z" fill="#edc971"/>\n' % [finish.x, finish.y, back.x + normal.x, back.y + normal.y, back.x - normal.x, back.y - normal.y]
	return svg + "</svg>\n"

func _save(stem: String, svg: String) -> bool:
	var file := FileAccess.open(DIRECTORY + stem + ".svg", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write guide SVG: " + stem)
		return false
	file.store_string(svg)
	file.close()
	var rendered := Image.new()
	if rendered.load_svg_from_string(svg) != OK or rendered.save_png(DIRECTORY + stem + ".png") != OK:
		push_error("Cannot render guide PNG: " + stem)
		return false
	return true
