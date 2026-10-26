extends RefCounted
## Static cut geometry. Called only when excavated cell occupancy changes.
const MARGIN := .90
const EXTENT := Rect2(-24, -24, 64, 64)

static func _unique(values: Array) -> Array:
	var result: Array = []
	for value in values:
		var rounded := snappedf(float(value), .00001)
		if not result.has(rounded): result.append(rounded)
	result.sort()
	return result

static func _hash_at(p: Vector2) -> float:
	var value := sin(p.x * 127.1 + p.y * 311.7 + 17.3) * 43758.5453
	return value - floor(value)

static func build(cells: Array[Vector2i]) -> Dictionary:
	var rects: Array[Rect2] = []
	var xv: Array = []
	var yv: Array = []
	for cell in cells:
		var r := Rect2(Vector2(cell) - Vector2.ONE * MARGIN, Vector2.ONE * (1 + 2 * MARGIN))
		rects.append(r)
		xv.append_array([r.position.x, r.end.x]); yv.append_array([r.position.y, r.end.y])
	var xs := _unique(xv)
	var ys := _unique(yv)
	var inside := {}
	for x in range(xs.size() - 1):
		for y in range(ys.size() - 1):
			var midpoint := Vector2((xs[x] + xs[x+1]) * .5, (ys[y] + ys[y+1]) * .5)
			for r in rects:
				if r.has_point(midpoint):
					inside[Vector2i(x,y)] = true
					break
	var links := {}
	for p: Vector2i in inside:
		var corners := [Vector2(xs[p.x],ys[p.y]),Vector2(xs[p.x+1],ys[p.y]),Vector2(xs[p.x+1],ys[p.y+1]),Vector2(xs[p.x],ys[p.y+1])]
		var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
		for i in 4:
			if not inside.has(p + dirs[i]): links[corners[i]] = corners[(i+1)%4]
	var contours: Array[PackedVector2Array] = []
	while not links.is_empty():
		var start: Vector2 = links.keys()[0]
		var p := start
		var raw: Array[Vector2] = []
		while links.has(p):
			raw.append(p)
			var next: Vector2 = links[p]
			links.erase(p); p = next
			if p == start: break
		var simple: Array[Vector2] = []
		for i in raw.size():
			if absf((raw[i]-raw[posmod(i-1,raw.size())]).cross(raw[(i+1)%raw.size()]-raw[i])) > .000001: simple.append(raw[i])
		var bevel: Array[Vector2] = []
		for i in simple.size():
			var a := simple[posmod(i-1,simple.size())]
			var b := simple[(i+1)%simple.size()]
			p = simple[i]
			var distance := minf(.12, minf(p.distance_to(a),p.distance_to(b)) * .20)
			bevel.append(p + p.direction_to(a) * distance)
			bevel.append(p + p.direction_to(b) * distance)
		var contour := PackedVector2Array()
		for i in bevel.size():
			var a := bevel[i]
			var b := bevel[(i+1)%bevel.size()]
			var steps := maxi(1, ceili(a.distance_to(b) / .48))
			contour.append(a)
			for k in range(1,steps):
				p = a.lerp(b,float(k)/steps)
				var direction := a.direction_to(b)
				contour.append(p + Vector2(direction.y,-direction.x) * (_hash_at(p*31)-.5)*.045)
		contours.append(contour)
	var top: Array[PackedVector2Array] = []
	# Narrow strips ensure subtraction returns simple polygons, never a polygon
	# containing an unrepresentable interior hole. Islands are added separately.
	for x in range(int(EXTENT.position.x * 2), int(EXTENT.end.x * 2)):
		var a := x * .5
		var pieces: Array[PackedVector2Array] = [PackedVector2Array([Vector2(a,EXTENT.position.y),Vector2(a+.5,EXTENT.position.y),Vector2(a+.5,EXTENT.end.y),Vector2(a,EXTENT.end.y)])]
		for contour in contours:
			if Geometry2D.is_polygon_clockwise(contour): continue
			var remaining: Array[PackedVector2Array] = []
			for piece in pieces: remaining.append_array(Geometry2D.clip_polygons(piece,contour))
			pieces = remaining
		top.append_array(pieces)
	for contour in contours:
		if Geometry2D.is_polygon_clockwise(contour): top.append(contour)
	return {"contours":contours,"top":top}
