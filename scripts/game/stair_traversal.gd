extends RefCounted
## Feet follow the five treads used by isometric_kit_geometry.cjs. The mouth
## points towards the low/open side; canonical south descends along +Y.
const Types = preload("res://scripts/game/game_types.gd")
const RISERS = [.3013333333, .436, .5706666667, .7053333333, .84]
const TOP_TRAVEL := .38

static func sample(sim: DungeonSim, hero: Dictionary, at: Vector2, departure_from := Vector2(INF,INF)) -> Dictionary:
	var opacity := 1.0
	if hero.get("entering", false) or hero.get("exiting", false):
		var cell: Vector2i = hero.pos
		var mouth := Vector2(sim._entrance_mouth(cell))
		var entering: bool = hero.get("entering", false)
		var timer: float = hero.get("enter_t", 0) if entering else hero.get("exit_t", 0)
		var progress := clampf(1-timer/Types.TURN_TIME, 0, 1)
		var center := Vector2(cell)+Vector2(.5,.5)
		var top := center-mouth*TOP_TRAVEL
		var departure: Vector2 = departure_from if departure_from.is_finite() else center
		at = top.lerp(center,progress) if entering else departure.lerp(top,progress)
		# Only the remote endpoint fades, never the passage across the steps.
		# Use distance, since a failed pick beside the stairs starts farther away.
		opacity = smoothstep(0,TOP_TRAVEL*.28,(at-top).dot(mouth))
	var stair := Vector2i(at.floor())
	var elevation := 0.0
	if sim._inside(stair) and sim.grid[stair.y][stair.x] == Types.Tile.ENTRANCE:
		var u := (at-Vector2(stair)-Vector2(.5,.5)).dot(Vector2(sim._entrance_mouth(stair)))+.5
		# Narrow riser transitions keep the held walk poses from snapping in Y.
		for edge: float in RISERS: elevation += .05*(1-smoothstep(edge-.025,edge+.025,u))
	else:
		stair = Vector2i(-1,-1)
	return {"at":at,"elevation":elevation,"opacity":opacity,"stair":stair}
