extends SceneTree

class GridFixture extends Node:
	enum Tile { ROCK, FLOOR }
	var grid := [[0, 0, 0, 0], [1, 1, 1, 1], [1, 1, 1, 1]]
	func _inside(p: Vector2i) -> bool:
		return p.x >= 0 and p.x < 4 and p.y >= 0 and p.y < 3

func _initialize() -> void:
	var world = load("res://scripts/world/dungeon_world.gd").new()
	var game := GridFixture.new()
	if not world.has_method("_wall_span"):
		printerr("FAIL: wall span grouping missing")
		world.free()
		game.free()
		quit(1)
		return
	assert(world._wall_span(Vector2i(0, 0), Vector2i.DOWN, game) == 2)
	assert(world._wall_span(Vector2i(1, 0), Vector2i.DOWN, game) == 0)
	# Excavating one of the pair must restore a single wall at its neighbour.
	game.grid[0][0] = game.Tile.FLOOR
	assert(world._wall_span(Vector2i(1, 0), Vector2i.DOWN, game) == 1)
	# A turn must never be bridged by a paired wall.
	game.grid[1][3] = game.Tile.ROCK
	assert(world._wall_span(Vector2i(2, 0), Vector2i.DOWN, game) == 1)
	# Map boundaries use the same grouping, but cannot cross a rock cell.
	assert(world._wall_span(Vector2i(0, 2), Vector2i.DOWN, game, true) == 2)
	game.grid[2][1] = game.Tile.ROCK
	assert(world._wall_span(Vector2i(0, 2), Vector2i.DOWN, game, true) == 1)
	world.free()
	game.free()
	print("OK: wall pairing, excavation, corners and map limits")
	quit()
