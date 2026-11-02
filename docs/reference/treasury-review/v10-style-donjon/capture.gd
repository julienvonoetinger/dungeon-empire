extends "res://docs/reference/treasury-review/v9-sprite-unique/capture.gd"
const StyledTreasure = preload("res://docs/reference/treasury-review/v10-style-donjon/renderer.gd")

func make_view() -> Node2D:
	return StyledTreasure.new()

func review_directory() -> String:
	return "res://docs/reference/treasury-review/v10-style-donjon/"
