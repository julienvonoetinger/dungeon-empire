@tool
extends Node2D

## Rectangular room and passage studies share whole native-alpha assets.
## No entrance, collision, probes or procedural topology is implemented here.
signal rebuilt
const KIT := preload("res://scripts/modular_study_kit.gd")
const WALL_PROFILE := preload("res://scripts/modular_wall_profile.gd")
const ART_SCALE := 0.29
const CELL_STEP := WALL_PROFILE.CELL_PITCH
const SMALL_ROOM := Vector2(558, 425)
const BASE_ORIGIN := Vector2(57, 63)
const VISUAL_SEED := 173

@export var layout: DungeonLayout
@export_enum("Closed room", "North–south passage", "West–east passage") var open_axis: int = 0
# Resolve on each inspector read: a stored Callable can become Nil on hot reload.
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")
var _pieces: Array[Sprite2D] = []
var _origin := BASE_ORIGIN

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	refresh_preview()

func _cells() -> Vector2i:
	return layout.get_grid_size() if layout != null else Vector2i.ONE

func get_content_rect() -> Rect2:
	var cells := _cells()
	var extra := Vector2(maxi(0, cells.x - 2), maxi(0, cells.y - 2))
	return Rect2(Vector2.ZERO, Vector2(416, 416) + extra * CELL_STEP * ART_SCALE)

func get_cap_rect() -> Rect2:
	var size := SMALL_ROOM + Vector2(_cells() - Vector2i.ONE) * CELL_STEP
	if open_axis == 1:
		return Rect2(_origin + Vector2(0, 190) * ART_SCALE, Vector2(size.x, _cells().y * CELL_STEP.y) * ART_SCALE)
	if open_axis == 2:
		size.x = _cells().x * CELL_STEP.x
	return Rect2(_origin, size * ART_SCALE)

func refresh_preview() -> void:
	for piece in _pieces:
		remove_child(piece)
		piece.queue_free()
	_pieces.clear()
	var cells := _cells()
	if cells.x < 1 or cells.y < 1 or cells.x > 3 or cells.y > 3:
		push_warning("This visual study supports closed rectangles from 1 to 3 cells per axis.")
		return
	var size := SMALL_ROOM + Vector2(cells - Vector2i.ONE) * CELL_STEP
	var width := size.x
	var south_y := size.y
	if open_axis == 2:
		width = cells.x * CELL_STEP.x
	_origin = BASE_ORIGIN + Vector2(maxi(0, 2 - cells.x), maxi(0, 2 - cells.y)) * CELL_STEP * ART_SCALE * 0.5
	_paving(cells)
	if open_axis == 1:
		for left in [0.0,width - WALL_PROFILE.BORDER]:
			for sprite: Sprite2D in KIT.SIDE_ART.make_run(left,186,192 + cells.y * CELL_STEP.y,ART_SCALE):
				sprite.position += _origin
				add_child(sprite)
				_pieces.append(sprite)
		queue_redraw()
		rebuilt.emit()
		return
	# The approved top course retains its thickness; lower courses span the
	# entire wall, independently of the top/corner module boundaries.
	var north_counts: Array = WALL_PROFILE.NORTH_COUNTS
	var south_counts: Array = WALL_PROFILE.SOUTH_COUNTS
	var north_count: int = south_counts[cells.x - 1] if open_axis == 2 else north_counts[cells.x - 1]
	_facade_courses(-12 if open_axis == 2 else 75, width + 14 if open_axis == 2 else width - 75, WALL_PROFILE.course_top(false), north_count, 0)
	_facade_courses(-12, width + 14, south_y + WALL_PROFILE.course_top(true), south_counts[cells.x - 1], 2)
	if open_axis == 2:
		_horizontal_caps(Vector2.ZERO, cells.x, false)
		_horizontal_caps(Vector2(0, south_y), cells.x, true)
		queue_redraw()
		rebuilt.emit()
		return
	for section in range(cells.x - 1):
		_place("north", Vector2(278 + section * CELL_STEP.x, 0), 2, WALL_PROFILE.NORTH_SCALE)
		_place("south", Vector2(284 + section * CELL_STEP.x, south_y), 4, WALL_PROFILE.SOUTH_SCALE)
	_place("nw", Vector2.ZERO, 2)
	_place("ne", Vector2(width, 0), 2)
	# Fill the actual ports once. The former315*.92 pairs advanced only256,
	# overlapping each other and the lower corner by about34 source units.
	for center in [WALL_PROFILE.CLOSED_SIDE_CENTERS.x, width + WALL_PROFILE.CLOSED_SIDE_CENTERS.y]:
		for sprite: Sprite2D in KIT.SIDE_ART.make_run(center - 41.0,
				WALL_PROFILE.CLOSED_SIDE_TOP, south_y + WALL_PROFILE.CLOSED_SIDE_BOTTOM,
				ART_SCALE, WALL_PROFILE.CLOSED_SIDE_WIDTH):
			sprite.position += _origin
			add_child(sprite)
			_pieces.append(sprite)
	_place("sw", Vector2(0, south_y), 5)
	_place("se", Vector2(width, south_y), 5)
	queue_redraw()
	rebuilt.emit()

func _horizontal_caps(origin: Vector2, count: int, south: bool, first := INF) -> void:
	var start := WALL_PROFILE.cap_first(south, false) if is_inf(first) else first
	for section in range(count):
		_place("south" if south else "north", origin + Vector2(start + section * CELL_STEP.x, 0),
			4 if south else 2, WALL_PROFILE.cap_scale(south))

func _paving(cells: Vector2i, passage_length: float = -1.0) -> void:
	# Three native proportions. Reorder complete stones across the whole row,
	# so logical-cell boundaries do not create repeated vertical seams.
	var patterns := [[0, 1, 0], [1, 2], [0, 0, 1], [2, 1], [1, 0, 0]]
	var passage_patterns := [[0, 1, 1], [2, 2], [1, 0, 1], [1, 1, 0]]
	var rng := RandomNumberGenerator.new()
	rng.seed = VISUAL_SEED
	var used := [0, 0, 0]
	var variants := [0, 2, 1, 3]
	var rows: Array[Dictionary] = []
	var total_height := 0.0
	for row in range(cells.y * 2):
		var formats: Array[int] = []
		for cell in range(cells.x):
			var pattern: Array = passage_patterns[(row + cell) % passage_patterns.size()] if open_axis == 1 and row % 2 == 1 else patterns[(row * 3 + cell * 2) % patterns.size()]
			for format in pattern:
				formats.append(format)
		for index in range(formats.size() - 1, 0, -1):
			var other := rng.randi_range(0, index)
			var previous := formats[index]
			formats[index] = formats[other]
			formats[other] = previous
		var ids: Array[String] = []
		var native_width := 0.0
		var native_height := INF
		var max_height := 0.0
		for format in formats:
			var variant: int = variants[(used[format] + format) % variants.size()]
			used[format] += 1
			var id := "floor_" + str(variant * 3 + format)
			ids.append(id)
			native_width += KIT.BODY[id].x
			native_height = minf(native_height, KIT.BODY[id].y)
			max_height = maxf(max_height, KIT.BODY[id].y)
		var factor := (cells.x * CELL_STEP.x + 4.0) / native_width
		var advance := native_height * factor - 1.0
		rows.append({"ids": ids, "factor": factor, "advance": advance})
		total_height += max_height * factor if row == cells.y * 2 - 1 else advance
	# At open passage ends the entire row composition fits the side run with
	# one uniform scale; no paver is cropped or independently stretched.
	var span := cells.y * CELL_STEP.y + 6.0 if passage_length < 0 else passage_length
	var fit := span / total_height if open_axis == 1 else 1.0
	var top := 186.0 if open_axis == 1 else 188.0
	for row in range(rows.size()):
		var ids: Array[String] = rows[row].ids
		var factor: float = rows[row].factor * fit
		var cursor := 0.0 if open_axis == 2 else 40.0 + (cells.x * CELL_STEP.x + 4.0) * (1.0 - fit) * 0.5
		for index in range(ids.size()):
			var id := ids[index]
			_place(id, Vector2(cursor, top), 0, factor)
			cursor += KIT.BODY[id].x * factor
		# Native edge outlines touch; the surplus at the ends sits under walls.
		top += rows[row].advance * fit

func _row_spec(left: float, right: float, full_count: int, half_ends: bool, phase: int) -> Dictionary:
	var ids: Array[String] = []
	if half_ends:
		ids.append("brick_half_" + str(phase % 4))
	for index in range(full_count):
		ids.append("brick_" + str((index * 3 + phase + VISUAL_SEED) % 4))
	if half_ends:
		ids.append("brick_half_" + str((phase + 2) % 4))
	return _course_spec(ids, left, right)

func _course_spec(ids: Array[String], left: float, right: float) -> Dictionary:
	var native_width := 0.0
	var native_height := 0.0
	for id in ids:
		native_width += KIT.BODY[id].x
		native_height = maxf(native_height, KIT.BODY[id].y)
	var gap := 1.5
	var uniform_scale := (right - left - gap * (ids.size() - 1)) / native_width
	return {"ids": ids, "scale": uniform_scale, "height": native_height * uniform_scale, "gap": gap}

func _facade_courses(left: float, right: float, top: float, count: float, phase: int) -> void:
	var full := int(count)
	var upper: Dictionary
	var lower: Dictionary
	if is_equal_approx(count, full):
		upper = _row_spec(left, right, full, false, phase)
		lower = _row_spec(left, right, full - 1, true, phase + 1)
	else:
		var upper_ids: Array[String] = []
		var lower_ids: Array[String] = ["brick_half_" + str((phase + 1) % 4)]
		for index in range(full):
			upper_ids.append("brick_" + str((index * 3 + phase + VISUAL_SEED) % 4))
			lower_ids.append("brick_" + str((index * 3 + phase + 1 + VISUAL_SEED) % 4))
		upper_ids.append("brick_half_" + str((phase + 2) % 4))
		upper = _course_spec(upper_ids, left, right)
		lower = _course_spec(lower_ids, left, right)
	_draw_course(upper, left, top)
	_draw_course(lower, left, top + upper.height - 2.0)

func _draw_course(row: Dictionary, left: float, top: float) -> void:
	var cursor := left
	for id in row.ids:
		_place(id, Vector2(cursor, top), 1, row.scale)
		cursor += KIT.BODY[id].x * row.scale + row.gap

func _place(id: String, anchor: Vector2, layer: int, relative_scale := 1.0, shaded_floor := false) -> Sprite2D:
	var sprite := KIT.make(id, ART_SCALE * relative_scale, shaded_floor)
	sprite.name = id.capitalize() + str(_pieces.size())
	sprite.position = _origin + anchor * ART_SCALE
	sprite.z_index = layer
	add_child(sprite)
	_pieces.append(sprite)
	return sprite

func _draw() -> void:
	draw_rect(get_content_rect(), Color("080e19"))
