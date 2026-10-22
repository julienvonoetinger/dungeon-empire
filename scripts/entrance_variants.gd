extends Node2D

const LABELS := ["HAUT · NORD", "DROITE · EST", "BAS · SUD", "GAUCHE · OUEST"]
const CELLS := [Vector2i(3, 1), Vector2i(6, 3), Vector2i(3, 6), Vector2i(1, 3)]
const PANEL_SIZE := Vector2(560, 470)
const COMPOSITION := Vector2(1120, 940)


func _ready() -> void:
	for side in range(4):
		var map := DungeonLayout.new()
		map.margin = 140
		map.rows = PackedStringArray([
			"........", ".012345.", ".234567.", ".456701.",
			".670123.", ".012345.", ".234567.", "........",
		])
		map.entrance_enabled = true
		map.entrance_side = side as DungeonLayout.WallSide
		map.entrance_cell = CELLS[side]
		var panel := Vector2(side % 2, floori(side / 2.0)) * PANEL_SIZE
		var dungeon := DungeonView.new()
		dungeon.layout = map
		dungeon.scale = Vector2.ONE * 0.57
		dungeon.position = panel + Vector2(77, 50)
		add_child(dungeon)
		var label := Label.new()
		label.text = LABELS[side]
		label.position = panel + Vector2(0, 22)
		label.size.x = PANEL_SIZE.x
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 23)
		label.modulate = Color("b6c6df")
		add_child(label)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var available := get_viewport_rect().size
	var zoom := minf(available.x / COMPOSITION.x, available.y / COMPOSITION.y)
	scale = Vector2.ONE * zoom
	position = (available - COMPOSITION * zoom) * 0.5
