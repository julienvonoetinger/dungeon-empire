extends RefCounted
## Registration of the four approved paintings in the ordinary isometric kit.
const TEXTURES := {
	"N": preload("res://assets/dungeon/secret-rooms/treasury/reserve-N.png"),
	"E": preload("res://assets/dungeon/secret-rooms/treasury/reserve-E.png"),
	"S": preload("res://assets/dungeon/secret-rooms/treasury/reserve-S.png"),
	"W": preload("res://assets/dungeon/secret-rooms/treasury/reserve-W.png"),
}
const INWARD := {"N":Vector2.DOWN, "E":Vector2.LEFT, "S":Vector2.UP, "W":Vector2.RIGHT}
const FACING := {"N":"north", "E":"east", "S":"south", "W":"west"}

static func placement(room: Dictionary, walls: Array[Dictionary]) -> Dictionary:
	var side: String = room.side
	var origin := Vector2(room.origin)
	var center := origin + Vector2.ONE
	var inward: Vector2 = INWARD[side]
	var axis := Vector2.RIGHT if inward.y != 0 else Vector2.DOWN
	var slide := .055 if room.slot == 0 else -.055
	var anchor := center + inward * .10 + axis * slide
	var half := inward.abs() * .81 + axis * .84
	if side in ["E","S"]:
		var prefix := "wall-h-" if side == "E" else "wall-v-"
		var face := origin.dot(axis)
		var footprint := Rect2i(room.origin, Vector2i(2,2))
		for wall in walls:
			var at: Vector2 = wall.at
			if str(wall.id).begins_with(prefix) and at.dot(axis) == origin.dot(axis) and footprint.has_point(Vector2i(at)):
				face = maxf(face, Vector2(wall.max.x,wall.max.y).dot(axis))
		half = inward.abs() * .71 + axis * .45
		anchor = center + axis * (face + .45 - center.dot(axis)) + inward * (.09 + slide)
	return {"anchor":anchor,"half":half}

static func part(room: Dictionary, walls: Array[Dictionary], view: Node2D) -> Dictionary:
	var fit := placement(room, walls)
	var anchor: Vector2 = fit.anchor
	var half: Vector2 = fit.half
	var side: String = room.side
	var texture: Texture2D = TEXTURES[side]
	var size := texture.get_size()
	var pin := Vector2(size.x / 2, roundf(size.y * .66))
	var eye: Vector3 = view.DEFINITION.get("view_direction")
	return {"id":"treasury-hoard", "room":room, "at":anchor, "texture":texture,
		"min":Vector3(anchor.x-half.x, anchor.y-half.y, 0), "max":Vector3(anchor.x+half.x, anchor.y+half.y, .65),
		"depth":anchor.dot(Vector2(eye.x,eye.y)), "rect":Rect2(view.grid_to_local(anchor) - pin, size)}
