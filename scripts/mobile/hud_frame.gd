extends StyleBox

@export var bg_color := Color("0b1012")
@export var border_color := Color("947440")

func _draw(canvas_item: RID, rect: Rect2) -> void:
	var cut := minf(12.0, rect.size.y * 0.2)
	var a := rect.position
	var b := rect.end
	var points := PackedVector2Array([
		Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y),
		Vector2(b.x, a.y + cut), Vector2(b.x, b.y - cut),
		Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y),
		Vector2(a.x, b.y - cut), Vector2(a.x, a.y + cut)])
	RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([bg_color]))
	points.append(points[0])
	RenderingServer.canvas_item_add_polyline(canvas_item, points, PackedColorArray([border_color]), 1.5, true)
