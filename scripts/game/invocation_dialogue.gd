extends Control
## Speaker portraits shared by timed subtitles and reader-paced dialogue.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const PORTRAITS := {
	"L’invocateur": preload("res://assets/game/introduction/portraits/invoker.webp"),
	"Le Maître": preload("res://assets/game/introduction/portraits/master.webp"),
	"Les anciens": preload("res://assets/game/introduction/portraits/elders.webp"),
}
const RITUAL := [
	[10.0, 14.8, "L’invocateur", "Aldren a pris nos terres. Nos familles se terrent dans les grottes."],
	[15.0, 20.0, "L’invocateur", "Recevez notre serment. Donnez-nous la force de reprendre notre foyer !"],
	[22.2, 26.4, "Le Maître", "J’ai entendu votre appel. Ma puissance aura un prix : votre fidélité."],
	[26.7, 30.5, "L’invocateur", "Retournez aux grottes. Allez chercher les autres et ramenez-les ici !"],
	[32.6, 36.8, "Le Maître", "Sous cette montagne s’élèvera mon royaume. Suis-moi, invocateur."],
	[37.1, 40.2, "L’invocateur", "Je vous suis, Maître. Que les nôtres trouvent enfin un refuge."],
]
const ENTRANCE := [
	[1.0, 4.8, "L’invocateur", "Tout est à bâtir… La montagne nous cachera-t-elle d’Aldren ?"],
	[5.0, 8.9, "Le Maître", "Ce cœur abritera ma puissance. Défendez-le, et notre royaume grandira."],
	[9.3, 14.2, "L’invocateur", "Maître, chez nous, on apprend à manier les outils. Bien peu des nôtres savent tenir une épée."],
	[14.5, 18.8, "L’invocateur", "Mais nous vous avons donné notre parole. Tout ce que nos mains savent faire, nous le ferons pour vous."],
	[19.2, 23.4, "L’invocateur", "J’ai fait venir nos meilleurs artisans. Tenez, les voilà qui descendent."],
	[31.1, 36.1, "L’invocateur", "Approchez, mes amis. Maître, voici notre mineur, notre menuisier et notre scientifique."],
]
var speaker := Label.new()
var words := Label.new()
var portrait := TextureRect.new()
var band := Panel.new()
var nameplate := Panel.new()
var bottom_reserve := 0.0
var area := Rect2()
var ui_unit := 1.0
var embedded := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stone := UI.surface("panel", 14)
	for panel in [band, nameplate]:
		panel.add_theme_stylebox_override("panel", stone)
	portrait.name = "Portrait"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for control in [band, words, portrait, nameplate, speaker]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(control)
	if embedded:
		resized.connect(_place, CONNECT_DEFERRED)
	hide()

func present(stage: String, time: float) -> void:
	var cues: Array = RITUAL if stage == "ritual" else ENTRANCE if stage == "entrance" else []
	for cue in cues:
		if time >= cue[0] and time < cue[1]:
			show_line(cue[2], cue[3])
			return
	clear_line()

func show_line(who: String, text: String) -> void:
	if speaker.text != who or words.text != text:
		speaker.text = who
		words.text = text
		portrait.texture = PORTRAITS[who]
		speaker.add_theme_color_override("font_color", UI.ACCENT if who == "Le Maître" else UI.GOLD)
		_place()
	show()

func clear_line() -> void:
	hide()
	speaker.text = ""
	words.text = ""
	portrait.texture = null

func fit(safe_area: Rect2, unit: float) -> void:
	area = safe_area
	ui_unit = unit
	_place()

func _place() -> void:
	if not portrait.texture: return
	if embedded and size.x < 1.0: return
	if not embedded and not area.has_area(): return
	scale = Vector2.ONE * ui_unit
	var tall := area.size.y > area.size.x
	var margin := 4.0
	var width := size.x if embedded else area.size.x - 2.0 * margin
	# Inline passages follow the width of the reading column, including its scrollbar.
	var usable_height := clampf(width * .6, 190., 290.) if embedded else area.size.y - bottom_reserve
	var face_width := width * (.32 if tall else .23)
	if embedded:
		face_width = clampf(face_width, 64., 96.)
	var face_size := Vector2(portrait.texture.get_size())
	face_size *= minf(face_width / face_size.x, usable_height * (.23 if tall else .41) / face_size.y)
	speaker.add_theme_font_size_override("font_size", clampi(roundi(width * (.0355 if tall else .0222)), 12, 22))
	words.add_theme_font_size_override("font_size", 18 if embedded else clampi(roundi(width * (.0465 if tall else .0285)), 15, 26))
	var name_width := maxf(face_width, speaker.get_minimum_size().x + 16.0)
	var text_x := name_width + clampf(width * .023, 8., 28.)
	var pad := clampf(width * .029, 12., 28.)
	if embedded:
		pad = 12.
	words.size = Vector2(maxf(1., width - text_x - pad), 0.)
	var band_height := maxf(usable_height * (.13 if tall else .24), words.get_minimum_size().y + 2.0 * pad)
	var name_height := maxf(speaker.get_minimum_size().y + 12., usable_height * (.046 if tall else .085))
	var overlap := name_height * .65
	var height := ceilf(maxf(face_size.y + name_height, band_height + name_height - overlap))
	if embedded:
		custom_minimum_size.y = height
	else:
		size = Vector2(width, height)
		position = Vector2(area.position.x + margin, area.end.y - bottom_reserve - margin - height) * ui_unit
	nameplate.size = Vector2(name_width, name_height)
	nameplate.position = Vector2(0, height - name_height)
	speaker.position = nameplate.position
	speaker.size = nameplate.size
	portrait.size = face_size
	portrait.position = Vector2((name_width - face_size.x) * .5, nameplate.position.y - face_size.y)
	band.size = Vector2(width, band_height)
	band.position = Vector2(0, nameplate.position.y + overlap - band_height)
	words.position = band.position + Vector2(text_x, pad)
	words.size.y = band_height - 2.0 * pad
