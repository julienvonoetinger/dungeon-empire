extends RefCounted

## Whole generated silhouettes and transparent gutters; measurements only
## determine anchors and UNIFORM scale, never masks or image modifications.
const CAPS := preload("res://assets/dungeon/modular-study/cap-muted-v11.png")
const CORNERS := preload("res://assets/dungeon/modular-study/cap-square-v3.png")
const SIDE_ART := preload("res://scripts/modular_side_kit.gd")
const FLOOR := preload("res://assets/dungeon/modular-study/floor-calm-v3.png")
const FLOOR_SUPPORT := preload("res://assets/dungeon/modular-study/floor-calm-support-v1.png")
const FACADE := preload("res://assets/dungeon/modular-study/brick-muted-v3.png")
const PARTS := {
	"nw": [Rect2(0, 0, 365, 435), Vector2(66, 85)],
	"north": [Rect2(365, 0, 525, 435), Vector2(386, 150)],
	"ne": [Rect2(890, 0, 364, 435), Vector2(1187, 85)],
	"west": [Rect2(0, 435, 365, 380), Vector2(118, 505)],
	"east": [Rect2(890, 435, 364, 380), Vector2(1135, 505)],
	"sw": [Rect2(0, 815, 365, 439), Vector2(65, 1005)],
	"south": [Rect2(365, 815, 525, 439), Vector2(387, 902)],
	"se": [Rect2(890, 815, 364, 439), Vector2(1188, 1005)],
	"floor_0": [Rect2(0, 0, 310, 320), Vector2(48, 66)],
	"floor_1": [Rect2(310, 0, 400, 320), Vector2(338, 66)],
	"floor_2": [Rect2(710, 0, 544, 320), Vector2(739, 66)],
	"floor_3": [Rect2(0, 320, 310, 280), Vector2(48, 344)],
	"floor_4": [Rect2(310, 320, 400, 280), Vector2(339, 344)],
	"floor_5": [Rect2(710, 320, 544, 280), Vector2(739, 344)],
	"floor_6": [Rect2(0, 600, 310, 290), Vector2(48, 639)],
	"floor_7": [Rect2(310, 600, 400, 290), Vector2(338, 639)],
	"floor_8": [Rect2(710, 600, 544, 290), Vector2(739, 638)],
	"floor_9": [Rect2(0, 890, 310, 364), Vector2(48, 924)],
	"floor_10": [Rect2(310, 890, 400, 364), Vector2(339, 924)],
	"floor_11": [Rect2(710, 890, 544, 364), Vector2(739, 924)],
	"brick_0": [Rect2(0, 0, 780, 350), Vector2(101, 128)],
	"brick_half_0": [Rect2(780, 0, 474, 350), Vector2(816, 128)],
	"brick_1": [Rect2(0, 350, 780, 280), Vector2(101, 403)],
	"brick_half_1": [Rect2(780, 350, 474, 280), Vector2(815, 402)],
	"brick_2": [Rect2(0, 630, 780, 270), Vector2(101, 677)],
	"brick_half_2": [Rect2(780, 630, 474, 270), Vector2(815, 677)],
	"brick_3": [Rect2(0, 900, 780, 354), Vector2(101, 951)],
	"brick_half_3": [Rect2(780, 900, 474, 354), Vector2(815, 951)],
}
const BODY := {
	"floor_0": Vector2(237, 235), "floor_1": Vector2(351, 235),
	"floor_2": Vector2(468, 234), "floor_3": Vector2(236, 238),
	"floor_4": Vector2(350, 238), "floor_5": Vector2(468, 238),
	"floor_6": Vector2(236, 236), "floor_7": Vector2(351, 237),
	"floor_8": Vector2(469, 237), "floor_9": Vector2(235, 244),
	"floor_10": Vector2(349, 243), "floor_11": Vector2(468, 243),
	"brick_0": Vector2(644, 194), "brick_half_0": Vector2(339, 194),
	"brick_1": Vector2(644, 193), "brick_half_1": Vector2(341, 194),
	"brick_2": Vector2(644, 194), "brick_half_2": Vector2(341, 194),
	"brick_3": Vector2(644, 195), "brick_half_3": Vector2(341, 195),
}

static func make(id: String, uniform_scale: float, shaded_floor := false) -> Sprite2D:
	var slot: Rect2 = PARTS[id][0]
	var anchor: Vector2 = PARTS[id][1]
	var texture := AtlasTexture.new()
	texture.atlas = CAPS
	if id in ["nw", "ne", "sw", "se"]:
		texture.atlas = CORNERS
	elif id.begins_with("floor_"):
		texture.atlas = FLOOR_SUPPORT if shaded_floor else FLOOR
	elif id.begins_with("brick"):
		texture.atlas = FACADE
	texture.region = slot
	texture.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = slot.position - anchor
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.set_meta("asset_id", id)
	return sprite
