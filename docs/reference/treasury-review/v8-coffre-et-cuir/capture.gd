extends "res://docs/reference/treasury-review/v7-reserve-en-relief/capture.gd"
const Styled = preload("res://docs/reference/treasury-review/v8-coffre-et-cuir/renderer.gd")

func review_directory() -> String:
	return "res://docs/reference/treasury-review/v8-coffre-et-cuir/"

func make_view() -> Node2D:
	return Styled.new()
