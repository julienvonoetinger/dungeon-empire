extends BaseButton
## A selectable floor tile for a gift, door or spike.
var icon: Texture2D
var view: Node2D
var gift := false
var icon_offset := Vector2.ZERO

func find_visible_floor(center: Vector2, extent: Vector2) -> bool:
	# A low wall can hide the middle of a floor diamond. Put the invitation
	# on the exposed stone so tapping its coin always reaches this tile.
	for radius in [0., .16, .29, .40]:
		for axis in [Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN]:
			icon_offset = axis * extent * radius
			var point := center + icon_offset
			if not view.solid_covers_point(point) and not view.solid_covers_point(point + Vector2(0,4)) and not view.solid_covers_point(point - Vector2(0,4)):
				return true
	return false

func _has_point(point: Vector2) -> bool:
	if size.x <= 0. or size.y <= 0.: return false
	var delta := (point - size*.5).abs() / (size*.5)
	if delta.x + delta.y > 1.: return false
	var screen := get_global_transform_with_canvas() * point
	return not view.solid_covers_point(view.get_global_transform_with_canvas().affine_inverse()*screen)

func paint_on_floor(floor_node: Node2D, at: Vector2, extent: Vector2, world_per_ui: float) -> void:
	var half := extent*.5
	var corners := PackedVector2Array([at+Vector2(0,-half.y),at+Vector2(half.x,0),at+Vector2(0,half.y),at+Vector2(-half.x,0)])
	var active := is_hovered() or has_focus() or is_pressed()
	var fill := Color("ab792c") if gift else Color("7d40c4")
	fill.a = .55 if active else .30
	floor_node.draw_colored_polygon(corners,fill)
	corners.append(corners[0])
	floor_node.draw_polyline(corners, Color("f6d48f") if gift or active else Color("c99aef"),1.6*world_per_ui,true)
	var icon_size := Vector2(icon.get_size())
	icon_size *= minf(extent.y*.78,34.*world_per_ui) / maxf(icon_size.x,icon_size.y)
	floor_node.draw_texture_rect(icon,Rect2(at+icon_offset-icon_size*.5,icon_size),false)
