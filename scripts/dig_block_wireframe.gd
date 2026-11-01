extends Node2D
## Approved review geometry, with generated painting registered face by face.
const Paint=preload("res://assets/previews/dig-blocks/paint.gd")
static var paintings: Array=Paint.variants()
var cell := Vector2i.ZERO
var faces: Array[PackedVector2Array] = []
var top_center := Vector2.ZERO
var support: Dictionary = {}
var pressed := false
var paint_index := 0

func configure(view: Node2D, at: Vector2i, height: float) -> void:
	cell=at
	# Stable cosmetic variety, independent of the gameplay RNG and camera.
	var pattern:=posmod(cell.x*73856093 ^ cell.y*19349663,11)
	paint_index=2 if pattern<2 else pattern%2
	# Keep the existing wall/pillar footprint clear instead of sharing its volume.
	var inset:=.13
	var bottom:=PackedVector2Array()
	var top:=PackedVector2Array()
	for offset in [Vector2(inset,inset),Vector2(1-inset,inset),Vector2(1-inset,1-inset),Vector2(inset,1-inset)]:
		bottom.append(view.grid_to_local(Vector2(cell)+offset))
		top.append(view.grid_to_local(Vector2(cell)+offset,height))
	faces=[PackedVector2Array([top[1],bottom[1],bottom[2],top[2]]),PackedVector2Array([top[2],bottom[2],bottom[3],top[3]]),top]
	top_center=view.grid_to_local(Vector2(cell)+Vector2(.5,.5),height)
	var rect:=Rect2(top[0],Vector2.ZERO)
	for point in top: rect=rect.expand(point)
	for point in bottom: rect=rect.expand(point)
	var direction: Vector3=view._definition.get("view_direction")
	support={"id":"dig-block","at":Vector2(cell),"min":Vector3(cell.x+inset,cell.y+inset,0),"max":Vector3(cell.x+1-inset,cell.y+1-inset,height),"rect":rect,"depth":(Vector2(cell)+Vector2(.5,.5)).dot(Vector2(direction.x,direction.y)),"node":self,"dig_cell":cell}
	z_index=1
	queue_redraw()

func covers(point: Vector2) -> bool:
	for face in faces:
		if Geometry2D.is_point_in_polygon(point,face): return true
	return false

func _draw() -> void:
	var colors: Array[Color]=[Color("202a3e"),Color("29364c"),Color("3c4963")]
	var paint: Dictionary=paintings[paint_index]
	# Match the native slate masonry; the source paintings remain untouched.
	var stone_tint:=Color(.82,.84,.90)
	var tint:=stone_tint.lightened(.14) if pressed else stone_tint
	for index in faces.size():
		draw_colored_polygon(faces[index],colors[index])
		draw_polygon(faces[index],PackedColorArray([tint]),paint.uvs[index],paint.texture)
	# Only the touched block receives a thin contour, with no permanent UI cage.
	if pressed and faces.size()==3:
		var contour:=faces[2].duplicate()
		contour.append(contour[0])
		draw_polyline(contour,Color("d4a7ee"),1.5,true)
