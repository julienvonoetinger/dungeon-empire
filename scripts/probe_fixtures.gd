extends RefCounted

## Independently chosen sample positions for the approved six-room composition.
## Never derive expected positions from the pieces currently being checked.
static func floor_points(dungeon: Node2D) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for cell in dungeon.layout.get_floor_cells():
		points.append(dungeon.cell_position(cell)+Vector2(48,48))
	var cells: Array[Vector2i] = []
	for x in range(8,19):
		for y in [5,6]:
			cells.append(Vector2i(x,y))
	for y in range(3,11):
		for x in [12,13]:
			cells.append(Vector2i(x,y))
	for y in range(8,11):
		for x in [3,4]:
			cells.append(Vector2i(x,y))
	for x in range(15,20):
		for y in [13,14]:
			cells.append(Vector2i(x,y))
	for cell in cells:
		for offset in [Vector2(12,12),Vector2(84,12),Vector2(12,84),Vector2(84,84)]:
			points.append(dungeon.cell_position(cell)+offset)
	return points

static func entrance_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for x in [270,290,710,750,820,900]:
		for y in [275,315,365,435]:
			points.append(Vector2(x,y))
	return points

static func side_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for x in [187,220,250,2758,2780,2808]:
		for y in [450,480,514,515,564,565,600,650,680,740,800,850,880,915]:
			points.append(Vector2(x,y))
	for x in [187,220,250]:
		for y in [1218,1250,1282,1283,1332,1333,1400,1500,1600,1700,1750,1785]:
			points.append(Vector2(x,y))
	return points

static func volume_points() -> Array[Vector2]:
	return [Vector2(177,550),Vector2(177,1380),Vector2(2830,550),
		Vector2(228,714),Vector2(228,1516),Vector2(2784,760),Vector2(1275,580),Vector2(1530,580)]

static func east_samples() -> Array:
	return [
		[Vector2(2810,450),Vector2(332,664)], [Vector2(2810,510),Vector2(332,724)],
		[Vector2(2810,810),Vector2(332,665)], [Vector2(2810,870),Vector2(332,725)],
		[Vector2(2810,1218),Vector2(332,664)], [Vector2(2810,1278),Vector2(332,724)],
		[Vector2(2810,1578),Vector2(332,665)], [Vector2(2810,1638),Vector2(332,725)]
	]

static func heart_samples() -> Array[Vector2i]:
	return [Vector2i(1225,475),Vector2i(1240,603),Vector2i(1316,453),
		Vector2i(1297,434),Vector2i(1394,482),Vector2i(1315,517),
		Vector2i(1316,540),Vector2i(1280,587)]

static func definitions(dungeon: Node2D) -> Array[Dictionary]:
	var probes: Array[Dictionary] = []
	_append(probes,"floor",floor_points(dungeon),["floor"])
	_append(probes,"entrance",entrance_points(),["wall","entrance"])
	for point in [Vector2(480,451),Vector2(620,451)]:
		var probe := _point("entry-foot/%03d"%probes.size(),"entrance",point,["entrance"])
		probes.append(probe)
	for x in [430,662]:
		var probe := _point("torch-foot/%d"%x,"entrance",Vector2(x,451),["entrance"])
		probe["expected_uv"] = Vector2(128,314.75)
		probe["prefix"] = "EntryTorch"
		probes.append(probe)
	_append(probes,"side",side_points(),["wall","pier"])
	var volume := volume_points()
	for i in range(volume.size()):
		probes.append(_point("volume/%03d"%i,"side",volume[i],["wall"] if i < 3 else ["pier"]))
	for i in range(east_samples().size()):
		var sample: Array = east_samples()[i]
		var probe := _point("east/%03d"%i,"side",sample[0],["wall","pier"])
		probes.append(probe)
	for i in range(heart_samples().size()):
		var sample := Vector2(heart_samples()[i])
		var probe := _point("heart/%03d"%i,"heart",sample+Vector2(1052,238),["heart"])
		probes.append(probe)
	probes.append({"id":"heart/anchor","group":"heart","position":Vector2(2368,784),
		"anchor_path":"Heart","expected_kinds":["heart"]})
	return probes

static func _append(probes: Array[Dictionary],group: String,points: Array[Vector2],kinds: Array) -> void:
	for i in range(points.size()):
		probes.append(_point("%s/%03d"%[group,i],group,points[i],kinds))

static func _point(id: String,group: String,point: Vector2,kinds: Array) -> Dictionary:
	return {"id":id,"group":group,"position":point,"expected_kinds":kinds}
