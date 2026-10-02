extends RefCounted

const SPACING := 1.55
static var _patches: Dictionary = {}

static func _site(key: Vector2i) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("geology:" + str(key))
	return (Vector2(key) + Vector2(0.5 + rng.randf_range(-0.42, 0.42), 0.5 + rng.randf_range(-0.42, 0.42))) * SPACING

# Convex half-plane clipping keeps the geological pattern independent of tiles.
static func clip(points: Array[Vector2], normal: Vector2, distance: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if points.is_empty():
		return result
	var previous: Vector2 = points[-1]
	var before := previous.dot(normal) - distance
	for current in points:
		var after := current.dot(normal) - distance
		if (before <= 0.0) != (after <= 0.0):
			result.append(previous.lerp(current, before / (before - after)))
		if after <= 0.0:
			result.append(current)
		previous = current
		before = after
	return result

static func patch(key: Vector2i) -> Dictionary:
	if _patches.has(key):
		return _patches[key]
	var site := _site(key)
	var extent := SPACING * 3.0
	var polygon: Array[Vector2] = [site + Vector2(-extent, -extent), site + Vector2(extent, -extent), site + Vector2(extent, extent), site + Vector2(-extent, extent)]
	for y in range(-2, 3):
		for x in range(-2, 3):
			if x == 0 and y == 0:
				continue
			var other := _site(key + Vector2i(x, y))
			var normal := (other - site).normalized()
			polygon = clip(polygon, normal, ((site + other) * 0.5).dot(normal) - 0.045)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("strata:" + str(key))
	var polygons: Array = [polygon]
	for i in (1 if rng.randf() < 0.20 else 0):
		var candidate: Array[Vector2] = polygons.pop_front()
		var angle := rng.randf_range(0, TAU)
		var normal := Vector2(cos(angle), sin(angle))
		var center := Vector2.ZERO
		for point in candidate:
			center += point
		center /= candidate.size()
		var distance := center.dot(normal) + rng.randf_range(-0.15, 0.15)
		var left := clip(candidate, normal, distance - 0.025)
		var right := clip(candidate, -normal, -distance - 0.025)
		if left.size() >= 3 and right.size() >= 3:
			polygons.append(left)
			polygons.append(right)
		else:
			polygons.append(candidate)
	var pieces: Array[Dictionary] = []
	for shape in polygons:
		var chipped: Array[Vector2] = []
		var center := Vector2.ZERO
		for point in shape:
			center += point
		center /= shape.size()
		for edge in shape.size():
			var a: Vector2 = shape[edge]
			var b: Vector2 = shape[(edge + 1) % shape.size()]
			var count := maxi(3, ceili(a.distance_to(b) / 0.25))
			for j in count:
				var point := a.lerp(b, float(j) / count)
				chipped.append(point.move_toward(center, rng.randf_range(0.01, 0.065)))
		var height := rng.randf_range(0.28, 0.46) if rng.randf() < 0.22 else rng.randf_range(0.68, 0.90)
		pieces.append({"polygon": chipped, "outline": chipped, "height": height, "slope": Vector2(rng.randf_range(-0.025, 0.025), rng.randf_range(-0.025, 0.025)), "site": site, "tint": Color("8c939e") * rng.randf_range(0.87, 1.05)})
	var value := {"pieces": pieces}
	_patches[key] = value
	return value

static func fragments(low: Vector2, high: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var first := Vector2i(floori(low.x / SPACING) - 1, floori(low.y / SPACING) - 1)
	var last := Vector2i(floori(high.x / SPACING) + 1, floori(high.y / SPACING) + 1)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var source := patch(Vector2i(x, y))
			for piece in source.pieces:
				var polygon: Array[Vector2] = piece.polygon
				polygon = clip(polygon, Vector2.LEFT, -low.x)
				polygon = clip(polygon, Vector2.RIGHT, high.x)
				polygon = clip(polygon, Vector2.UP, -low.y)
				polygon = clip(polygon, Vector2.DOWN, high.y)
				if polygon.size() >= 3:
					var fragment: Dictionary = piece.duplicate()
					fragment.polygon = polygon
					result.append(fragment)
	return result
