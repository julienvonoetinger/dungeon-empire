extends StyleBox

func _draw(canvas_item: RID, rect: Rect2) -> void:
	var a := rect.position
	var b := rect.end
	var points := PackedVector2Array([
		a, Vector2(b.x, a.y), Vector2(b.x - 16, b.y - 8),
		Vector2(b.x - 28, b.y), Vector2(a.x + 28, b.y), Vector2(a.x + 16, b.y - 8)])
	RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([Color("080b0df5")]))
	points.append(points[0])
	RenderingServer.canvas_item_add_polyline(canvas_item, points, PackedColorArray([Color("a58649")]), 1.5, true)
