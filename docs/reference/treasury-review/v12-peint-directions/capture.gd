extends "res://docs/reference/treasury-review/v11-couloir/capture.gd"
const PaintedReserve = preload("res://docs/reference/treasury-review/v12-peint-directions/renderer.gd")

class CheckedReserve extends PaintedReserve:
	func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
		var sorted := super._ordered_parts(parts)
		var side: String = entrance.get("side", "")
		if side not in ["E", "S"]:
			return sorted
		var after_treasure := false
		var contact := INF
		var segments := 0
		for p in sorted:
			if p.id == "treasury-hoard":
				after_treasure = true
			var east_wall: bool = str(p.id).begins_with("wall-h-") and p.at.y == ROOM_ORIGIN.y and p.at.x >= ROOM_ORIGIN.x and p.at.x < ROOM_ORIGIN.x + 2
			var south_wall: bool = str(p.id).begins_with("wall-v-") and p.at.x == ROOM_ORIGIN.x and p.at.y >= ROOM_ORIGIN.y and p.at.y < ROOM_ORIGIN.y + 2
			if (side == "E" and east_wall) or (side == "S" and south_wall):
				var gap: float = anchor.y - support_half.y - p.max.y if side == "E" else anchor.x - support_half.x - p.max.x
				assert(gap >= -.00001 and not after_treasure, "Rear masonry must not cut through the painting")
				contact = minf(contact, gap)
				segments += 1
		assert(segments == 2 and absf(contact) < .00001)
		return sorted

func make_view() -> Node2D:
	return CheckedReserve.new()

func review_directory() -> String:
	return "res://docs/reference/treasury-review/v12-peint-directions/"

func check_placement(row: Dictionary, inward: Vector2) -> void:
	assert(view.draw_count == 1 and view.entrance.side == row.side and view.entrance.slot == row.slot)
	var paint: Dictionary = view.registrations[row.side]
	assert(paint.file == "reserve-" + str(row.side) + ".png")
	assert(view.tex is ImageTexture and view.tex == view.variants[row.side])
	assert(view.tex.get_size() == Vector2(paint.width, paint.height))
	if seen.has(row.side):
		assert(seen[row.side].tex == view.tex)
		var shift: Vector2 = view.anchor - seen[row.side].anchor
		if row.side in ["E", "S"]:
			assert(absf(shift.dot(view.entrance.axis)) < .001)
			assert(shift.dot(inward) < -.10)
		else:
			assert(shift.dot(view.entrance.axis) < -.10)
	else:
		for previous: Dictionary in seen.values():
			assert(previous.tex != view.tex)
		seen[row.side] = {"tex": view.tex, "anchor": view.anchor}
	assert((view.anchor - CENTER).dot(inward) + 1.0 - view.support_half.dot(inward.abs()) >= .28)
