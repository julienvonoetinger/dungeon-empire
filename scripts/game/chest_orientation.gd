extends RefCounted
## Presentation only. No saved facing or influence on raid movement.
const Types = preload("res://scripts/game/game_types.gd")
const DIRECTIONS := [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]
const NAMES := ["south", "east", "north", "west"]

static func _clear(sim: DungeonSim, at: Vector2i) -> bool:
	if not sim._inside(at): return false
	var tile: int = sim.grid[at.y][at.x]
	return tile not in [Types.Tile.ROCK, Types.Tile.CORE, Types.Tile.VAULT, Types.Tile.ENTRANCE] and not sim._door_intact(at)

static func select(sim: DungeonSim, at: Vector2i) -> Dictionary:
	var best := -1
	var facing := "south"
	for i in DIRECTIONS.size():
		var direction: Vector2i = DIRECTIONS[i]
		var front := at + direction
		if not _clear(sim, front): continue
		var lateral := Vector2i(-direction.y, direction.x)
		var score := 4 * int(_clear(sim, front + direction))
		score += int(_clear(sim, front + lateral)) + int(_clear(sim, front - lateral))
		# Strict comparison preserves the S/E/N/W tie break, with no camera/actor input.
		if score > best:
			best = score
			facing = NAMES[i]
	return {"facing":facing, "accessible":best >= 0}

static func sprite_id(protected: bool, facing: String) -> String:
	var base := "prop-chest" if protected else "prop-chest-open"
	return base if facing == "south" else base + "-" + facing
