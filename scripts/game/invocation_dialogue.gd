extends Control
## Speaker portraits shared by timed subtitles and reader-paced dialogue.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const StoneBand = preload("res://scripts/game/ui/intro_stone_band.gd")
const PORTRAITS := {
	"L’invocateur": preload("res://assets/game/introduction/portraits/invoker.webp"),
	"Le Maître": preload("res://assets/game/introduction/portraits/master.webp"),
	"Les anciens": preload("res://assets/game/introduction/portraits/elders.webp"),
	"Le mineur": preload("res://assets/game/introduction/portraits/miner.webp"),
	"Le menuisier": preload("res://assets/game/introduction/portraits/carpenter.webp"),
	"Le scientifique": preload("res://assets/game/introduction/portraits/scientist.webp"),
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
	[9.3, 16.0, "L’invocateur", "Maître, les héros d’Aldren ont sûrement vu les éclairs du rituel depuis la vallée. Ils viendront en chercher la source."],
	[16.3, 23.0, "L’invocateur", "S’ils trouvent cet escalier, ils auront le champ libre jusqu’au Cœur. Préparons les défenses du donjon avant leur arrivée."],
	[23.3, 28.2, "L’invocateur", "Chez nous, on apprend à manier les outils. Bien peu des nôtres savent tenir une épée."],
	[28.5, 32.8, "L’invocateur", "Mais nous vous avons donné notre parole. Tout ce que nos mains savent faire, nous le ferons pour vous."],
	[33.2, 37.4, "L’invocateur", "J’ai fait venir nos meilleurs artisans. Tenez, les voilà qui descendent."],
	[45.1, 50.1, "L’invocateur", "Approchez, mes amis. Maître, voici notre mineur, notre menuisier et notre scientifique."],
]
var speaker := Label.new()
var words := Label.new()
var portrait := TextureRect.new()
var band := StoneBand.new()
var bottom_reserve := 0.0
var area := Rect2()
var ui_unit := 1.0
var embedded := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.name = "Portrait"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for control in [band, portrait, speaker, words]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(control)
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
	if not area.has_area(): return
	scale = Vector2.ONE * ui_unit
	var width := area.size.x
	var tall := area.size.y > width
	var inset := clampf(width * .018, 8., 24.)
	var gap := clampf(width * .016, 8., 20.)
	var face_width := clampf(width * (.26 if tall else .16), 72., 184.)
	var face_height := (area.size.y - bottom_reserve) * (.19 if tall else .30)
	if embedded:
		face_width = clampf(width * .20, 64., 90.)
		face_height = 85.
	var face_size := Vector2(portrait.texture.get_size())
	face_size *= minf(face_width / face_size.x, face_height / face_size.y)
	speaker.add_theme_font_size_override("font_size", clampi(roundi(width * (.0355 if tall else .0222)), 12, 22))
	words.add_theme_font_size_override("font_size", 18 if embedded else clampi(roundi(width * (.0465 if tall else .0285)), 15, 26))
	var speaker_size := speaker.get_minimum_size()
	var column := maxf(face_size.x, speaker_size.x)
	var text_x := inset + column + gap
	var pad_top := clampf(width * .01, 7., 11.)
	var pad_bottom := 5.
	words.size = Vector2(maxf(1., width - text_x - inset), 0.)
	var band_height := ceilf(maxf(words.get_minimum_size().y, speaker_size.y) + pad_top + pad_bottom)
	var name_bottom_gap := 3.
	var height := ceilf(maxf(face_size.y + speaker_size.y + name_bottom_gap, band_height))
	var content_left := area.position.x
	var canvas := get_parent_control().size / ui_unit
	var strip_width := canvas.x
	var bottom_inset := 0.
	if not embedded:
		if bottom_reserve == 0.: bottom_inset = maxf(0., canvas.y - area.end.y)
		position = Vector2(0, area.end.y - bottom_reserve - height) * ui_unit
	# The stone spans the viewport. Faces and lettering stay in the safe area.
	size = Vector2(strip_width, height + bottom_inset)
	speaker.position = Vector2(content_left + inset, height - name_bottom_gap - speaker_size.y)
	speaker.size = Vector2(column, speaker_size.y)
	portrait.size = face_size
	portrait.position = speaker.position + Vector2((column - face_size.x) * .5, -face_size.y)
	band.position = Vector2(0, height - band_height)
	band.size = Vector2(strip_width, band_height + bottom_inset)
	words.position = band.position + Vector2(content_left + text_x, pad_top)
	words.size.y = band_height - pad_top - pad_bottom
