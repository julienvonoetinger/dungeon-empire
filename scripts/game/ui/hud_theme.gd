extends RefCounted

const GOLD := Color("d9b45c")
const INK := Color("1a1119")
const TEXT := Color("e8dcc8")
const MUTED := Color("beb1c7")
const ASSETS := "res://assets/ui/black-gold/"
const PAINTED := {"pick":"dig","hammer":"dig","spike":"spikes","door":"door","chest":"chest","locked":"locked","gem":"heart","void":"crystal"}
const ICON_REGIONS = preload("res://assets/ui/forge/icon_regions.gd")
static var _icons: Dictionary = {}

static func surface(file: String, margin: float = 12.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = preload("res://assets/ui/forge/stone.png")
	style.modulate_color = Color("d1b0ec") if file in ["selected","gold"] else Color.WHITE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 11)
		style.set_expand_margin(side, 0)
		style.set_content_margin(side, margin)
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style

static func flat(color: Color, radius: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

static func command_surface(selected: bool=false, margin: float=10) -> StyleBoxFlat:
	var style:=flat(Color("392340") if selected else INK,6)
	style.corner_detail=1
	style.border_color=Color("ba87d6") if selected else Color("91849a")
	style.set_border_width_all(2)
	style.set_content_margin_all(margin)
	return style

static func slim_scrollbar(scroll: ScrollContainer) -> void:
	for part in ["scroll", "scroll_focus", "grabber", "grabber_highlight", "grabber_pressed"]:
		var style := flat(Color("7b698e") if part.begins_with("grabber") else Color("151c2d"), 2)
		style.content_margin_left=2; style.content_margin_right=2
		style.content_margin_top=8; style.content_margin_bottom=8
		scroll.get_v_scroll_bar().add_theme_stylebox_override(part,style)

static func create() -> Theme:
	var theme := Theme.new()
	# The HUD compensates project stretch to retain physical touch targets.
	# MSDF keeps text sharp through that canvas scale, including portrait mode.
	var font := ThemeDB.fallback_font.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	theme.default_font = font
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color("070a10"))
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_stylebox("panel", "PanelContainer", surface("panel"))
	for state in ["normal", "hover", "pressed"]:
		theme.set_stylebox(state, "Button", command_surface(state == "pressed", 10))
	var disabled := command_surface(false,10)
	disabled.bg_color=Color("1d1920"); disabled.border_color=Color("514957")
	theme.set_stylebox("disabled", "Button", disabled)
	var focus := flat(Color.TRANSPARENT, 10)
	focus.border_color = Color("d2a4ff")
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", "Button", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", Color("a6a39f"))
	theme.set_constant("icon_max_width", "Button", 28)
	theme.set_constant("h_separation", "Button", 10)
	theme.set_constant("separation", "HBoxContainer", 8)
	theme.set_constant("separation", "VBoxContainer", 6)
	theme.set_stylebox("background", "ProgressBar", flat(Color("090d13"), 4))
	theme.set_stylebox("fill", "ProgressBar", flat(Color("965ccc"), 3))
	return theme

static func icon(name: String) -> Texture2D:
	if _icons.has(name): return _icons[name]
	if name in ["spike","snare","void"]:
		_icons[name]=load("res://assets/ui/master/trap-"+name+".png")
		return _icons[name]
	if name in ["catalog","path","prey"]: return load("res://assets/ui/master/"+name+".svg")
	if name=="health": return preload("res://assets/ui/forge/health.svg")
	if name=="coins": return preload("res://assets/ui/forge/coins.svg")
	if name in ["undo","eye"]: return load("res://assets/ui/forge/" + name + ".svg")
	if PAINTED.has(name):
		var cropped := AtlasTexture.new()
		cropped.atlas=load("res://assets/ui/forge/" + PAINTED[name] + ".png")
		cropped.region=ICON_REGIONS.REGIONS[PAINTED[name]]
		cropped.filter_clip=true
		_icons[name]=cropped
		return cropped
	return load(ASSETS + name + ".svg") as Texture2D

static func label(parent: Node, text: String, size: int = 16, color: Color = TEXT) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

static func button(parent: Node, text: String, action: Callable, glyph: String = "", gold: bool = false) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(48, 48)
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	if not glyph.is_empty(): item.icon = icon(glyph)
	if gold:
		for state in ["normal", "hover", "pressed"]:
			item.add_theme_stylebox_override(state, command_surface(true, 12))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			item.add_theme_color_override(state, TEXT)
	item.pressed.connect(func():
		if not item.get_meta("palette_dragging",false): action.call())
	parent.add_child(item)
	return item

## Icon above a short visible label: actions stay understandable without tooltips.
static func tile(parent: Node, glyph: String, text: String, action: Callable) -> Button:
	var item := button(parent, "", action)
	for state in ["normal","hover","pressed"]:
		var circle:=command_surface(state=="pressed",0)
		circle.set_corner_radius_all(28); circle.corner_detail=12
		item.add_theme_stylebox_override(state,circle)
	item.custom_minimum_size = Vector2(56, 58)
	item.tooltip_text = text
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	item.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8; box.offset_right = -8; box.offset_top = 5; box.offset_bottom = -5
	var mark := picture(box, glyph, 24)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var words := label(box, text, 11)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.set_meta("mark", mark)
	item.set_meta("words", words)
	return item

static func picture(parent: Node, glyph: String, extent: float = 36) -> TextureRect:
	var item := TextureRect.new()
	item.texture = icon(glyph)
	item.custom_minimum_size = Vector2.ONE * extent
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

static func bar(parent: Node, height: float = 10, gold: bool = false) -> ProgressBar:
	var item := ProgressBar.new()
	item.custom_minimum_size.y = height
	item.show_percentage = false
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gold: item.add_theme_stylebox_override("fill", flat(GOLD, 3))
	parent.add_child(item)
	return item
