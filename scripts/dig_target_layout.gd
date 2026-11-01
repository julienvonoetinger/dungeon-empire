extends RefCounted
## Translate contiguous guide rows/columns together, without resizing cubes.

static func offsets(view: Node2D, cells: Array[Vector2i], clearance: float) -> Dictionary:
	var normals: Dictionary={}
	var result: Dictionary={}
	for cell in cells:
		var normal:=Vector2.ZERO
		for dir in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
			var neighbour: Vector2i=cell+dir
			if view.session.sim._inside(neighbour) and view.session.sim.grid[neighbour.y][neighbour.x]!=view.Types.Tile.ROCK:
				normal-=Vector2(dir)
		normals[cell]=normal
		result[cell]=Vector2.ZERO
	for axis in 2:
		var step:=Vector2i.RIGHT if axis==0 else Vector2i.DOWN
		for cell in cells:
			if normals.has(cell-step): continue
			var run: Array[Vector2i]=[]
			var cursor: Vector2i=cell
			var direction:=0.0
			while normals.has(cursor):
				run.append(cursor)
				direction+=normals[cursor][axis]
				cursor+=step
			# A corner's lateral retreat belongs to its whole row, otherwise it
			# compresses the pitch and intersects the next unchanged-size cube.
			for member in run:
				var offset: Vector2=result[member]
				offset[axis]=signf(direction)*clearance
				result[member]=offset
	return result
