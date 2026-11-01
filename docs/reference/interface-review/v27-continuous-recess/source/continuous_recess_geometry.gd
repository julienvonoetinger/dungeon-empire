extends RefCounted
## A single continuous height field around the union of excavated cells.
const Terrain=preload("res://scripts/game/dungeon_terrain.gd")
const STEP:=.25
const RAMP_WIDTH:=.80

static func distance_to_cells(point: Vector2, cells: Dictionary, radius: float) -> float:
	var centre:=Vector2i(floori(point.x),floori(point.y))
	if cells.has(centre): return 0.0
	var distance:=radius
	var reach:=ceili(radius)
	for y in range(centre.y-reach,centre.y+reach+1):
		for x in range(centre.x-reach,centre.x+reach+1):
			if not cells.has(Vector2i(x,y)): continue
			var dx:=maxf(float(x)-point.x,maxf(0,point.x-float(x+1)))
			var dy:=maxf(float(y)-point.y,maxf(0,point.y-float(y+1)))
			distance=minf(distance,sqrt(dx*dx+dy*dy))
	return distance

static func build(cells: Array[Vector2i], margin: float, height: float, extent: Rect2) -> Dictionary:
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
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var colors:=PackedColorArray()
	var heights:=PackedFloat32Array()
	var top: Array[PackedVector2Array]=[]
	var inner:=maxf(0,margin-RAMP_WIDTH)
	for y in rows:
		for x in columns:
			var point:=start+Vector2(x,y)*STEP
			var distance:=distance_to_cells(point,occupied,margin)
			var level:=clampf((distance-inner)/(margin-inner),0,1)*height
			uvs.append(point); heights.append(level); vertices.append(Terrain.project(point,level))
	var light:=Vector3(-.6,-.4,1).normalized()
	for y in rows:
		for x in columns:
			var i:=y*columns+x
			var dx: float=(heights[y*columns+mini(columns-1,x+1)]-heights[y*columns+maxi(0,x-1)])/(STEP*2)
			var dy: float=(heights[mini(rows-1,y+1)*columns+x]-heights[maxi(0,y-1)*columns+x])/(STEP*2)
			var normal:=Vector3(-dx,-dy,1).normalized()
			var shade:=clampf(.86+.14*normal.dot(light)/light.z,.68,1.08)
			colors.append(Color(shade,shade,shade,heights[i]/height))
			if x==columns-1 or y==rows-1: continue
			for triangle in [[i,i+1,i+columns+1],[i,i+columns+1,i+columns]]:
				indices.append_array(PackedInt32Array(triangle))
				if heights[triangle[0]]>=height-.00001 and heights[triangle[1]]>=height-.00001 and heights[triangle[2]]>=height-.00001:
					top.append(PackedVector2Array([uvs[triangle[0]],uvs[triangle[1]],uvs[triangle[2]]]))
	# Four large flat panels finish the fixed world coverage, sharing the same
	# height/UVs as the sampled region. No tall standalone border-face sprites.
	var panels: Array[Rect2]=[
		Rect2(extent.position,Vector2(extent.size.x,start.y-extent.position.y)),
		Rect2(Vector2(extent.position.x,end.y),Vector2(extent.size.x,extent.end.y-end.y)),
		Rect2(Vector2(extent.position.x,start.y),Vector2(start.x-extent.position.x,end.y-start.y)),
		Rect2(Vector2(end.x,start.y),Vector2(extent.end.x-end.x,end.y-start.y))]
	for panel in panels:
		var corners:=PackedVector2Array([panel.position,Vector2(panel.end.x,panel.position.y),panel.end,Vector2(panel.position.x,panel.end.y)])
		var offset:=vertices.size()
		for point in corners:
			uvs.append(point); heights.append(height); vertices.append(Terrain.project(point,height)); colors.append(Color.WHITE)
		for index in [0,1,2,0,2,3]: indices.append(offset+index)
		top.append(corners)
	return {"top":top,"contours":[],"vertices":vertices,"uvs":uvs,"indices":indices,"colors":colors,"heights":heights,"sample_count":rows*columns,"inner_margin":inner,"margin":margin}
