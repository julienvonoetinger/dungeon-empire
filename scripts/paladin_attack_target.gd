@tool
extends Node2D
## Geometric strike target only, not a new dungeon asset or damage system.
var top := PackedVector2Array()
var bottom := PackedVector2Array()
var impact_point := Vector2.ZERO
var flash := false:
	set(value):
		flash = value
		queue_redraw()

func top_center() -> Vector2:
	var center := Vector2.ZERO
	for point in top:
		center += point
	return center / maxf(1, top.size())

func _draw() -> void:
	if top.size() != 4 or bottom.size() != 4:
		return
	# Only the two camera-facing walls of the physical box.
	for i in 4:
		var j := (i+1) % 4
		if (top[i].y + top[j].y) * .5 < top_center().y - .01:
			continue
		var face := PackedVector2Array([top[i],top[j],bottom[j],bottom[i]])
		draw_colored_polygon(face, Color("28354c") if top[i].x < top[j].x else Color("35435d"))
		draw_polyline(PackedVector2Array([top[i],top[j],bottom[j],bottom[i],top[i]]),Color("101722"),1.5,true)
	draw_colored_polygon(top, Color("b591d3") if flash else Color("55627a"))
	var outline := top.duplicate()
	outline.append(top[0])
	draw_polyline(outline,Color("101722"),1.5,true)
	draw_arc(impact_point,6,0,TAU,24,Color("e2c2f4"),1.5,true)
	if flash:
		for direction in [Vector2(-1,-.7),Vector2(1,-.7),Vector2(0,-1)]:
			draw_line(impact_point + direction*9,impact_point + direction*19,Color("eed6ff"),2,true)
