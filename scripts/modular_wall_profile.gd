extends RefCounted

## Single source of wall proportions for isolated and connected modules.
const CELL_PITCH := Vector2(476, 256)
const BORDER := 82.0
const CLOSED_SIDE_TOP := 279.0
const CLOSED_SIDE_BOTTOM := -166.0
const CLOSED_SIDE_WIDTH := 101.0
const CLOSED_SIDE_CENTERS := Vector2(41.75, -38.0)
const SOUTH_PROJECTION := 169.0
const NORTH_COURSE_TOP := 96.0
const SOUTH_COURSE_TOP := 105.0
const NORTH_SCALE := 0.99
const SOUTH_SCALE := 0.97
const NORTH_COUNTS := [2, 4, 7]
const SOUTH_COUNTS := [3, 5, 8]
const CAP_REGIONS := {"north": Rect2(-6, -12, 495, 107), "south": Rect2(-11, -12, 506, 115)}

static func cap_scale(south: bool) -> float:
	return SOUTH_SCALE if south else NORTH_SCALE

static func course_top(south: bool) -> float:
	# Place the complete brick rim below the cap's painted foot.
	return SOUTH_COURSE_TOP if south else NORTH_COURSE_TOP

static func cap_first(south: bool, closed_left: bool) -> float:
	return (284.0 if south else 278.0) if closed_left else (3.0 if south else -4.0)

static func face_count(columns: int, south: bool, closed: bool) -> int:
	if columns <= 3:
		return SOUTH_COUNTS[columns - 1] if south or not closed else NORTH_COUNTS[columns - 1]
	return maxi(1, roundi((columns * CELL_PITCH.x + 26) / 195.6))

static func span_count(width: float) -> float:
	# Whole/half masonry modules preserve the 2x1 reference's stone height.
	return maxf(1.0, roundf(width / 195.6 * 2) * 0.5)
