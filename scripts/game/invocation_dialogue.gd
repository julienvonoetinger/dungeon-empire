extends PanelContainer
## Subtitles use the cinematic clock, including pause and backward seeking.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const RITUAL := [
	[10.0, 14.8, "L’invocateur", "Aldren a pris nos terres. Nos familles se terrent dans les grottes."],
	[15.0, 20.0, "L’invocateur", "Recevez notre serment. Donnez-nous la force de reprendre notre foyer !"],
	[22.2, 26.4, "Le Maître", "J’ai entendu votre appel. Ma puissance aura un prix : votre fidélité."],
	[26.6, 30.8, "Le Maître", "Sous cette montagne s’élèvera mon royaume. Suis-moi, invocateur."],
	[31.0, 35.0, "L’invocateur", "Je vous suis, Maître. Que les nôtres trouvent enfin un refuge."],
]
const ENTRANCE := [
	[1.0, 4.8, "L’invocateur", "Tout est à bâtir… La montagne nous cachera-t-elle d’Aldren ?"],
	[5.0, 8.9, "Le Maître", "Ce cœur abritera ma puissance. Défendez-le, et notre royaume grandira."],
]
var speaker := Label.new()
var words := Label.new()
var bottom_reserve := 0.0
var area := Rect2()
var ui_unit := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UI.surface("panel", 14))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	column.add_child(speaker)
	column.add_child(words)
	for label in [speaker, words]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speaker.add_theme_font_size_override("font_size", 16)
	words.add_theme_font_size_override("font_size", 20)
	minimum_size_changed.connect(_place, CONNECT_DEFERRED)
	hide()

func present(stage: String, time: float) -> void:
	var cues: Array = RITUAL if stage == "ritual" else ENTRANCE if stage == "entrance" else []
	for cue in cues:
		if time >= cue[0] and time < cue[1]:
			if speaker.text != cue[2] or words.text != cue[3]:
				speaker.text = cue[2]
				words.text = cue[3]
				speaker.add_theme_color_override("font_color", UI.ACCENT if cue[2] == "Le Maître" else UI.GOLD)
			show()
			_place()
			return
	hide()
	speaker.text = ""
	words.text = ""

func fit(safe_area: Rect2, unit: float) -> void:
	area = safe_area
	ui_unit = unit
	_place()

func _place() -> void:
	if area.size.x <= 0: return
	scale = Vector2.ONE * ui_unit
	size = Vector2(minf(680, area.size.x - 24), get_combined_minimum_size().y)
	position = Vector2(area.get_center().x-size.x*.5, area.end.y-size.y-12-bottom_reserve)*ui_unit
