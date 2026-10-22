extends RefCounted

## Complete native-alpha sprites; fixed shaft width, never fitted by widening.
const CAPS := preload("res://assets/dungeon/modular-study/cap-tight-v13.png")
const SHORTS := preload("res://assets/dungeon/modular-study/wall-tight-v22.png")
const LENGTHS := preload("res://assets/dungeon/modular-study/wall-tight-v23.png")
const COMPACT := preload("res://assets/dungeon/modular-study/cap-compact-pairs-v24.png")
const SMALL := preload("res://assets/dungeon/modular-study/cap-elbows-muted-v10.png")
const SOURCES := [CAPS, CAPS, SHORTS, SHORTS, SHORTS, SHORTS, LENGTHS, LENGTHS, LENGTHS, LENGTHS, COMPACT, COMPACT, SMALL]
const REGIONS := [Rect2(0,435,365,380), Rect2(890,435,364,380), Rect2(0,0,627,627), Rect2(627,0,627,627), Rect2(0,627,627,627), Rect2(627,627,627,627), Rect2(0,0,627,550), Rect2(627,0,627,550), Rect2(0,550,627,704), Rect2(627,550,627,704), Rect2(50,450,230,350), Rect2(980,450,250,350), Rect2(365,435,525,380)]
const ANCHORS := [Vector2(103,20), Vector2(147,20), Vector2(240,257), Vector2(168,169), Vector2(248,87), Vector2(168,23), Vector2(240,202), Vector2(167,184), Vector2(246,73), Vector2(167,64), Vector2(46,52), Vector2(71,52), Vector2(153,138)]
const BODIES := [Vector2(117,347), Vector2(118,348), Vector2(248,236), Vector2(232,324), Vector2(220,385), Vector2(232,449), Vector2(251,276), Vector2(237,294), Vector2(239,484), Vector2(236,495), Vector2(113,265), Vector2(115,267), Vector2(219,111)]
const PAIRED_INDICES := [0, 1, 10, 11]
const STEP := 0.25

static func _stone(index: int) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = SOURCES[index]
	atlas.region = REGIONS[index]
	atlas.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.offset = -ANCHORS[index]
	return sprite

static func make_run(left: float, top: float, bottom: float, art_scale: float, target_width: float = 94.0) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	var length := bottom - top
	if length <= 2.0:
		return result
	# Whole native lengths fill the span at the corner's width. The old final
	# height fit also changed width and made identical side walls inconsistent.
	var slots := ceili(length / STEP) + 1
	var costs := PackedFloat64Array()
	var heights := PackedFloat64Array()
	var counts := PackedInt32Array()
	var previous := PackedInt32Array()
	var choices := PackedInt32Array()
	costs.resize(slots)
	costs.fill(INF)
	heights.resize(slots)
	counts.resize(slots)
	previous.resize(slots)
	choices.resize(slots)
	choices.fill(-1)
	costs[0] = 0.0
	for state in range(slots):
		if is_inf(costs[state]):
			continue
		for index in range(BODIES.size()):
			if index == BODIES.size() - 1 and length >= target_width * 1.5:
				continue
			var height: float = heights[state] + BODIES[index].y * target_width / BODIES[index].x
			if height > length:
				continue
			var next := ceili(height / STEP)
			# Jointed pairs also cover compact spans without isolated filler squares.
			var cost := costs[state] + (2.0 if index in PAIRED_INDICES else 5.0)
			if choices[state] == index:
				cost += 0.15
			if cost < costs[next]:
				costs[next] = cost
				heights[next] = height
				counts[next] = counts[state] + 1
				previous[next] = state
				choices[next] = index
	var best := 0
	var best_score := INF
	for state in range(1,slots):
		if is_inf(costs[state]):
			continue
		var joint := (length - heights[state]) / (counts[state] + 1)
		var score := costs[state] + maxf(0.0,joint - 2.0) * 100.0 + joint * 0.1
		if score < best_score:
			best_score = score
			best = state
	if best == 0:
		return result
	var selected: Array[int] = []
	var state := best
	while state > 0:
		selected.push_front(choices[state])
		state = previous[state]
	var gap := (length - heights[best]) / (selected.size() + 1)
	var cursor := top + gap
	for index in selected:
		var factor: float = target_width / BODIES[index].x
		var sprite := _stone(index)
		sprite.position = Vector2(left + 41.0 - target_width * 0.5,cursor) * art_scale
		sprite.scale = Vector2.ONE * art_scale * factor
		sprite.z_index = 3
		sprite.set_meta("asset_id", "side_top_" + str(index))
		result.append(sprite)
		cursor += BODIES[index].y * factor + gap
	return result
