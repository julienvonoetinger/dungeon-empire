extends RefCounted
## A level bedrock cut with a shared contour for its top and exposed section.
const Distance=preload("res://scripts/continuous_recess_geometry.gd")
const STEP:=.25

static func _outside(triangle: Array[Vector3]) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for i in triangle.size():
		var a:=triangle[i]; var b:=triangle[(i+1)%triangle.size()]
		if a.z>=0: result.append(a)
		if (a.z<0)!=(b.z<0):
			var crossing:=a.lerp(b,a.z/(a.z-b.z))
			crossing.z=0
			result.append(crossing)
	return result

static func build(cells: Array[Vector2i], margin: float, extent: Rect2) -> Dictionary:
	var occupied: Dictionary={}
	var bounds:=Rect2(Vector2.ZERO,Vector2.ONE)
	if not cells.is_empty(): bounds=Rect2(Vector2(cells[0]),Vector2.ONE)
	for cell in cells:
		occupied[cell]=true
		bounds=bounds.merge(Rect2(Vector2(cell),Vector2.ONE))
	bounds=bounds.grow(margin+STEP)
	var start:=Vector2(floorf(bounds.position.x/STEP),floorf(bounds.position.y/STEP))*STEP
	var end:=Vector2(ceilf(bounds.end.x/STEP),ceilf(bounds.end.y/STEP))*STEP
	var columns:=roundi((end.x-start.x)/STEP)+1
	var rows:=roundi((end.y-start.y)/STEP)+1
	var samples: Array[Vector3]=[]
	for y in rows:
		for x in columns:
			var p:=start+Vector2(x,y)*STEP
			samples.append(Vector3(p.x,p.y,Distance.distance_to_cells(p,occupied,margin+STEP)-margin))
	var top: Array[PackedVector2Array]=[]
	var edges: Array[PackedVector2Array]=[]
	for y in rows-1:
		for x in columns-1:
			var i:=y*columns+x
			for indices in [[i,i+1,i+columns+1],[i,i+columns+1,i+columns]]:
				var triangle: Array[Vector3]=[samples[indices[0]],samples[indices[1]],samples[indices[2]]]
				var polygon:=_outside(triangle)
				if polygon.size()<3: continue
				var face:=PackedVector2Array()
				for vertex in polygon: face.append(Vector2(vertex.x,vertex.y))
				top.append(face)
				for k in polygon.size():
					var a:=polygon[k]; var b:=polygon[(k+1)%polygon.size()]
					if absf(a.z)<.000001 and absf(b.z)<.000001 and a.distance_squared_to(b)>.00000001:
						edges.append(PackedVector2Array([Vector2(a.x,a.y),Vector2(b.x,b.y)]))
	# The sampling window joins the surrounding rock plane at the same height.
	for panel: Rect2 in [
		Rect2(extent.position,Vector2(extent.size.x,start.y-extent.position.y)),
		Rect2(Vector2(extent.position.x,end.y),Vector2(extent.size.x,extent.end.y-end.y)),
		Rect2(Vector2(extent.position.x,start.y),Vector2(start.x-extent.position.x,end.y-start.y)),
		Rect2(Vector2(end.x,start.y),Vector2(extent.end.x-end.x,end.y-start.y))]:
		top.append(PackedVector2Array([panel.position,Vector2(panel.end.x,panel.position.y),panel.end,Vector2(panel.position.x,panel.end.y)]))
	return {"top":top,"edges":edges,"contours":[],"margin":margin}
