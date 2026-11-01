extends RefCounted
## A level bedrock cut with a shared contour for its top and exposed section.
const Distance=preload("res://scripts/continuous_recess_geometry.gd")
const STEP:=.25

static func _distance_to_profile(point: Vector2, profile: PackedVector2Array) -> float:
	var inside:=true
	var squared:=INF
	for i in profile.size():
		var a:=profile[i]; var edge:=profile[(i+1)%profile.size()]-a
		if edge.length_squared()<.0000001: continue
		var relative:=point-a
		if edge.cross(relative)<0: inside=false
		var nearest:=a+edge*clampf(relative.dot(edge)/edge.length_squared(),0,1)
		squared=minf(squared,point.distance_squared_to(nearest))
	return 0.0 if inside else sqrt(squared)

static func _distance_to_swept_cells(point: Vector2, cells: Dictionary, radius: float, setback: Vector2, profile: PackedVector2Array) -> float:
	if setback.is_zero_approx(): return Distance.distance_to_cells(point,cells,radius)
	var centre:=Vector2i(floori(point.x),floori(point.y))
	if cells.has(centre): return 0.0
	var distance:=radius
	var reach:=ceili(radius+maxf(setback.x,setback.y))
	for y in range(centre.y-reach,centre.y+reach+1):
		for x in range(centre.x-reach,centre.x+reach+1):
			if cells.has(Vector2i(x,y)):
				distance=minf(distance,_distance_to_profile(point-Vector2(x,y),profile))
	return distance

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

static func build(cells: Array[Vector2i], margin: float, extent: Rect2, setback: Vector2 = Vector2.ZERO) -> Dictionary:
	var occupied: Dictionary={}
	var bounds:=Rect2(Vector2.ZERO,Vector2.ONE)
	if not cells.is_empty(): bounds=Rect2(Vector2(cells[0]),Vector2.ONE)
	for cell in cells:
		occupied[cell]=true
		bounds=bounds.merge(Rect2(Vector2(cell),Vector2.ONE))
	# Sweep the opening towards the camera by the projection of wall height.
	# This makes room for the whole cube silhouette, not only its top footprint.
	bounds=bounds.merge(Rect2(bounds.position+setback,bounds.size))
	bounds=bounds.grow(margin+STEP)
	var start:=Vector2(floorf(bounds.position.x/STEP),floorf(bounds.position.y/STEP))*STEP
	var end:=Vector2(ceilf(bounds.end.x/STEP),ceilf(bounds.end.y/STEP))*STEP
	var columns:=roundi((end.x-start.x)/STEP)+1
	var rows:=roundi((end.y-start.y)/STEP)+1
	var samples: Array[Vector3]=[]
	var profile:=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.RIGHT+setback,Vector2.ONE+setback,Vector2.DOWN+setback,Vector2.DOWN])
	for y in rows:
		for x in columns:
			var p:=start+Vector2(x,y)*STEP
			samples.append(Vector3(p.x,p.y,_distance_to_swept_cells(p,occupied,margin+STEP,setback,profile)-margin))
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
	return {"top":top,"edges":edges,"contours":[],"margin":margin,"projection_setback":setback}
