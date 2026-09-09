extends SceneTree

const MainScript := preload("res://scripts/Main.gd")
const TEST_CELL := Vector2i(1, 1)

func _initialize() -> void:
	var game: Node = MainScript.new()
	root.add_child(game)
	await process_frame
	game._new_map()
	if not _check_damage(game, game.Tile.SPIKE, "thief", 68, 38):
		return
	if not _check_damage(game, game.Tile.SPIKE, "ranger", 82, 52):
		return
	if not _check_damage(game, game.Tile.SPIKE, "paladin", 115, 95):
		return
	if not _check_damage(game, game.Tile.SNARE, "thief", 68, 52):
		return
	print("OK: traps apply the intended damage to every hero archetype")
	quit()

func _check_damage(game: Node, tile: int, kind: String, starting_hp: int, expected_hp: int) -> bool:
	game.grid[TEST_CELL.y][TEST_CELL.x] = tile
	game.trap_charges[TEST_CELL] = game._trap_max_charges(tile)
	game.raid_stats = {"traps_spent": 0}
	game.hero = {
		"kind": kind,
		"hp": starting_hp,
		"max_hp": starting_hp,
		"fleeing": false,
		"move_cd": 0.0,
		"carried_gold": 0,
	}
	game._resolve_cell(TEST_CELL)
	if int(game.hero["hp"]) != expected_hp:
		printerr("FAIL: %s on %s should end at %d HP, got %d" % [kind, game.Tile.keys()[tile], expected_hp, int(game.hero["hp"])])
		quit(1)
		return false
	return true
