@tool
extends "res://scripts/modular_room_study.gd"

## Rebuild a room and its connections from logical occupancy and exposed edges.
## The regular wall profile and paving routines are shared with the seven studies.
const PLAN := preload("res://scripts/modular_connection_plan.gd")
const JOINS := preload("res://scripts/modular_join_kit.gd")

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

func _vertical_length() -> int:
	return vertical_corridor_length if vertical_corridor_length > 0 else corridor_length

var _plan: Dictionary = {}
var _room_origin := Vector2.ZERO
var _frame := Rect2(0, 0, 1280, 720)
var _room_size := Vector2(1510, 937)
var _west_end := 0.0
var _east_end := 1510.0
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
		"west-upper-return": _room_origin + Vector2(279,180) * ART_SCALE,
		"west-lower-return": _room_origin + Vector2(279,_room_size.y - 17) * ART_SCALE,
		"east-upper-return": _room_origin + Vector2(_room_size.x - 279,180) * ART_SCALE,
		"east-lower-return": _room_origin + Vector2(_room_size.x - 279,_room_size.y - 17) * ART_SCALE,
		"north-side": _room_origin + Vector2(int(_cells().x / 2) * CELL_STEP.x + 41,(_north_floor_top - 65) * 0.5) * ART_SCALE,
		"south-side": _room_origin + Vector2(int(_cells().x / 2) * CELL_STEP.x + 41,(_floor_bottom + _vertical_length() * CELL_STEP.y + _room_size.y + 170) * 0.5) * ART_SCALE,
	}

func get_connection_plan() -> Dictionary:
	return _plan

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
	_plan = PLAN.build(cells, corridor_length, connections, _vertical_length())
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
	for point: Vector2i in _plan.turns:
		_draw_turn(_plan.turns[point])
	for run: Dictionary in _plan.runs:
		if run.side in [PLAN.NORTH, PLAN.SOUTH]:
			_draw_horizontal_run(run)
	_extend_floor_rows(rows)
	var cx := int(cells.x / 2)
	if connections & PLAN.NORTH:
		var central_top: float = rows[0][0].position.y / ART_SCALE
		var minimum_top_run := 119.0 * 82.0 / 228.0
		_north_floor_top = minf(central_top - _vertical_length() * CELL_STEP.y - 6.0,
			JOINS.vertical_port("se", false) - minimum_top_run)
		_origin = Vector2(cx * CELL_STEP.x, _north_floor_top - 186) * ART_SCALE
		open_axis = 1
		_paving(Vector2i(1, _vertical_length()), central_top - _north_floor_top)
	if connections & PLAN.SOUTH:
		_origin = Vector2(cx * CELL_STEP.x, _floor_bottom - 186) * ART_SCALE
		open_axis = 1
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
	if turn.has("paired_port"):
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
		if run.side not in [PLAN.NORTH, PLAN.SOUTH] or run.b.x - run.a.x != 1:
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
		if run.side not in [PLAN.WEST, PLAN.EAST]:
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

func _draw_horizontal_run(run: Dictionary) -> void:
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
		masonry_count = WALL_PROFILE.face_count(columns, south, false)
	# No per-scene minimum-height offset or rescaling of cap rows.
	_facade_courses(face_left, face_right, y + WALL_PROFILE.COURSE_TOP, masonry_count, 2 if south else 0)
	if a.x < 0:
		_west_end = minf(_west_end, left)
	if b.x > _cells().x:
		_east_end = maxf(_east_end, right)

func _draw_vertical_run(run: Dictionary) -> void:
	var a: Vector2i = run.a
	var b: Vector2i = run.b
	var upper: Dictionary = run.left_turn
	var lower: Dictionary = run.right_turn
	var east: bool = run.side == PLAN.EAST
	var x := a.x * CELL_STEP.x
	if not upper.is_empty() and not lower.is_empty() and not upper.compact and not lower.compact and not upper.has("vertical_shift") and not lower.has("vertical_shift"):
		# Original closed-room assembly is retained exactly.
		for section in range(b.y - a.y - 1):
			var shift: float = SIDE_OFFSETS[section % SIDE_OFFSETS.size()]
			_place("east" if east else "west",
				Vector2(x + 82 - shift if east else x + shift, upper.anchor.y + 270 + section * CELL_STEP.y), 3, 0.92)
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
			width = 82.0
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
	var middle := int(_cells().y / 2) * 2
	for row_index in [middle, middle + 1]:
		var row: Array = rows[row_index]
		var first: Sprite2D = row.front()
		var last: Sprite2D = row.back()
		var factor := first.scale.x / ART_SCALE
		var top := first.position.y / ART_SCALE
		var last_id: String = last.get_meta("asset_id")
		var left := first.position.x / ART_SCALE
		var right: float = last.position.x / ART_SCALE + KIT.BODY[last_id].x * factor
		if connections & PLAN.WEST:
			_extend_row(row, row_index, left, _west_end, top, factor, -1)
		if connections & PLAN.EAST:
			_extend_row(row, row_index, right, _east_end, top, factor, 1)

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
		row: Array, row_index: int, step: int) -> float:
	var width: float = KIT.BODY[id].x * factor
	if direction < 0:
		cursor -= width
	var stone := _place(id, Vector2(cursor, top), 0, factor)
	stone.self_modulate = (row[(step + row_index) % row.size()] as Sprite2D).self_modulate
	if row_index == int(_cells().y / 2) * 2:
		var support := _place(id, Vector2(cursor, top - 40), -1, factor)
		support.self_modulate = stone.self_modulate * Color(0.7,0.7,0.7,1)
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
