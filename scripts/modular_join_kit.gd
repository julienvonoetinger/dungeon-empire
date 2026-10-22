extends RefCounted

## Dedicated short-leg variants of the existing L corners; never square cubes.
const CAPS := preload("res://assets/dungeon/modular-study/cap-elbows-flush-v9.png")
const PAIRED := preload("res://assets/dungeon/modular-study/paired-cap-transitions-v7.png")
const SIDE_ART := preload("res://scripts/modular_side_kit.gd")
const WALL_PROFILE := preload("res://scripts/modular_wall_profile.gd")

const SHORT_PORTS := {
	"nw": Vector2(-14,159), "ne": Vector2(-14,159),
	"sw": Vector2(-55,114), "se": Vector2(-55,114),
}
const SHAFTS := {"nw": Vector2(-8,89), "ne": Vector2(-86,11), "sw": Vector2(-7,90), "se": Vector2(-87,11)}
const PROFILES := {"nw": Vector2(-14,99), "ne": Vector2(-14,99), "sw": Vector2(1,114), "se": Vector2(1,114)}
const PAIRED_SHAFTS := [
	[Vector2(-17,83),Vector2(480,582)], [Vector2(-4,97),Vector2(494,595)],
	[Vector2(-17,84),Vector2(486,592)], [Vector2(-16,89),Vector2(494,595)],
]
const PAIRED_PROFILES := [Vector2(-17,92),Vector2(-17,93),Vector2(-56,60),Vector2(-55,60)]
const PAIRED_PORTS := [
	[Vector2(-17,160),Vector2(-79,92)], [Vector2(-79,93),Vector2(-17,160)],
	[Vector2(-126,60),Vector2(-56,128)], [Vector2(-55,128),Vector2(-126,60)],
]
const ORIGINAL_PORTS := {
	"nw": Vector2(-13,278), "ne": Vector2(-13,278),
	"sw": Vector2(-168,99), "se": Vector2(-168,99),
}

static func horizontal_fit(id: String, south: bool) -> Vector3:
	# Whole sprites use the horizontal course of the shared wall profile.
	var native: Vector2 = PROFILES[id]
	var shaft: Vector2 = SHAFTS[id]
	var cap: Rect2 = WALL_PROFILE.CAP_REGIONS["south" if south else "north"]
	var target := Vector2(cap.position.y, cap.end.y) * WALL_PROFILE.cap_scale(south)
	var factor := (target.y - target.x) / (native.y - native.x)
	var center := (shaft.x + shaft.y) * 0.5
	var x := (-41.0 if id in ["ne", "se"] else 41.0) - center * factor
	return Vector3(x, target.x - native.x * factor, factor)

static func vertical_port(id: String, bottom: bool, compact: bool = true, south: bool = false) -> float:
	# Measurements place intact source ends; they never clip painted pixels.
	var ports: Vector2 = SHORT_PORTS[id] if compact else ORIGINAL_PORTS[id]
	var end := ports.y if bottom else ports.x
	if compact:
		var fit := horizontal_fit(id, south)
		return end * fit.z + fit.y
	return end

static func shaft_width(id: String, south: bool) -> float:
	var span: Vector2 = SHAFTS[id]
	return (span.y - span.x) * horizontal_fit(id,south).z

static func paired_fit(index: int) -> Vector3:
	var left: Vector2 = PAIRED_SHAFTS[index][0]
	var right: Vector2 = PAIRED_SHAFTS[index][1]
	var left_center := (left.x + left.y) * 0.5
	var right_center := (right.x + right.y) * 0.5
	var factor := WALL_PROFILE.CELL_PITCH.x / (right_center - left_center)
	var cap: Rect2 = WALL_PROFILE.CAP_REGIONS["south" if index >= 2 else "north"]
	var target := Vector2(cap.position.y, cap.end.y) * WALL_PROFILE.cap_scale(index >= 2)
	var native: Vector2 = PAIRED_PROFILES[index]
	return Vector3(41.0 - left_center * factor, (target.x + target.y - (native.x + native.y) * factor) * 0.5, factor)

static func paired_width(index: int, left: bool) -> float:
	var span: Vector2 = PAIRED_SHAFTS[index][0 if left else 1]
	return (span.y - span.x) * paired_fit(index).z

static func paired_index(left: String, right: String, south: bool) -> int:
	if left == "nw" and right == "se":
		return 3 if south else 0
	if left == "sw" and right == "ne":
		return 2 if south else 1
	return -1

static func paired_port(index: int, left: bool) -> Vector2:
	var port: Vector2 = PAIRED_PORTS[index][0 if left else 1]
	var fit := paired_fit(index)
	return port * fit.z + Vector2.ONE * fit.y
