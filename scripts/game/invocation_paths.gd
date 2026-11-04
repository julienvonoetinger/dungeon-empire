extends RefCounted
## Navigation from the approved scenery's ground footprints, with actor clearance.
const ORIGIN := Vector2(-600,180)
const STEP := 12.0
var grid := AStarGrid2D.new()
var blockers: Array[PackedVector2Array] = []
var bounds: Array[Rect2] = []
var origin:=ORIGIN

func _init(departure:=false) -> void:
	origin=Vector2(-700,-700) if departure else ORIGIN
	grid.region = Rect2i(0,0,130,425) if departure else Rect2i(0,0,101,340)
	grid.cell_size = Vector2.ONE*STEP
	grid.offset = origin
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var source = JSON.parse_string(FileAccess.get_file_as_string("res://assets/game/introduction/procession/obstacles.json"))
	if departure:
		var altar:=[]
		for i in 32:
			var angle:=TAU*i/32.
			altar.append([-6+cos(angle)*207.,7+sin(angle)*111.])
		source.append({"name":"Altar","points":altar})
	for item in source:
		if departure and item.name=="Paroi4": continue
		var shift:=Vector2.ZERO
		if departure and item.name=="Paroi8": shift=Vector2(256,0)
		if departure and item.name=="Eboulis13": shift=Vector2(128,0)
		var polygon := PackedVector2Array()
		# An ellipse on the ground plane: 38px lateral / 19px depth clearance.
		for p in item.points: polygon.append((Vector2(p[0],p[1])+shift)*Vector2(1,2))
		for inflated in Geometry2D.offset_polygon(polygon,38.0):
			var world_polygon := PackedVector2Array()
			for p in inflated: world_polygon.append(p*Vector2(1,.5))
			blockers.append(world_polygon)
			var box := Rect2(world_polygon[0],Vector2.ZERO)
			for p in world_polygon: box=box.expand(p)
			bounds.append(box)
			var first := Vector2i(((box.position-origin)/STEP).floor())
			var last := Vector2i(((box.end-origin)/STEP).ceil())
			for y in range(maxi(0,first.y),mini(grid.region.end.y,last.y+1)):
				for x in range(maxi(0,first.x),mini(grid.region.end.x,last.x+1)):
					var id := Vector2i(x,y)
					if Geometry2D.is_point_in_polygon(grid.get_point_position(id),world_polygon): grid.set_point_solid(id)

func clear(point: Vector2) -> bool:
	for i in blockers.size():
		if bounds[i].has_point(point) and Geometry2D.is_point_in_polygon(point,blockers[i]): return false
	return true

func segment_clear(a: Vector2,b: Vector2) -> bool:
	var steps := maxi(1,ceili(a.distance_to(b)/4.0))
	for i in range(steps+1):
		if not clear(a.lerp(b,float(i)/steps)): return false
	return true

func spawn_below(minimum: Vector2) -> Vector2:
	# Screen edges vary by aspect ratio; an offscreen point can still be a rock.
	var point := minimum
	for attempt in 200:
		var free := true
		for x in [-STEP,0.0,STEP]:
			for y in [-STEP,0.0,STEP]:
				free = free and clear(point+Vector2(x,y))
		if free: return point
		point.y+=STEP
	assert(false,"No clear offscreen spawn")
	return minimum

func _nearest_free(point: Vector2) -> Vector2i:
	var nearest := Vector2i(((point-origin)/STEP).round())
	var best := Vector2i(-1,-1)
	var distance := INF
	for y in range(nearest.y-3,nearest.y+4):
		for x in range(nearest.x-3,nearest.x+4):
			var id := Vector2i(x,y)
			if not grid.region.has_point(id) or grid.is_point_solid(id): continue
			var position := grid.get_point_position(id)
			if point.distance_squared_to(position)<distance and segment_clear(point,position):
				best=id
				distance=point.distance_squared_to(position)
	assert(best != Vector2i(-1,-1),"No clear navigation anchor near %s" % point)
	return best

func route(start: Vector2,finish: Vector2) -> PackedVector2Array:
	var a := _nearest_free(start)
	var b := _nearest_free(finish)
	assert(clear(start) and clear(finish),"Ritual formation must stand clear of scenery")
	var raw := grid.get_point_path(a,b)
	assert(not raw.is_empty(),"No clear route from %s to %s" % [start,finish])
	if raw.is_empty(): return PackedVector2Array([start])
	raw.insert(0,start)
	raw.append(finish)
	var result := PackedVector2Array([start])
	var current := 0
	while current < raw.size()-1:
		var next := raw.size()-1
		while next>current+1 and not segment_clear(raw[current],raw[next]): next-=1
		assert(segment_clear(raw[current],raw[next]),"Route clearance failed")
		result.append(raw[next])
		current=next
	return result

static func sample(path: PackedVector2Array, progress: float) -> Vector2:
	var total := 0.0
	for i in range(1,path.size()): total+=path[i-1].distance_to(path[i])
	var remaining := clampf(progress,0,1)*total
	for i in range(1,path.size()):
		var distance := path[i-1].distance_to(path[i])
		if remaining<=distance: return path[i-1].lerp(path[i],remaining/maxf(distance,.0001))
		remaining-=distance
	return path[path.size()-1]
