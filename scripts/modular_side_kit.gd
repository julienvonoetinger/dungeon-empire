extends RefCounted

## Whole generated overhead stones. Regions include complete source gutters.
const TEXTURE := preload("res://assets/dungeon/modular-study/wall-tops-ports-v12.png")
const SMALL := preload("res://assets/dungeon/modular-study/cap-elbows-flush-v9.png")
const REGIONS := [Rect2(0,0,627,627), Rect2(627,0,627,627), Rect2(0,627,627,627), Rect2(627,627,627,627), Rect2(365,435,525,380)]
const ANCHORS := [Vector2(262,62), Vector2(237,165), Vector2(262,86), Vector2(237,29), Vector2(153,138)]
const BODIES := [Vector2(152,510), Vector2(153,300), Vector2(152,422), Vector2(153,521), Vector2(219,111)]

static func _stone(index: int) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = SMALL if index == 4 else TEXTURE
	atlas.region = REGIONS[index]
	atlas.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.offset = -ANCHORS[index]
	return sprite

static func legacy_pair(east: bool, scale: float) -> Sprite2D:
	# Preserve the original study's two-stone cadence, height and center line.
	var factor := 315.0 / BODIES[0].y
	var width := BODIES[0].x * factor
	var center := -41.0 if east else 41.0
	var sprite := _stone(0)
	sprite.offset += Vector2((center - width * 0.5) / factor,-15.0 / factor)
	sprite.scale = Vector2.ONE * scale * factor
	sprite.set_meta("asset_id", "east" if east else "west")
	return sprite

static func make_run(left: float, top: float, bottom: float, art_scale: float, target_width: float = 94.0) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	var length := bottom - top
	if length <= 2:
		return result
	# Fit a composition of native lengths, rather than changing stone width
	# dramatically as a run gets longer. Every piece is scaled uniformly.
	var selected: Array[int] = []
	var total := 0.0
	var best_error := INF
	# The shallow plate is a short terminal sprite, never a long wall cadence.
	var candidates := BODIES.size() if length < target_width * 1.5 else BODIES.size() - 1
	for first in range(candidates):
		var first_height: float = BODIES[first].y * target_width / BODIES[first].x
		for second in range(first,candidates):
			var second_height: float = BODIES[second].y * target_width / BODIES[second].x
			for count in range(ceili(length / first_height) + 2):
				var other := maxi(0,roundi((length - count * first_height) / second_height))
				if count + other == 0:
					continue
				var height := count * first_height + other * second_height
				var error := absf(height - length) + 0.05 * (count + other)
				if error < best_error:
					best_error = error
					total = height
					selected.clear()
					for unused in range(count):
						selected.append(first)
					for unused in range(other):
						selected.append(second)
	var fit := length / total
	var width := target_width * fit
	var cursor := top
	for index in selected:
		var factor: float = target_width / BODIES[index].x * fit
		var sprite := _stone(index)
		sprite.position = Vector2(left + 41.0 - width * 0.5,cursor) * art_scale
		sprite.scale = Vector2.ONE * art_scale * factor
		sprite.z_index = 3
		sprite.set_meta("asset_id", "side_top_" + str(index))
		result.append(sprite)
		cursor += BODIES[index].y * factor
	return result
