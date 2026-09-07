extends Control

var menu: GameToolbar


func _draw() -> void:
	if menu != null:
		menu.draw_wheel(self)
