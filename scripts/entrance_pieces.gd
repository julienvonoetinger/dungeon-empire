extends RefCounted

## Native atlas contours for the reusable entrance, separate from the exact
## source-frame study. Each masonry contour encloses a whole painted stone.
static func cap() -> PackedVector2Array:
	return points([[366,155],[474,155],[482,163],[484,170],[483,190],
		[478,198],[368,198],[365,192],[365,163]])

static func face() -> PackedVector2Array:
	return points([[1310,173],[1401,173],[1407,180],[1407,218],
		[1401,226],[1354,224],[1346,226],[1316,225],[1310,219]])

static func narrow_face() -> PackedVector2Array:
	return points([[1283,173],[1301,173],[1308,179],[1308,218],
		[1303,225],[1282,225],[1280,218],[1280,181]])

static func fixtures() -> Array[Dictionary]:
	return [
		{"name":"ArchAndDoor","source":points([
			[151,350],[149,342],[151,321],[152,314],[152,248],
			[114,248],[110,239],[110,195],[115,184],[146,158],
			[174,151],[215,134],[220,132],[253,132],[272,142],
			[295,154],[313,154],[338,161],[352,181],[353,194],
			[326,220],[326,319],[327,340],[322,350],
			[292,350],[286,343],[185,343],[181,350]])}
	]

static func points(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for value: Array in values:
		result.append(Vector2(value[0],value[1]))
	return result
