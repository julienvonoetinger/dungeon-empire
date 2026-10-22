extends RefCounted

## Orthographic cap and solid masonry ends for a one-cell void separator.
## Full native-alpha regions, measured ports, uniform transforms, white tint.
const SOURCE := preload("res://assets/dungeon/modular-study/narrow-separator-v3.png")
const ENDS := preload("res://assets/dungeon/modular-study/solid-separator-ends-v8.png")
const PITCH := 476.0
const PARTS := {
	"straight": {"region": Rect2(0,0,1254,620), "body": Rect2(54,152,1151,393)},
	"left_end": {"region": Rect2(0,0,982,801), "body": Rect2(202,166,669,539),
		"cap_height": 316.0, "face_top": 322.0, "second_course": 422.0},
	"right_end": {"region": Rect2(982,0,982,801), "body": Rect2(1094,166,671,539),
		"cap_height": 316.0, "face_top": 322.0, "second_course": 422.0},
}
const HEIGHT := 393.0 * PITCH / 1151.0

static func factor(id: String) -> float:
	return HEIGHT / float(PARTS[id].get("cap_height",(PARTS[id].body as Rect2).size.y))

static func facade_top(id: String, lower := false) -> float:
	return float(PARTS[id].second_course if lower else PARTS[id].face_top) * factor(id)

static func course_height(id: String, lower := false) -> float:
	var part: Dictionary = PARTS[id]
	var native: float = (part.body as Rect2).size.y - part.second_course if lower else part.second_course - part.face_top
	return native * factor(id)

static func width(id: String) -> float:
	return (PARTS[id].body as Rect2).size.x * factor(id)

static func make(id: String, anchor: Vector2, art_scale: float) -> Sprite2D:
	var part: Dictionary = PARTS[id]
	var region: Rect2 = part.region
	var body: Rect2 = part.body
	var texture := AtlasTexture.new()
	texture.atlas = SOURCE if id == "straight" else ENDS
	texture.region = region
	texture.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = region.position - body.position
	sprite.position = anchor * art_scale
	sprite.scale = Vector2.ONE * art_scale * factor(id)
	sprite.z_index = 5
	sprite.set_meta("asset_id", "separator_" + id)
	return sprite
