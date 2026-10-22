@tool
extends "res://scripts/modular_room_study.gd"

## Rebuild a room and its connections from logical occupancy and exposed edges.
## The regular wall profile and paving routines are shared with the seven studies.
const PLAN := preload("res://scripts/modular_connection_plan.gd")
const JOINS := preload("res://scripts/modular_join_kit.gd")
const SEPARATORS := preload("res://scripts/modular_separator_kit.gd")

@export_flags("North", "East", "South", "West") var connections: int = 15:
	set(value):
		connections = value & 15
		_request_rebuild()
@export_range(1, 3) var corridor_length: int = 2:
	set(value):
		corridor_length = clampi(value, 1, 3)
		_request_rebuild()
## Zero follows corridor_length; positive values set north/south length only.
@export var vertical_corridor_length: int = 0:
	set(value):
		vertical_corridor_length = maxi(value, 0)
		_request_rebuild()
## Empty follows the middle row; explicit rows can attach multiple passages.
@export var horizontal_attachment_rows: PackedInt32Array = PackedInt32Array():
	set(value):
		horizontal_attachment_rows = value
		_request_rebuild()
## Empty follows the middle column; explicit columns can attach multiple passages.
@export var vertical_attachment_columns: PackedInt32Array = PackedInt32Array():
	set(value):
		vertical_attachment_columns = value
		_request_rebuild()

func _vertical_length() -> int:
	return vertical_corridor_length if vertical_corridor_length > 0 else corridor_length

var _plan: Dictionary = {}
var _room_origin := Vector2.ZERO
var _frame := Rect2(0, 0, 1280, 720)
var _room_size := Vector2(1510, 937)
var _west_end := 0.0
var _east_end := 1510.0
var _horizontal_ends: Dictionary = {}
var _has_horizontal_turn_bounds := false
var _floor_bottom := 0.0
var _north_floor_top := -330.0
var _rebuild_pending := false

func _request_rebuild() -> void:
	if is_inside_tree() and not _rebuild_pending:
		_rebuild_pending = true
		refresh_preview.call_deferred()

func get_content_rect() -> Rect2:
	return _frame

func get_cap_rect() -> Rect2:
	return Rect2(_room_origin, _room_size * ART_SCALE)

func get_junction_centers() -> Dictionary:
	var cells := _cells()
	var cx := int(cells.x / 2)
	var cy := int(cells.y / 2)
	return {
		"north": _room_origin + Vector2(cx * CELL_STEP.x + 279, 90) * ART_SCALE,
		"south": _room_origin + Vector2(cx * CELL_STEP.x + 279, _room_size.y + 50) * ART_SCALE,
		"west": _room_origin + Vector2(40, cy * CELL_STEP.y + 270) * ART_SCALE,
		"east": _room_origin + Vector2(_room_size.x - 40, cy * CELL_STEP.y + 270) * ART_SCALE,
	}

func get_regression_detail_centers() -> Dictionary:
	var centers := get_junction_centers()
	var shoulder_middle := (int(_cells().x / 2) * CELL_STEP.x + WALL_PROFILE.BORDER) * 0.5
	var cy := int(_cells().y / 2)
	var upper_y: float = cy * CELL_STEP.y
	for run: Dictionary in _plan.get("runs", []):
		if run.side == PLAN.NORTH and run.a.x < 0 and not run.right_turn.is_empty():
			upper_y = run.right_turn.anchor.y
			break
	return {
		"west-floor": centers.west,
		"corridor-wall-foot": _room_origin + Vector2(-620, upper_y + 120) * ART_SCALE,
		"corner-style": _room_origin + Vector2(0, upper_y + 80) * ART_SCALE,
		"west-upper-return": _room_origin + Vector2(shoulder_middle,180) * ART_SCALE,
		"west-lower-return": _room_origin + Vector2(shoulder_middle,_room_size.y - 17) * ART_SCALE,
		"east-upper-return": _room_origin + Vector2(_room_size.x - shoulder_middle,180) * ART_SCALE,
		"east-lower-return": _room_origin + Vector2(_room_size.x - shoulder_middle,_room_size.y - 17) * ART_SCALE,
		"north-side": _room_origin + Vector2(int(_cells().x / 2) * CELL_STEP.x + 41,(_north_floor_top - 65) * 0.5) * ART_SCALE,
		"south-side": _room_origin + Vector2(int(_cells().x / 2) * CELL_STEP.x + 41,(_floor_bottom + _vertical_length() * CELL_STEP.y + _room_size.y + 170) * 0.5) * ART_SCALE,
	}

func get_connection_plan() -> Dictionary:
	return _plan

func get_corner_detail_centers() -> Dictionary:
	var result := {}
	for point: Vector2i in _plan.get("turns", {}):
		var turn: Dictionary = _plan.turns[point]
		if turn.has("separator"):
			continue
		var x := -41.0 if turn.id in ["ne","se"] else 41.0
		result["corner-%d-%d" % [point.x,point.y]] = _room_origin + (turn.anchor + Vector2(x,40)) * ART_SCALE
	for separator: Dictionary in _plan.get("separators", []):
		result["separator-%d-%d" % [separator.end.x,separator.end.y]] = _room_origin + separator.tip_center * ART_SCALE
	return result

func refresh_preview() -> void:
	_rebuild_pending = false
	for piece in _pieces:
		remove_child(piece)
		piece.queue_free()
	_pieces.clear()
	var cells := _cells()
	if cells.x < 3 or cells.y < 3 or cells.x % 2 == 0 or cells.y % 2 == 0:
		_plan.clear()
		_frame = Rect2(0, 0, 416, 416)
		_room_origin = Vector2.ZERO
		_room_size = Vector2.ZERO
		_origin = Vector2.ZERO
		_floor_bottom = 0.0
		push_warning("Connected study requires an odd room of at least 3x3 cells.")
		queue_redraw()
		rebuilt.emit()
		return
	_origin = Vector2.ZERO
	_room_origin = Vector2.ZERO
	_room_size = Vector2(cells) * CELL_STEP + Vector2(WALL_PROFILE.BORDER, WALL_PROFILE.SOUTH_PROJECTION)
	_plan = PLAN.build(cells, corridor_length, connections, _vertical_length(), horizontal_attachment_rows, vertical_attachment_columns)
	_prepare_paired_runs()
	_align_short_returns()
	# Central pavers retain the exact seed, positions, scales, colors and order.
	open_axis = 0
	_paving(cells)
	var rows := _central_floor_rows()
	_floor_bottom = 0.0
	for stone: Sprite2D in rows.back():
		var id: String = stone.get_meta("asset_id")
		_floor_bottom = maxf(_floor_bottom, stone.position.y / ART_SCALE + KIT.BODY[id].y * stone.scale.x / ART_SCALE)
	_west_end = 0.0
	_east_end = _room_size.x
	_horizontal_ends.clear()
	_has_horizontal_turn_bounds = false
	for point: Vector2i in _plan.turns:
		_draw_turn(_plan.turns[point])
	for separator: Dictionary in _plan.separators:
		_draw_separator(separator)
	for run: Dictionary in _plan.runs:
		if run.side in [PLAN.NORTH, PLAN.SOUTH] and (not run.left_turn.is_empty() or not run.right_turn.is_empty()):
			_draw_horizontal_run(run)
	# Closed turn ports establish physical open-end bounds first. A continuous
	# wall crossing several attachments then uses those same terminal bounds.
	for run: Dictionary in _plan.runs:
		if run.side in [PLAN.NORTH, PLAN.SOUTH] and run.left_turn.is_empty() and run.right_turn.is_empty():
			_draw_horizontal_run(run)
	_extend_floor_rows(rows)
	if connections & PLAN.NORTH:
		var central_top: float = rows[0][0].position.y / ART_SCALE
		var minimum_top_run := 119.0 * 82.0 / 228.0
		_north_floor_top = minf(central_top - _vertical_length() * CELL_STEP.y - 6.0,
			JOINS.vertical_port("se", false) - minimum_top_run)
		open_axis = 1
		for column in _plan.vertical_columns:
			_origin = Vector2(column * CELL_STEP.x, _north_floor_top - 186) * ART_SCALE
			_paving(Vector2i(1, _vertical_length()), central_top - _north_floor_top)
	if connections & PLAN.SOUTH:
		open_axis = 1
		for column in _plan.vertical_columns:
			_origin = Vector2(column * CELL_STEP.x, _floor_bottom - 186) * ART_SCALE
			_paving(Vector2i(1, _vertical_length()))
	_origin = Vector2.ZERO
	open_axis = 0
	for run: Dictionary in _plan.runs:
		if run.side in [PLAN.WEST, PLAN.EAST]:
			_draw_vertical_run(run)
	_center_whole_sprites()
	queue_redraw()
	rebuilt.emit()

func _draw_turn(turn: Dictionary) -> void:
	if turn.has("paired_port") or turn.has("separator"):
		return
	var id: String = turn.id
	var south: bool = turn.mask in [1,2,7,11]
	var sprite := _place(id, turn.anchor, 5 if south else 2)
	if turn.compact:
		# Same complete region and anchor as the original L. Only its dedicated
		# source art has shorter vertical terminal stones; no pixels are cut.
		var atlas: AtlasTexture = sprite.texture
		atlas.atlas = JOINS.CAPS
		var fit := JOINS.horizontal_fit(id, south)
		sprite.position += Vector2(fit.x, fit.y) * ART_SCALE
		sprite.scale *= fit.z
		sprite.set_meta("compact_turn", true)

func _turn_port(turn: Dictionary, bottom: bool) -> float:
	if turn.has("paired_port"):
		var ports: Vector2 = turn.paired_port
		return ports.y if bottom else ports.x
	return JOINS.vertical_port(turn.id, bottom, turn.compact, turn.mask in [1,2,7,11])

func _prepare_paired_runs() -> void:
	for run: Dictionary in _plan.runs:
		if run.has("separator") or run.side not in [PLAN.NORTH, PLAN.SOUTH] or run.b.x - run.a.x != 1:
			continue
		var left: Dictionary = run.left_turn
		var right: Dictionary = run.right_turn
		if left.is_empty() or right.is_empty():
			continue
		var index := JOINS.paired_index(left.id,right.id,run.side == PLAN.SOUTH)
		if index < 0:
			continue
		run["paired_index"] = index
		left["paired_port"] = JOINS.paired_port(index,true)
		right["paired_port"] = JOINS.paired_port(index,false)
		left["shaft_width"] = JOINS.paired_width(index,true)
		right["shaft_width"] = JOINS.paired_width(index,false)
		left["compact"] = true
		right["compact"] = true

func _draw_paired_run(index: int, anchor: Vector2, south: bool) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = JOINS.PAIRED
	atlas.region = Rect2((index % 2) * 768,int(index / 2) * 512,768,512)
	atlas.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.offset = -Vector2(96,256)
	var fit := JOINS.paired_fit(index)
	sprite.position = _origin + (anchor + Vector2(fit.x,fit.y)) * ART_SCALE
	sprite.scale = Vector2.ONE * ART_SCALE * fit.z
	sprite.z_index = 5 if south else 2
	sprite.set_meta("asset_id", "paired_cap_" + str(index))
	add_child(sprite)
	_pieces.append(sprite)

func _align_short_returns() -> void:
	# A short return consists of two complete L ends meeting directly. Move
	# entire horizontal wall rows to their native ports instead of inserting
	# tiny filler stones, stretching an arm or overlapping painted ends.
	var horizontal_at: Dictionary = {}
	for index in range(_plan.runs.size()):
		var run: Dictionary = _plan.runs[index]
		if run.side in [PLAN.NORTH, PLAN.SOUTH]:
			horizontal_at[run.a] = index
			horizontal_at[run.b] = index
	var row_shifts: Dictionary = {}
	for run: Dictionary in _plan.runs:
		if run.has("separator") or run.side not in [PLAN.WEST, PLAN.EAST]:
			continue
		var upper: Dictionary = run.left_turn
		var lower: Dictionary = run.right_turn
		if upper.is_empty() or lower.is_empty() or not upper.compact or not lower.compact:
			continue
		var gap: float = lower.anchor.y + _turn_port(lower, false) - upper.anchor.y - _turn_port(upper, true)
		if absf(gap) <= 0.01 or absf(gap) > WALL_PROFILE.BORDER:
			continue
		row_shifts[horizontal_at[run.a]] = gap * 0.5
		row_shifts[horizontal_at[run.b]] = -gap * 0.5
	for index in row_shifts:
		var run: Dictionary = _plan.runs[index]
		for turn: Dictionary in [run.left_turn, run.right_turn]:
			if not turn.is_empty():
				turn.anchor += Vector2(0, row_shifts[index])
				turn["vertical_shift"] = row_shifts[index]

func _draw_separator(separator: Dictionary) -> void:
	var upper: Dictionary = separator.upper
	var lower: Dictionary = separator.lower
	var closed_left: bool = separator.closed_left
	var turn: Dictionary = lower.left_turn if closed_left else lower.right_turn
	var id := "left_end" if closed_left else "right_end"
	var end_width := SEPARATORS.width(id)
	var count: int = upper.b.x - upper.a.x
	var span := count * SEPARATORS.PITCH + end_width
	# Keep the same complete-module terminal bounds as the ordinary contour.
	# New art changes the local nose, not the length of the open passages.
	var left: float
	var right: float
	if closed_left:
		right = maxf(_separator_open_bound(upper),_separator_open_bound(lower))
		left = right - span
	else:
		left = minf(_separator_open_bound(upper),_separator_open_bound(lower))
		right = left + span
	# Align the single front lip to the lower exposed edge. The top is broad
	# native artwork, not two cap bands laid on top of each other.
	var bottom: float = turn.anchor.y + WALL_PROFILE.CAP_REGIONS.north.end.y * WALL_PROFILE.NORTH_SCALE
	var top := bottom - SEPARATORS.HEIGHT
	var tip_left := left if closed_left else right - end_width
	_add_separator_piece(id,Vector2(tip_left,top))
	var first := left + end_width if closed_left else left
	for index in range(count):
		_add_separator_piece("straight",Vector2(first + index * SEPARATORS.PITCH,top))
	# The terminal owns its complete masonry and end return. Straight courses
	# meet its exposed connection port; no extra bricks are drawn beneath it.
	var straight_span := count * SEPARATORS.PITCH
	_separator_facade(first,first + straight_span,top,id)
	separator["tip_center"] = Vector2(tip_left + end_width * 0.5,top + SEPARATORS.HEIGHT * 0.85)
	_west_end = minf(_west_end,left)
	_east_end = maxf(_east_end,right)
	_has_horizontal_turn_bounds = true
	for attachment: int in [upper.a.y - 1,lower.a.y]:
		var ends: Dictionary = _horizontal_ends.get(attachment,{"left": 0.0,"right": float(_room_size.x)})
		if upper.a.x < 0:
			ends.left = minf(ends.left,left)
		if upper.b.x > _cells().x:
			ends.right = maxf(ends.right,right)
		_horizontal_ends[attachment] = ends

func _separator_facade(left: float, right: float, top: float, terminal: String) -> void:
	# Choose whole stones for each measured native course, including its base.
	# Different lower-course brick lengths keep the terminal foot level without
	# stretching pixels, moving the end sprite or hiding a mismatched edge.
	for lower: bool in [false,true]:
		var height := SEPARATORS.course_height(terminal,lower)
		var brick_width: float = height * KIT.BODY.brick_0.x / KIT.BODY.brick_0.y
		var estimate := maxi(1,roundi((right - left) / brick_width) - (1 if lower else 0))
		var best: Dictionary = {}
		var error := INF
		for count in range(maxi(1,estimate - 2),estimate + 3):
			var row := _row_spec(left,right,count,lower,1 if lower else 0)
			var candidate: float = absf(row.height - height)
			if candidate < error:
				best = row
				error = candidate
		_draw_course(best,left,top + SEPARATORS.facade_top(terminal,lower))

func _add_separator_piece(id: String, anchor: Vector2) -> void:
	var sprite := SEPARATORS.make(id,anchor,ART_SCALE)
	add_child(sprite)
	_pieces.append(sprite)

func _separator_open_bound(run: Dictionary) -> float:
	var south: bool = run.side == PLAN.SOUTH
	var cap: Rect2 = WALL_PROFILE.CAP_REGIONS["south" if south else "north"]
	var factor := WALL_PROFILE.cap_scale(south)
	var count: int = run.b.x - run.a.x
	if not run.left_turn.is_empty():
		return run.left_turn.anchor.x + WALL_PROFILE.cap_first(south,true) + (count - 1) * CELL_STEP.x + cap.end.x * factor
	return run.right_turn.anchor.x - (274.0 if south else 280.0) - count * CELL_STEP.x + cap.position.x * factor

func _draw_horizontal_run(run: Dictionary) -> void:
	if run.has("separator"):
		return
	var a: Vector2i = run.a
	var b: Vector2i = run.b
	var south: bool = run.side == PLAN.SOUTH
	var left_turn: Dictionary = run.left_turn
	var right_turn: Dictionary = run.right_turn
	var left_closed := not left_turn.is_empty()
	var right_closed := not right_turn.is_empty()
	var columns := b.x - a.x
	var y := a.y * CELL_STEP.y + (WALL_PROFILE.SOUTH_PROJECTION if south else 0.0)
	if left_closed:
		y = left_turn.anchor.y
	elif right_closed:
		y = right_turn.anchor.y
	var count := columns - 1 if left_closed and right_closed else columns
	var first := a.x * CELL_STEP.x + WALL_PROFILE.cap_first(south, false)
	if left_closed:
		first = left_turn.anchor.x + WALL_PROFILE.cap_first(south, true)
	elif right_closed:
		first = right_turn.anchor.x - (274 if south else 280) - count * CELL_STEP.x
	if not left_closed and not right_closed and a.x < 0 and b.x > _cells().x and _has_horizontal_turn_bounds:
		var profile: Rect2 = WALL_PROFILE.CAP_REGIONS["south" if south else "north"]
		var cap_scale := WALL_PROFILE.cap_scale(south)
		var cap_left := profile.position.x * cap_scale
		var cap_right := profile.end.x * cap_scale
		count = maxi(1,roundi((_east_end - _west_end - (cap_right - cap_left)) / CELL_STEP.x) + 1)
		first = (_west_end + _east_end - (count - 1) * CELL_STEP.x - cap_left - cap_right) * 0.5
	# This is the SAME cap call, cadence and .99/.97 scale as 2x1Corridor.
	if run.has("paired_index"):
		_draw_paired_run(run.paired_index,left_turn.anchor,south)
	else:
		_horizontal_caps(Vector2(first, y), count, south, 0)
	var id := "south" if south else "north"
	var measured: Rect2 = WALL_PROFILE.CAP_REGIONS[id]
	var factor := WALL_PROFILE.cap_scale(south)
	var left: float = left_turn.anchor.x if left_closed else first + measured.position.x * factor
	var right: float = right_turn.anchor.x if right_closed else first + (count - 1) * CELL_STEP.x + measured.end.x * factor
	# Open ends retain the reference corridor's complete facade ends. At a
	# corner, the facade ends at the return instead of projecting beyond it.
	var face_left := left + (75.0 if left_turn.id == "nw" else 0.0) if left_closed else left - 12.0
	var face_right := right - (75.0 if right_turn.id == "ne" else 0.0) if right_closed else right + 14.0
	var masonry_count := WALL_PROFILE.span_count(face_right - face_left)
	if left_closed and right_closed and left_turn.mask in [1,2,4,8] and right_turn.mask in [1,2,4,8]:
		masonry_count = WALL_PROFILE.face_count(columns, south, true)
	elif not left_closed and not right_closed:
		masonry_count = WALL_PROFILE.face_count(count, south, false)
	# No per-scene minimum-height offset or rescaling of cap rows.
	_facade_courses(face_left, face_right, y + WALL_PROFILE.course_top(south), masonry_count, 2 if south else 0)
	if a.x < 0:
		_west_end = minf(_west_end, left)
	if b.x > _cells().x:
		_east_end = maxf(_east_end, right)
	if (left_closed or right_closed) and (a.x < 0 or b.x > _cells().x):
		_has_horizontal_turn_bounds = true
	var attachment: int = a.y - (1 if south else 0)
	# Scalar floats keep the original row endpoints' precision (Vector2 would
	# round source coordinates before the final paving fit).
	var ends: Dictionary = _horizontal_ends.get(attachment,{"left": 0.0,"right": float(_room_size.x)})
	if a.x < 0:
		ends.left = minf(ends.left,left)
	if b.x > _cells().x:
		ends.right = maxf(ends.right,right)
	_horizontal_ends[attachment] = ends

func _draw_vertical_run(run: Dictionary) -> void:
	if run.has("separator"):
		return
	var a: Vector2i = run.a
	var upper: Dictionary = run.left_turn
	var lower: Dictionary = run.right_turn
	var east: bool = run.side == PLAN.EAST
	var x := a.x * CELL_STEP.x
	if not upper.is_empty() and not lower.is_empty() and not upper.compact and not lower.compact and not upper.has("vertical_shift") and not lower.has("vertical_shift"):
		var center: float = upper.anchor.x + (WALL_PROFILE.CLOSED_SIDE_CENTERS.y if east else WALL_PROFILE.CLOSED_SIDE_CENTERS.x)
		_side_gap(center - 41.0, upper.anchor.y + _turn_port(upper,true),
			lower.anchor.y + _turn_port(lower,false), WALL_PROFILE.CLOSED_SIDE_WIDTH)
		return
	var top := _north_floor_top
	var bottom := _floor_bottom + _vertical_length() * CELL_STEP.y + 6.0
	if not upper.is_empty():
		top = upper.anchor.y + _turn_port(upper, true)
	if not lower.is_empty():
		bottom = lower.anchor.y + _turn_port(lower, false)
	# Compact L ends meet on short room shoulders; they need no filler cube.
	if bottom <= top + 2.0:
		return
	var width := 94.0
	for turn: Dictionary in [upper,lower]:
		if turn.is_empty():
			continue
		if turn.has("shaft_width"):
			width = turn.shaft_width
		elif turn.compact:
			width = JOINS.shaft_width(turn.id,turn.mask in [1,2,7,11])
		else:
			width = WALL_PROFILE.CLOSED_SIDE_WIDTH
		break
	_side_gap(x, top, bottom, width)

func _side_gap(left: float, top: float, bottom: float, width: float = 94.0) -> void:
	for sprite: Sprite2D in JOINS.SIDE_ART.make_run(left,top,bottom,ART_SCALE,width):
		sprite.name = "WholeSide" + str(_pieces.size())
		add_child(sprite)
		_pieces.append(sprite)

func _central_floor_rows() -> Array[Array]:
	var rows: Array[Array] = []
	var previous_y := -INF
	for stone in _pieces:
		if not is_equal_approx(stone.position.y, previous_y):
			rows.append([])
			previous_y = stone.position.y
		rows.back().append(stone)
	return rows

func _extend_floor_rows(rows: Array[Array]) -> void:
	for attachment in _plan.horizontal_rows:
		var ends: Dictionary = _horizontal_ends.get(attachment,{"left": _west_end,"right": _east_end})
		_extend_attachment_rows(rows,attachment,ends)

func _extend_attachment_rows(rows: Array[Array], attachment: int, ends: Dictionary) -> void:
	for row_index in [attachment * 2, attachment * 2 + 1]:
		var row: Array = rows[row_index]
		var first: Sprite2D = row.front()
		var last: Sprite2D = row.back()
		var factor := first.scale.x / ART_SCALE
		var top := first.position.y / ART_SCALE
		var last_id: String = last.get_meta("asset_id")
		var left := first.position.x / ART_SCALE
		var right: float = last.position.x / ART_SCALE + KIT.BODY[last_id].x * factor
		if connections & PLAN.WEST:
			_extend_row(row, row_index, left, ends.left, top, factor, -1)
		if connections & PLAN.EAST:
			_extend_row(row, row_index, right, ends.right, top, factor, 1)

func _extend_row(row: Array, row_index: int, start: float, end: float, top: float, factor: float, direction: int) -> void:
	var formats := [2,0,1,1,0]
	var cursor := start
	var step := 0
	# Native whole stones next to the room retain the central row's exact scale.
	while absf(end - cursor) > 650:
		var format: int = formats[(step + row_index) % formats.size()]
		var id := "floor_" + str(((step * 3 + row_index) % 4) * 3 + format)
		cursor = _extension_stone(id, cursor, top, factor, direction, row, row_index, step)
		step += 1
	# Fit the two final complete stones at the OPEN end uniformly. The room
	# junction itself is never overlaid, fitted independently, clipped or moved.
	var remaining := absf(end - cursor)
	var best_ids: Array[String] = []
	var best_factor := factor
	var best_error := INF
	for one in range(3):
		for two in range(3):
			var ids: Array[String] = ["floor_" + str(((step + row_index) % 4) * 3 + one),
				"floor_" + str(((step + row_index + 2) % 4) * 3 + two)]
			var candidate: float = remaining / (KIT.BODY[ids[0]].x + KIT.BODY[ids[1]].x)
			var error := absf(candidate - factor)
			if error < best_error:
				best_error = error
				best_factor = candidate
				best_ids = ids
	for id in best_ids:
		cursor = _extension_stone(id, cursor, top, best_factor, direction, row, row_index, step)
		step += 1

func _extension_stone(id: String, cursor: float, top: float, factor: float, direction: int,
		_row: Array, row_index: int, _step: int) -> float:
	var width: float = KIT.BODY[id].x * factor
	if direction < 0:
		cursor -= width
	_place(id, Vector2(cursor, top), 0, factor)
	if row_index % 2 == 0:
		_place(id, Vector2(cursor, top - 40), -1, factor, true)
	if direction > 0:
		cursor += width
	return cursor

func _center_whole_sprites() -> void:
	# Frame complete Sprite2D rectangles, including source transparent gutters.
	# These bounds never define a silhouette, mask, clipping region or collider.
	var bounds := Rect2()
	var first := true
	for sprite in _pieces:
		var rect: Rect2 = sprite.transform * sprite.get_rect()
		bounds = rect if first else bounds.merge(rect)
		first = false
	var shift := Vector2(40,40) - bounds.position
	for sprite in _pieces:
		sprite.position += shift
		# The inherited background draws at Z0. Lift the complete assembly one
		# layer so support pavers remain visible above it and below the floor.
		sprite.z_index += 1
	_room_origin = shift
	_origin = shift
	_frame = Rect2(Vector2.ZERO, (bounds.size + Vector2(80,80)).ceil())
