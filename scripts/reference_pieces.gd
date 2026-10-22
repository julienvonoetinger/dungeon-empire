extends RefCounted

## Source-space contours of separate elements, in unscaled atlas pixels.
## This is a fixed composition, not a procedural tile adjacency table.
## The illumination painted on each stone and floor element is preserved.
const FRAME := Rect2i(0, 120, 560, 510)

static func build() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	var floor_outline := _points([
		[0,344], [394,344], [394,396], [448,396], [448,376], [560,376],
		[560,558], [554,558], [554,545], [542,534], [491,534], [480,544], [480,630], [338,630], [338,510], [328,500],
		[282,500], [270,508], [270,522], [74,522], [74,515], [65,508],
		[68,496], [68,445], [58,435], [6,435], [0,440]
	])
	# Slabs retain their native dimensions. Clip where walls occlude the floor.
	var xs := [0, 72, 176, 272, 382, 487, 560]
	var ys := [344, 438, 524, 630]
	for row in range(ys.size() - 1):
		for col in range(xs.size() - 1):
			var tile := _rect(xs[col], ys[row], xs[col + 1] - xs[col], ys[row + 1] - ys[row])
			var clipped := Geometry2D.intersect_polygons(tile, floor_outline)
			for n in range(clipped.size()):
				_add(pieces, "Floor_%d_%d_%d" % [col, row, n], "floor", clipped[n])
	_add(pieces, "BackLeftCapA", "wall", _rect(0, 153, 46, 46))
	_add(pieces, "BackLeftCapB", "wall", _points([[46,153],[175,153],[114,194],[114,199],[46,199]]))
	_add(pieces, "BackLeftLipA", "wall", _rect(0, 199, 46, 50))
	_add(pieces, "BackLeftLipB", "wall", _rect(46, 199, 68, 44))
	_add(pieces, "BackLeftFaceA", "wall", _rect(0, 249, 46, 62))
	_add(pieces, "BackLeftFaceB", "wall", _rect(0, 311, 47, 33))
	_add(pieces, "BackLeftFaceC", "wall", _rect(46, 294, 50, 50))
	# Fixture patches include their sockets and locally illuminated stone.
	_add(pieces, "TorchWest", "fixture", _points([[47,243],[114,243],[114,221],[154,221],[154,344],[96,344],[96,294],[47,294]]))
	_add(pieces, "TorchEast", "fixture", _rect(324, 221, 70, 123))
	_add(pieces, "ArchShoulderWest", "wall", _points([[114,194],[147,158],[175,153],[190,178],[205,179],[184,191],[164,213],[155,239],[154,268],[154,344],[152,344],[152,221],[114,221]]))
	_add(pieces, "ArchCrownWest", "wall", _points([[175,153],[215,134],[219,132],[227,172],[230,172],[205,179],[190,178]]))
	_add(pieces, "ArchCrownCenter", "wall", _points([[219,132],[255,132],[269,142],[258,175],[227,172]]))
	_add(pieces, "ArchCrownEast", "wall", _points([[269,140],[292,153],[313,153],[304,187],[281,184],[258,175]]))
	_add(pieces, "ArchShoulderEast", "wall", _points([[313,153],[338,160],[352,180],[352,194],[324,221],[324,249],[316,225],[304,202],[281,184],[304,187]]))
	_add(pieces, "ArchStoneRing", "entrance", _points([
		[154,344],[152,320],[154,268],[155,239],[164,213],[184,191],
		[205,179],[230,172],[258,175],[281,184],[304,202],[316,225],
		[324,249],[324,344],[287,344],[288,262],[286,242],[279,226],
		[266,215],[249,211],[229,212],[208,218],[192,231],[184,249],
		[184,268],[184,344]
	]))
	_add(pieces, "WoodenDoor", "entrance", _points([
		[184,344],[184,268],[184,249],[192,231],[208,218],[229,212],
		[249,211],[266,215],[279,226],[286,242],[288,262],[287,344]
	]))
	_add(pieces, "BackRightCap", "wall", _points([[337,155],[477,155],[484,169],[483,198],[394,198],[394,194],[352,194],[352,180],[337,162]]))
	_add(pieces, "BackRightLip", "wall", _points([[352,194],[394,194],[394,221],[324,221]]))
	_add(pieces, "BackRightReturn", "wall", _rect(448, 198, 35, 62))
	_add(pieces, "EntryPierUpper", "pier", _points([[394,194],[440,194],[448,204],[448,244],[394,244]]))
	_add(pieces, "EntryPierMiddle", "pier", _rect(394,244,54,57))
	_add(pieces, "EntryPierLower", "pier", _rect(394,301,54,43))
	_add(pieces, "EntryPierDiamond", "pier", _points([[394,344],[448,344],[448,388],[443,396],[400,396],[394,388]]))
	_add(pieces, "CorridorCap", "wall", _points([[448,258],[530,258],[535,263],[541,258],[560,258],[560,286],[448,286]]))
	_add(pieces, "CorridorLip", "wall", _rect(448,286,112,27))
	_add(pieces, "CorridorFaceUpper", "wall", _rect(448,313,112,31))
	_add(pieces, "CorridorFaceLower", "wall", _rect(448,344,112,32))
	# Foreground elements occlude floor and extend their faces toward the viewer.
	_add(pieces, "FrontWestCap", "pier", _points([[0,440],[6,435],[58,435],[68,445],[68,496],[64,508],[10,515],[0,505]]))
	_add(pieces, "FrontWestCorner", "pier", _points([[10,515],[60,506],[74,515],[74,574],[25,576],[17,568]]))
	_add(pieces, "FrontWestFace", "wall", _points([[0,505],[17,510],[17,568],[25,576],[74,574],[74,618],[0,618]]))
	_add(pieces, "FrontWallLipA", "wall", _rect(74,522,93,52))
	_add(pieces, "FrontWallLipB", "wall", _rect(167,522,103,52))
	_add(pieces, "FrontWallFaceA", "wall", _rect(74,574,93,42))
	_add(pieces, "FrontWallFaceB", "wall", _rect(167,574,103,46))
	_add(pieces, "FrontInnerLeftReturn", "wall", _points([[254,621],[270,616],[270,630],[254,630]]))
	_add(pieces, "FrontInnerPierTop", "pier", _points([[270,508],[282,500],[328,500],[338,510],[338,568],[328,578],[279,578],[270,570]]))
	_add(pieces, "FrontInnerPierFace", "pier", _points([[270,570],[279,578],[328,578],[338,568],[338,630],[270,630]]))
	_add(pieces, "FrontOuterPier", "pier", _points([[480,544],[491,534],[542,534],[554,545],[554,630],[480,630]]))
	_add(pieces, "FrontOuterReturn", "wall", _rect(554,558,6,72))
	return pieces

static func _points(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in values:
		result.append(Vector2(point[0], point[1]))
	return result

static func _rect(x: float, y: float, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x,y), Vector2(x+width,y), Vector2(x+width,y+height), Vector2(x,y+height)])

static func _add(pieces: Array[Dictionary], label: String, kind: String, source: PackedVector2Array) -> void:
	pieces.append({"name":label, "kind":kind, "source":source})
