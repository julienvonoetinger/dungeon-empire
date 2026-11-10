extends Node
## F6 starts at the artisans' departure after the spike trap is built.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
var game: IsometricGameSession

func _ready() -> void:
	game = GAME.instantiate()
	game.persistence_enabled = false
	add_child(game)
	game.restart(false,true)
	game.accept_village_gift()
	game.place_village_bag(Vector2i(7,7))
	game.place_village_bag(Vector2i(9,8))
	game.learn_from_artisan(GameTypes.Lesson.MEET_MINER)
	game.dig_cell(Vector2i(8,6))
	game.learn_from_artisan(GameTypes.Lesson.MEET_CARPENTER)
	game.select_cell(Vector2i(6,8))
	game.confirm_action(GameTypes.Tool.BUILD_DOOR)
	game.learn_from_artisan(GameTypes.Lesson.MEET_SCIENTIST)
	game.select_cell(Vector2i(5,8))
	game.confirm_action(GameTypes.Tool.TRAP_SPIKE)
