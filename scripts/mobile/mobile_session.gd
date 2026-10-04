extends Control

const Profile = preload("res://scripts/game/core_progression.gd")
const Router = preload("res://scripts/mobile/mobile_input_router.gd")
const Commands = preload("res://scripts/mobile/mobile_build.gd")
const SAVE_PATH := "user://mobile_run_v1.save"
const UI_PREFS_PATH := "user://mobile_ui.cfg"
const Tool := GameTypes.Tool
const GREEN := Color("65d9ad")
const GOLD := Color("f1cb72")
const RED := Color("f17b82")
const TOOLS := [
	[Tool.STORE, "Réserve", GameTypes.COST_VAULT],
	[Tool.STORE_LOCKED, "Verrou", 40],
	[Tool.STORE_MAGIC, "Runique", 80],
	[Tool.TRAP_SPIKE, "Pointes", 35],
	[Tool.TRAP_SNARE, "Entrave", 30],
	[Tool.TRAP_VOID, "Néant", 45],
	[Tool.BUILD_DOOR, "Porte", 40],
	[Tool.BUILD_MAGIC_DOOR, "Sceau", 80],
	[Tool.BUILD_ENTRANCE, "Entrée", 0]]
const CATEGORIES := [[Tool.BUILD_DOOR, Tool.BUILD_MAGIC_DOOR, Tool.BUILD_ENTRANCE], [Tool.STORE, Tool.STORE_LOCKED, Tool.STORE_MAGIC], [Tool.TRAP_SPIKE, Tool.TRAP_SNARE, Tool.TRAP_VOID]]

var g
var profile = Profile.new()
var router = Router.new()
var commands = Commands.new()
var camera_rules = preload("res://scripts/mobile/mobile_camera_controller.gd").new()
var save_api
var tool := Tool.NONE
var selected := Vector2i(-1, -1)
var preview := {}
var dig_hover := Vector2i(-1, -1)
var dig_hover_valid := false
var diggable_cells: Array[Vector2i] = []
var dig_hint: PanelContainer
var _dig_pointer := Vector2(-1, -1)
var _dig_pointer_over_ui := true
var following := false
var result_open := false
var paused := false
var top: PanelContainer
var bottom: PanelContainer
var tray_toggle: Button
var tray_collapsed := true
var actions: PanelContainer
var cameras: VBoxContainer
var navigation: HBoxContainer
var status_panel: PanelContainer
var core_panel: PanelContainer
var menu_button: Button
var pause_button: Button
var walls_button: Button
var _anchor_layout := false
var wealth: Label
var integrity: Label
var level_label: Label
var phase: Label
var raid_emblem: TextureRect
var detail: Label
var confirm: Button
var collect: Button
var raid_button: Button
var follow_button: Button
var modal: ColorRect
var modal_title: Label
var modal_body: Label
var modal_continue: Button
var modal_cancel: Button
var buttons := {}
var icons := {}
var badge_icons := {}
var _last_size := Vector2.ZERO
var _refresh_time := 0.0
var _modal_action := "continue"
var _save_failed := false
var display_font: Font
var portraits := {}
var hero_badge: Control
var vault_badges: Dictionary = {}
var vault_transfer: ColorRect
var trap_badges: Dictionary = {}
var door_badges: Dictionary = {}
var vault_layer: Control
var core_badge: Control
var category := 0
var category_buttons: Array[Button] = []
var damage_popups: Array = []
var _previous_hero_hp := -1
var _previous_core_hp := 100
var _normal_tool_style: StyleBox
var _selected_tool_style: StyleBox
var _pre_raid_view := {}
var build_options: HBoxContainer
var _raid_layout := false
var _memory_log_wait := 0.0
var _diagnostics: RefCounted
var _diagnostics_saved := true
var _copy_current_button: Button
var _copy_previous_button: Button

func _ready() -> void:
	profile.testing_unlock_defenses = bool(ProjectSettings.get_setting("testing/unlock_defenses", false))
	if OS.is_debug_build() and (OS.has_feature("android") or "--memory-probe" in OS.get_cmdline_user_args()) and g.persistence_enabled:
		_diagnostics = preload("res://scripts/mobile/mobile_diagnostics.gd").new()
		_diagnostics_saved = _diagnostics.begin("user://mobile_memory_v2.json") == OK
	g.raid.solid_core = true
	if g.persistence_enabled:
		_load_tray_preference()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/mobile/cinzel.ttf"):
		display_font = load("res://assets/mobile/cinzel.ttf")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icons = preload("res://scripts/mobile/ui_icons.gd").load_icons()
	badge_icons = preload("res://scripts/mobile/ui_icons.gd").load_badge_icons(icons)
	var portrait_atlas: Texture2D = load("res://assets/mobile/hero-portraits-v1.png")
	var kinds := ["thief", "paladin", "ranger", "mage"]
	for index in 4:
		var portrait := AtlasTexture.new()
		portrait.atlas = portrait_atlas
		portrait.region = Rect2(Vector2(index % 2, index / 2) * Vector2(portrait_atlas.get_size() / 2), portrait_atlas.get_size() / 2)
		portraits[kinds[index]] = portrait
	_build_ui()
	vault_transfer = preload("res://scripts/mobile/vault_transfer.gd").new()
	add_child(vault_transfer)
	vault_transfer.setup(self)
	router.tapped.connect(_tap)
	router.painted.connect(_dig_stroke)
	router.panned.connect(_pan)
	router.pinched.connect(_zoom)
	router.rotated.connect(_rotate)
	router.cancelled.connect(_cancel)
	g.raid.raid_finished.connect(_raid_finished)
	var restored := false
	if ResourceLoader.exists("res://scripts/mobile/mobile_save.gd"):
		save_api = load("res://scripts/mobile/mobile_save.gd")
		if g.persistence_enabled:
			var data: Dictionary = save_api.read_save(SAVE_PATH)
			if not data.is_empty():
				restored = save_api.apply(data, g.sim, g.raid, profile)
	if not restored:
		_save()
	g.cam_zoom = 2.0
	g.cam_yaw = 45.0
	g._cam_custom = true
	_layout()
	g._sync_world()
	_center_core()
	if not g._has_core():
		selected = Vector2i(6, 6)
		_update_preview()
	if g.game_over:
		_show_defeat_recovery()
	_refresh()
	if _diagnostics != null and not _diagnostics.previous.is_empty():
		_pause_menu()

func _is_empty_dungeon() -> bool:
	if g.grid.is_empty():
		return false
	for row in g.grid:
		for tile in row:
			if int(tile) != GameTypes.Tile.ROCK:
				return false
	return true

func _style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBox:
	var style := preload("res://scripts/mobile/hud_frame.gd").new()
	style.bg_color = color
	style.border_color = border
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _label(text: String, size_px: int = 20, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display_font != null and size_px >= 18:
		label.add_theme_font_override("font", display_font)
	return label

func _button(text: String, callback: Callable, tip: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tip
	button.custom_minimum_size = Vector2(64, 56)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("fff0d0"))
	button.add_theme_stylebox_override("normal", _style(Color("101619"), Color("947440")))
	button.add_theme_stylebox_override("hover", _style(Color("303132"), GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("454039"), GOLD))
	button.add_theme_stylebox_override("disabled", _style(Color("202224"), Color("333638")))
	button.pressed.connect(callback)
	return button

func _band() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("080c0ff5"), Color("947440")))
	add_child(panel)
	return panel

func _build_ui() -> void:
	vault_layer = Control.new()
	vault_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vault_layer)
	core_badge = preload("res://scripts/mobile/core_badge.gd").new()
	core_badge.icon = badge_icons[11]
	core_badge.hide()
	vault_layer.add_child(core_badge)
	hero_badge = preload("res://scripts/mobile/hero_badge.gd").new()
	hero_badge.hide()
	vault_layer.add_child(hero_badge)
	dig_hint = _band()
	dig_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dig_hint.size = Vector2(98, 38)
	var dig_row := HBoxContainer.new()
	dig_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dig_row.add_theme_constant_override("separation", 6)
	dig_hint.add_child(dig_row)
	var dig_icon := TextureRect.new()
	dig_icon.texture = icons[Tool.DIG]
	var dig_ink := Shader.new()
	dig_ink.code = "shader_type canvas_item; void fragment() { COLOR = vec4(0.945, 0.796, 0.447, texture(TEXTURE, UV).a * COLOR.a); }"
	var dig_material := ShaderMaterial.new()
	dig_material.shader = dig_ink
	dig_icon.material = dig_material
	dig_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dig_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dig_icon.custom_minimum_size = Vector2(22, 22)
	dig_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dig_row.add_child(dig_icon)
	dig_row.add_child(_label("%d or" % GameTypes.COST_DIG, 16, GOLD))
	dig_hint.hide()
	_normal_tool_style = _style(Color("101619"), Color("947440"))
	_selected_tool_style = _style(Color("252326"), GOLD)
	top = _band()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	top.add_child(header)
	var coin := TextureRect.new()
	coin.texture = icons[10]
	coin.custom_minimum_size = Vector2(48, 48)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(coin)
	wealth = _label("", 20, Color("fff0d0"))
	header.add_child(wealth)
	core_panel = _band()
	var core_info := VBoxContainer.new()
	core_panel.add_child(core_info)
	integrity = _label("", 20, GREEN)
	core_info.add_child(integrity)
	level_label = _label("", 14)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	core_info.add_child(level_label)
	pause_button = _button("II", _pause_menu, "Pause")
	add_child(pause_button)
	menu_button = _button("☰", func(): cameras.visible = not cameras.visible, "Commandes de vue")
	add_child(menu_button)
	status_panel = _band()
	var raid_frame := preload("res://scripts/mobile/raid_frame.gd").new()
	raid_frame.content_margin_left = 28
	raid_frame.content_margin_right = 28
	raid_frame.content_margin_top = 8
	raid_frame.content_margin_bottom = 8
	status_panel.add_theme_stylebox_override("panel", raid_frame)
	var status_row := HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 14)
	status_panel.add_child(status_row)
	raid_emblem = TextureRect.new()
	raid_emblem.texture = preload("res://scripts/mobile/menu_icon.gd").centered(load("res://assets/mobile/raid-skull-v2.png"))
	raid_emblem.custom_minimum_size = Vector2(48, 48)
	raid_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	raid_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	raid_emblem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	raid_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(raid_emblem)
	phase = _label("", 18, GOLD)
	phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_row.add_child(phase)
	bottom = _band()
	bottom.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tray_toggle = _button("←", _toggle_tray, "Retour aux catégories")
	tray_toggle.custom_minimum_size = Vector2(56, 104)
	tray_toggle.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var tab_style := tray_toggle.get_theme_stylebox(state).duplicate() as StyleBox
		tab_style.content_margin_left = 4
		tab_style.content_margin_right = 4
		tab_style.content_margin_top = 0
		tab_style.content_margin_bottom = 0
		tray_toggle.add_theme_stylebox_override(state, tab_style)
	var tray := VBoxContainer.new()
	bottom.add_child(tray)
	var options := HBoxContainer.new()
	build_options = options
	options.add_theme_constant_override("separation", 16)
	tray.add_child(options)
	options.add_child(tray_toggle)
	navigation = HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 12)
	add_child(navigation)
	for index in 3:
		var button := _button("", func(): _category(index), ["Portes", "Coffres", "Pièges"][index])
		button.custom_minimum_size = Vector2(150, 104)
		var contents := VBoxContainer.new()
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(contents)
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_top = 6
		var picture := TextureRect.new()
		picture.texture = preload("res://scripts/mobile/menu_icon.gd").centered(icons[[Tool.BUILD_DOOR, Tool.STORE, Tool.TRAP_SPIKE][index]])
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(56, 64)
		picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(picture)
		var caption := _label(["PORTES", "COFFRES", "PIÈGES"][index], 18, Color("fff0d0"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contents.add_child(caption)
		navigation.add_child(button)
		category_buttons.append(button)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	scroll.add_child(row)
	for entry in TOOLS:
		var id: int = entry[0]
		var button := _button("", func(): _choose_tool(id), entry[1])
		button.custom_minimum_size = Vector2(132, 104)
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(box)
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 6)
		var image := TextureRect.new()
		image.texture = preload("res://scripts/mobile/menu_icon.gd").centered(icons[id])
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(56, 56)
		image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(image)
		var label := _label("%s %s" % [entry[1], str(entry[2]) if entry[2] else ""], 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(label)
		buttons[id] = {"button": button, "label": label, "entry": entry}
		row.add_child(button)
	actions = _band()
	var action_row := HBoxContainer.new()
	actions.add_child(action_row)
	detail = _label("", 18)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action_row.add_child(detail)
	collect = _button("Collecter", _collect)
	action_row.add_child(collect)
	confirm = _button("Confirmer", _confirm)
	action_row.add_child(confirm)
	action_row.add_child(_button("X", _cancel, "Annuler"))
	cameras = VBoxContainer.new()
	cameras.add_theme_constant_override("separation", 10)
	cameras.hide()
	add_child(cameras)
	cameras.add_child(_button("+", func(): _zoom(size * 0.5, 1.2), "Zoom avant"))
	cameras.add_child(_button("-", func(): _zoom(size * 0.5, 1.0 / 1.2), "Zoom arriere"))
	cameras.add_child(_button("↶", func(): _rotate(-1), "Rotation gauche"))
	cameras.add_child(_button("↷", func(): _rotate(1), "Rotation droite"))
	var core_button := _button("", _center_core, "Recentrer sur le Cœur")
	core_button.icon = icons[11]
	core_button.expand_icon = true
	core_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core_button.add_theme_constant_override("icon_max_width", 40)
	cameras.add_child(core_button)
	follow_button = _button("", _toggle_follow, "Suivre le héros")
	follow_button.icon = portraits.thief
	follow_button.expand_icon = true
	follow_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	follow_button.add_theme_constant_override("icon_max_width", 44)
	cameras.add_child(follow_button)
	walls_button = _button("▦", func(): g.dungeon.set_mobile_walls_visible(not g.dungeon.mobile_walls_visible), "Afficher / masquer les murs")
	walls_button.toggle_mode = true
	walls_button.button_pressed = g.dungeon.mobile_walls_visible
	cameras.add_child(walls_button)
	cameras.add_child(_button("⟲", _request_restart, "Recommencer le donjon"))
	raid_button = _button("Raid", _start_raid)
	add_child(raid_button)
	for camera_button in cameras.get_children():
		camera_button.custom_minimum_size = Vector2(56, 44)
	modal = ColorRect.new()
	modal.color = Color(0.02, 0.03, 0.04, 0.8)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 340)
	panel.add_theme_stylebox_override("panel", _style(Color("20272a"), GOLD))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	modal_title = _label("", 30, GOLD)
	content.add_child(modal_title)
	modal_body = _label("", 22)
	modal_body.custom_minimum_size = Vector2(520, 170)
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(modal_body)
	modal_continue = _button("Continuer", _continue)
	content.add_child(modal_continue)
	modal_cancel = _button("Annuler", _cancel_restart)
	content.add_child(modal_cancel)
	modal_cancel.hide()
	if _diagnostics != null:
		_copy_current_button = _button("Copier diagnostic actuel", func(): _copy_diagnostic(false))
		content.add_child(_copy_current_button)
		_copy_previous_button = _button("Copier diagnostic precedent", func(): _copy_diagnostic(true))
		_copy_previous_button.disabled = _diagnostics.previous.is_empty()
		content.add_child(_copy_previous_button)
	modal.hide()

func _layout() -> void:
	var inset := Vector4(12, 10, 12, 10)
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var physical := Vector2(DisplayServer.window_get_size())
		if physical.x > 0 and safe.size.x > 0:
			var scale := size / physical
			inset.x = maxf(inset.x, safe.position.x * scale.x)
			inset.y = maxf(inset.y, safe.position.y * scale.y)
			inset.z = maxf(inset.z, (physical.x - safe.end.x) * scale.x)
			inset.w = maxf(inset.w, (physical.y - safe.end.y) * scale.y)
	top.position = Vector2(inset.x, inset.y)
	top.size = Vector2(200, 64)
	core_panel.position = Vector2(inset.x + 212, inset.y)
	core_panel.size = Vector2(184, 64)
	status_panel.size = Vector2(300, 64)
	status_panel.position = Vector2((size.x - 300) * 0.5, 0)
	if status_panel.position.x < core_panel.get_rect().end.x + 12:
		status_panel.position.y += maxf(top.size.y, core_panel.size.y) + 12
	menu_button.position = Vector2(size.x - inset.z - 64, inset.y)
	pause_button.position = menu_button.position - Vector2(72, 0)
	_anchor_layout = not g._has_core()
	build_options.visible = not g.raid_active and not _anchor_layout and not tray_collapsed
	navigation.size = Vector2(474, 104)
	navigation.position = Vector2((size.x - navigation.size.x) * 0.5, size.y - inset.w - 104)
	navigation.visible = not _anchor_layout and not g.raid_active and tray_collapsed
	bottom.size = Vector2(minf(72 + CATEGORIES[category].size() * 140, size.x - inset.x - inset.z), 104)
	bottom.position = Vector2((size.x - bottom.size.x) * 0.5, navigation.position.y)
	actions.size = Vector2(minf(650, size.x - 160), 64)
	actions.position = Vector2((size.x - actions.size.x) * 0.5, bottom.position.y - 80)
	if _anchor_layout:
		actions.position.y = size.y - inset.w - 72
	cameras.position = Vector2(size.x - inset.z - 64, inset.y + 64)
	cameras.size.x = 64
	raid_button.position = Vector2(size.x - inset.z - 88, size.y - inset.w - 56)
	raid_button.size = Vector2(88, 56)
	g._world_host.size = size
	_last_size = size
	_raid_layout = g.raid_active
	_align_header_height()

func _clock_text(seconds: float) -> String:
	var total := maxi(0, floori(seconds))
	return "%02d:%02d" % [total / 60, total % 60]

func _align_header_height() -> void:
	var height := 64.0
	for panel in [top, core_panel, status_panel]:
		height = maxf(height, panel.get_combined_minimum_size().y)
	for panel in [top, core_panel, status_panel]:
		panel.size.y = height

func _toggle_tray() -> void:
	if _anchor_layout or g.raid_active or modal.visible:
		return
	tray_collapsed = not tray_collapsed
	tool = Tool.NONE
	_cancel()
	if g.persistence_enabled:
		_save_tray_preference()
	_layout()
	_refresh()

func _load_tray_preference(path: String = UI_PREFS_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) == OK:
		var value: Variant = config.get_value("interface", "tray_collapsed", true)
		tray_collapsed = value if value is bool else true

func _save_tray_preference(path: String = UI_PREFS_PATH) -> Error:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("interface", "tray_collapsed", tray_collapsed)
	return config.save(path)

func tick(delta: float) -> void:
	walls_button.set_pressed_no_signal(g.dungeon.mobile_walls_visible)
	walls_button.tooltip_text = "Masquer les murs" if g.dungeon.mobile_walls_visible else "Afficher les murs"
	var memory := memory_diagnostics(delta, _diagnostics != null)
	if not memory.is_empty():
		_diagnostics_saved = _diagnostics.append(memory) == OK
		print("[DungeonMemory] ", JSON.stringify(memory))
	if size != _last_size or _raid_layout != g.raid_active or _anchor_layout == g._has_core():
		_layout()
	if not paused and not result_open:
		if g.raid_active:
			g._update_hero(delta)
		elif not g.game_over and g._ready_for_raid() and selected.x < 0:
			g.raid_timer = maxf(0, g.raid_timer - delta)
			if g.raid_timer <= 0:
				_start_raid()
	if following and g.raid_active and not g.hero.is_empty():
		_center(g.hero.pos)
	g._sync_world()
	_sync_vault_badges()
	_update_dig_hover()
	_sync_trap_badges()
	_sync_core_badge()
	_sync_door_badges()
	_sync_hero_badge()
	for popup in damage_popups:
		popup.time -= delta
	damage_popups = damage_popups.filter(func(popup): return popup.time > 0)
	if g.raid_active and not g.hero.is_empty():
		var hp: int = g.hero.hp
		if _previous_hero_hp >= 0 and hp < _previous_hero_hp:
			damage_popups.append({"point": g._cell_pos(g.hero.pos), "text": "-%d" % (_previous_hero_hp - hp), "time": 1.0})
		_previous_hero_hp = hp
	else:
		_previous_hero_hp = -1
	_refresh_time -= delta
	if _refresh_time <= 0:
		_refresh_time = 0.1
		_refresh()
	queue_redraw()

func _sync_vault_badges() -> void:
	var vaults: Dictionary = g._storage_state()["vaults"]
	for cell in vault_badges.keys():
		if not vaults.has(cell):
			vault_badges[cell].queue_free()
			vault_badges.erase(cell)
	var camera: Camera3D = g.dungeon.camera
	if camera == null:
		return
	var viewport_size := Vector2(camera.get_viewport().size)
	for cell in vaults:
		if not vault_badges.has(cell):
			var badge := preload("res://scripts/mobile/vault_badge.gd").new()
			badge.icon = badge_icons[10]
			vault_layer.add_child(badge)
			var hit := Button.new()
			badge.add_child(hit)
			hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			for state in ["normal", "hover", "pressed", "focus"]:
				hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
			hit.tooltip_text = "G\u00e9rer ce coffre"
			hit.pressed.connect(func(): vault_transfer.open(cell))
			vault_badges[cell] = badge
		var badge: Control = vault_badges[cell]
		badge.set_amount(int(vaults[cell]), GameTypes.VAULT_CAPACITY)
		badge.set_protection(int(g.sim.vault_locks.get(cell, 0)), g.sim.vault_protected(cell))
		_place_world_badge(badge, cell, 0.49, camera, viewport_size)

func _sync_trap_badges() -> void:
	var traps := {}
	for y in g.grid.size():
		for x in g.grid[y].size():
			var tile := int(g.grid[y][x])
			if g._is_trap_tile(tile):
				traps[Vector2i(x, y)] = tile
	for cell in trap_badges.keys():
		if not traps.has(cell):
			trap_badges[cell].queue_free()
			trap_badges.erase(cell)
	var camera: Camera3D = g.dungeon.camera
	if camera == null:
		return
	var viewport_size := Vector2(camera.get_viewport().size)
	var trap_icons := {GameTypes.Tile.SPIKE: Tool.TRAP_SPIKE, GameTypes.Tile.SNARE: Tool.TRAP_SNARE, GameTypes.Tile.VOID: Tool.TRAP_VOID}
	for cell in traps:
		if not trap_badges.has(cell):
			var badge := preload("res://scripts/mobile/trap_badge.gd").new()
			badge.repair_requested.connect(_repair_trap.bind(cell))
			vault_layer.add_child(badge)
			trap_badges[cell] = badge
		var badge: Control = trap_badges[cell]
		var next_icon: Texture2D = badge_icons[trap_icons[traps[cell]]]
		if badge.icon != next_icon:
			badge.icon = next_icon
			badge.queue_redraw()
		var capacity: int = g._trap_max_charges(traps[cell])
		badge.set_amount(maxi(0, int(g.trap_charges.get(cell, capacity))), capacity)
		badge.repair_button.disabled = g.raid_active or g.game_over or result_open or g.gold < GameTypes.COST_REPAIR_TRAP
		badge.repair_button.tooltip_text = "10 or par charge"
		var active: bool = g.dungeon._trap_sprung(cell, g, badge.amount == 0)
		var elevation := 0.35
		if traps[cell] == GameTypes.Tile.SPIKE and active:
			elevation = 0.6
		elif traps[cell] == GameTypes.Tile.SNARE:
			elevation = 1.0 if active else 0.6 if badge.amount == 0 else 0.35
		_place_world_badge(badge, cell, elevation, camera, viewport_size, 21.0)

func _repair_trap(cell: Vector2i) -> void:
	if g.raid_active or g.game_over or result_open or modal.visible:
		return
	if g.sim.repair_trap(cell) > 0:
		_save()
		g._sync_world()
		_sync_trap_badges()
		_refresh()

func _sync_hero_badge() -> void:
	if not g.raid_active or g.hero.is_empty() or g.dungeon.camera == null:
		hero_badge.hide()
		return
	hero_badge.set_hero(g.hero, portraits.get(str(g.hero.get("kind", "thief"))))
	var camera: Camera3D = g.dungeon.camera
	var screen: Vector2 = g.dungeon.hero_screen_anchor(0.7) * size / Vector2(camera.get_viewport().size)
	hero_badge.position = screen - Vector2(21, hero_badge.size.y + 8)
	_update_badge_visibility(hero_badge)
	# Keep the moving hero label readable over nearby structure badges.
	if hero_badge.visible:
		for badge in vault_badges.values() + trap_badges.values() + door_badges.values() + [core_badge]:
			if badge.visible and badge.get_rect().intersects(hero_badge.get_rect()):
				badge.hide()

func _sync_core_badge() -> void:
	if not g._has_core() or g.dungeon.camera == null:
		core_badge.hide()
		return
	core_badge.set_amount(clampi(g.core_hp, 0, GameTypes.CORE_MAX), GameTypes.CORE_MAX)
	var camera: Camera3D = g.dungeon.camera
	var center_offset := Vector3(g.CORE_W * 0.5 - 0.5, 0.0, g.CORE_H * 0.5 - 0.5)
	_place_world_badge(core_badge, g._core_origin(), 1.20, camera, Vector2(camera.get_viewport().size), -1.0, center_offset)

func _sync_door_badges() -> void:
	var doors := {}
	for y in g.grid.size():
		for x in g.grid[y].size():
			if g.sim._is_door_tile(int(g.grid[y][x])):
				doors[Vector2i(x, y)] = int(g.grid[y][x])
	for cell in door_badges.keys():
		if not doors.has(cell):
			door_badges[cell].queue_free()
			door_badges.erase(cell)
	var camera: Camera3D = g.dungeon.camera
	if camera == null:
		return
	for cell in doors:
		if not door_badges.has(cell):
			var badge := preload("res://scripts/mobile/trap_badge.gd").new()
			badge.repair_requested.connect(_repair_door.bind(cell))
			vault_layer.add_child(badge)
			door_badges[cell] = badge
		var badge: Control = door_badges[cell]
		var icon: Texture2D = badge_icons[Tool.BUILD_MAGIC_DOOR if doors[cell] == GameTypes.Tile.MAGIC_DOOR else Tool.BUILD_DOOR]
		if badge.icon != icon:
			badge.icon = icon
			badge.queue_redraw()
		var hp := clampi(int(g.door_hp.get(cell, GameTypes.DOOR_MAX_HP)), 0, GameTypes.DOOR_MAX_HP)
		badge.set_amount(hp, GameTypes.DOOR_MAX_HP)
		badge.set_repair_visible(hp == 0 or bool(g.door_opened.get(cell, false)))
		badge.repair_button.disabled = g.raid_active or g.game_over or result_open or g.gold < GameTypes.COST_REPAIR_DOOR
		badge.repair_button.tooltip_text = "15 or"
		_place_world_badge(badge, cell, 0.85, camera, Vector2(camera.get_viewport().size), 21.0)

func _repair_door(cell: Vector2i) -> void:
	if g.raid_active or g.game_over or result_open or modal.visible:
		return
	if g.sim.repair_door(cell):
		_save()
		g._sync_world()
		_sync_door_badges()
		_refresh()

func _place_world_badge(badge: Control, cell: Vector2i, elevation: float, camera: Camera3D, viewport_size: Vector2, anchor_x: float = -1.0, center_offset: Vector3 = Vector3.ZERO) -> void:
	var point := Vector3(cell.x + 0.5, 0.175, cell.y + 0.5) + center_offset + camera.global_basis.y * elevation
	var screen := camera.unproject_position(point) * size / viewport_size
	badge.position = screen - Vector2(badge.size.x * 0.5 if anchor_x < 0 else anchor_x, badge.size.y + 8)
	_update_badge_visibility(badge)
	if camera.is_position_behind(point):
		badge.hide()

func _update_badge_visibility(badge: Control) -> void:
	badge.visible = Rect2(Vector2.ZERO, size).encloses(badge.get_rect())
	for panel in [top, core_panel, status_panel, bottom, navigation, actions, cameras, pause_button, menu_button, raid_button]:
		if panel.visible and badge.get_rect().intersects(panel.get_rect()):
			badge.hide()
	if modal.visible:
		badge.hide()

func memory_diagnostics(delta: float, enabled: bool) -> Dictionary:
	if not enabled:
		return {}
	_memory_log_wait -= delta
	if _memory_log_wait > 0.0:
		return {}
	_memory_log_wait = 2.0
	var system_memory := OS.get_memory_info()
	# Engine counters omit some driver allocations; sample system availability too.
	return {
		"build": "memory-ab-2",
		"uptime_ms": Time.get_ticks_msec(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"rss_bytes": preload("res://scripts/mobile/mobile_diagnostics.gd").rss_bytes(FileAccess.get_file_as_string("/proc/self/status")) if OS.has_feature("android") else -1,
		"fps": Engine.get_frames_per_second(),
		"static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"video_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"texture_bytes": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"system_available_bytes": system_memory.get("available", -1),
		"system_free_bytes": system_memory.get("free", -1),
	}

func route(event: InputEvent) -> void:
	var position := Vector2(-1, -1)
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouse:
		position = event.position
	var over := modal.visible or vault_transfer.visible
	for badge in vault_badges.values():
		if badge.is_visible_in_tree() and badge.get_global_rect().has_point(position):
			over = true
	for badge in trap_badges.values() + door_badges.values():
		if badge.is_visible_in_tree() and badge.repair_button.visible and badge.repair_button.get_global_rect().has_point(position):
			over = true
	for control in [top, core_panel, status_panel, navigation, bottom, cameras, menu_button, pause_button, raid_button]:
		if control.visible and control.get_global_rect().has_point(position):
			over = true
	if tray_toggle.visible and tray_toggle.get_global_rect().has_point(position):
		over = true
	if actions.visible and actions.get_global_rect().has_point(position):
		over = true
	router.painting_enabled = _dig_enabled()
	router.handle_event(event, over)
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		_dig_pointer = position
		_dig_pointer_over_ui = over
		if event is InputEventScreenTouch and not event.pressed:
			_dig_pointer_over_ui = true
		_update_dig_hover()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		router.cancel()
		_dig_pointer_over_ui = true
		_update_dig_hover()
		paused = true
		if is_instance_valid(modal) and not result_open:
			_pause_menu()

func _choose_tool(id: int) -> void:
	if g.raid_active or result_open:
		return
	tool = id
	_update_preview()
	_refresh()

func _category(index: int) -> void:
	if g.raid_active or modal.visible:
		return
	tray_collapsed = category == index and not tray_collapsed
	category = index
	tool = Tool.NONE
	if g.persistence_enabled:
		_save_tray_preference()
	_cancel()
	_layout()
	_refresh()

func _tap(position: Vector2) -> void:
	if paused or result_open or g.raid_active or g.game_over:
		return
	var cell: Vector2i = _dig_cell_at(position) if _dig_enabled() else g._screen_to_grid(position)
	if not g._inside(cell):
		_cancel()
		return
	if g.grid[cell.y][cell.x] == GameTypes.Tile.VAULT:
		vault_transfer.open(cell)
		return
	if _dig_enabled() and g.grid[cell.y][cell.x] == GameTypes.Tile.ROCK:
		_dig_stroke(position, position)
		return
	if g._has_core() and tool in [Tool.NONE, Tool.DIG]:
		if g.corpses.any(func(corpse): return corpse.pos == cell):
			tool = Tool.ABSORB
		elif not g.loot_bags.any(func(bag): return bag.pos == cell):
			_cancel()
			return
	selected = cell
	if not g._has_core():
		selected = Vector2i(cell.x / 2 * 2, cell.y / 2 * 2)
	_update_preview()
	_refresh()

func _update_dig_hover() -> void:
	dig_hover = Vector2i(-1, -1)
	dig_hover_valid = false
	diggable_cells.clear()
	if _dig_enabled():
		for y in g.ROWS:
			for x in g.COLS:
				var cell := Vector2i(x, y)
				if g.sim.dig_failure_reason(cell).is_empty():
					diggable_cells.append(cell)
	if _dig_enabled() and not _dig_pointer_over_ui and Rect2(Vector2.ZERO, size).has_point(_dig_pointer):
		var cell: Vector2i = _dig_cell_at(_dig_pointer)
		if cell in diggable_cells:
			dig_hover = cell
			dig_hover_valid = true
	dig_hint.hide()
	if dig_hover.x >= 0:
		var points := _dig_tile_corners(dig_hover)
		var top_point := points[0]
		for point in points:
			if point.y < top_point.y:
				top_point = point
		dig_hint.position = Vector2(clampf(top_point.x + 12, 8, size.x - dig_hint.size.x - 8), clampf(top_point.y - dig_hint.size.y - 8, 8, size.y - dig_hint.size.y - 8))
		dig_hint.modulate = Color.WHITE if dig_hover_valid else RED
		_update_badge_visibility(dig_hint)
	queue_redraw()

func _dig_enabled() -> bool:
	return tool in [Tool.NONE, Tool.DIG] and g._has_core() and not paused and not result_open and not g.raid_active and not g.game_over and not modal.visible and not vault_transfer.visible

func _dig_stroke(from: Vector2, to: Vector2) -> void:
	if not _dig_enabled():
		return
	var changed := false
	var steps := maxi(1, ceili(from.distance_to(to) / 6.0))
	for index in range(steps + 1):
		if g.gold < GameTypes.COST_DIG:
			break
		var cell: Vector2i = _dig_cell_at(from.lerp(to, float(index) / steps))
		if g._inside(cell) and g.grid[cell.y][cell.x] == GameTypes.Tile.ROCK:
			if commands.commit(g.sim, profile, Tool.DIG, cell):
				changed = true
	_cancel()
	if changed:
		_save()
		g._sync_world()
	_refresh()

func _collect() -> void:
	if g.raid_active or g.game_over or result_open:
		return
	for bag in g.loot_bags:
		if bag.pos == selected:
			var stored: int = g._deposit_gold(int(bag.gold))
			bag.gold -= stored
			if bag.gold <= 0:
				g.loot_bags.erase(bag)
			_save()
			_update_preview()
			_refresh()
			return

func _update_preview() -> void:
	g.mobile_selection = selected
	preview = commands.preview(g.sim, profile, tool, selected) if selected.x >= 0 else {}

func _confirm() -> void:
	if commands.commit(g.sim, profile, tool, selected):
		_save()
		_cancel()
		g._sync_world()
	else:
		_update_preview()
	_refresh()

func _cancel() -> void:
	if tool == Tool.ABSORB:
		tool = Tool.NONE
	selected = Vector2i(-1, -1)
	g.mobile_selection = selected
	preview = {}
	if is_instance_valid(actions):
		actions.hide()

func _pan(delta: Vector2) -> void:
	following = false
	camera_rules.pan = g.cam_pan
	camera_rules.pan_by(Vector2(-delta.x, -delta.y / sin(deg_to_rad(40.0))))
	g.cam_pan = camera_rules.pan
	_constrain_camera()

func _zoom(position: Vector2, factor: float) -> void:
	camera_rules.zoom = g.cam_zoom
	camera_rules.zoom_by(factor)
	g._zoom_at(position, camera_rules.zoom / g.cam_zoom)
	_constrain_camera()

func _rotate(steps: int) -> void:
	camera_rules.yaw = g.cam_yaw
	camera_rules.rotate_steps(steps)
	g._orbit_yaw(camera_rules.yaw - g.cam_yaw)
	_constrain_camera()

func _constrain_camera() -> void:
	var limited: Dictionary = g.dungeon.limit_mobile_camera(g.cam_zoom, g.cam_pan, g._play_view(), g.COLS, g.ROWS, g.cam_yaw)
	g.cam_zoom = limited.zoom
	g.cam_pan = limited.pan

func _center(cell: Vector2i) -> void:
	var point: Vector2 = g._cell_pos(cell)
	var target := Vector2(size.x * 0.48, size.y * 0.43)
	g.cam_pan += Vector2(point.x - target.x, (point.y - target.y) / sin(deg_to_rad(40.0)))
	_constrain_camera()

func _center_core() -> void:
	following = false
	_center(g._core_origin() if g._has_core() else Vector2i(7, 7))

func _toggle_follow() -> void:
	following = not following
	if following and not g.hero.is_empty():
		_center(g.hero.pos)

func _start_raid() -> void:
	if g.raid_active or paused or result_open or not g._ready_for_raid():
		return
	_cancel()
	_save()
	_pre_raid_view = {"zoom": g.cam_zoom, "pan": g.cam_pan}
	g._start_raid()

func _raid_finished(result: Dictionary) -> void:
	var reward: Dictionary = profile.claim(result)
	if reward.is_empty():
		return
	_save()
	result_open = true
	following = false
	modal_title.text = "Cœur détruit" if g.game_over else "Raid terminé"
	modal_body.text = "Héros vaincus : %d    Fuites : %d\nOr emporté : %d\nOr disponible : %d    Or au sol : %d\nIntégrité : %d / 100\n\n+%d XP    Cœur niveau %d" % [int(result.get("killed", 0)), int(result.get("escaped", 0)), int(result.get("carried_out", 0)), g.gold, g.sim._unsecured_loot_total(), g.core_hp, reward.xp, profile.level()]
	if reward.level > reward.before_level:
		modal_body.text += "\nDébloqué : " + {2: "Entrave", 3: "Néant", 4: "Sceau magique"}.get(int(reward.level), "")
	_modal_action = "new" if g.game_over else "continue"
	modal_continue.text = "Nouveau donjon" if g.game_over else "Préparation"
	modal.show()

func _pause_menu() -> void:
	if result_open:
		return
	if is_instance_valid(vault_transfer):
		vault_transfer.close()
	modal_cancel.hide()
	paused = true
	modal_title.text = "Pause"
	modal_body.text = "Cœur niveau %d\n%d XP\n\n%s" % [profile.level(), profile.xp, "Sauvegarde indisponible" if _save_failed else "Progression locale conservée"]
	if _diagnostics != null:
		modal_body.text += "\nRendu : " + RenderingServer.get_current_rendering_method()
		if not _diagnostics_saved:
			modal_body.text += "\nJournal local indisponible"
		g._world_port.render_target_update_mode = SubViewport.UPDATE_DISABLED
		g.dungeon.set_process(false)
	_modal_action = "continue"
	modal_continue.text = "Reprendre"
	modal.show()

func _request_restart() -> void:
	if modal.visible:
		return
	router.cancel()
	_pause_menu()
	modal_title.text = "Recommencer le donjon ?"
	modal_body.text = "Le donjon actuel sera effacé.\nVous replacerez votre cœur, votre entrée et vos coffres.\n\nVotre XP et vos niveaux débloqués seront conservés."
	_modal_action = "new"
	modal_continue.text = "Recommencer"
	modal_cancel.show()
	modal_cancel.grab_focus()

func _cancel_restart() -> void:
	_modal_action = "continue"
	_continue()

func _continue() -> void:
	g._world_port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	g.dungeon.set_process(true)
	if result_open and not _pre_raid_view.is_empty():
		g.cam_zoom = _pre_raid_view.zoom
		g.cam_pan = _pre_raid_view.pan
		_pre_raid_view.clear()
	if _modal_action == "new":
		g._new_map()
		_pre_raid_view.clear()
		g.raid_index = profile.last_raid_id
		following = false
		_cancel()
		category = 0
		tool = Tool.NONE
		g.cam_zoom = 2.0
		g.cam_yaw = 45.0
		g.cam_pan = Vector2.ZERO
		g._cam_custom = true
		g._sync_world()
		_center_core()
		selected = Vector2i(6, 6)
		_update_preview()
		g._sync_world()
		_save()
	_modal_action = "continue"
	paused = false
	result_open = false
	modal.hide()
	modal_cancel.hide()
	_refresh()

func _copy_diagnostic(previous: bool) -> void:
	var text: String = _diagnostics.export_previous() if previous else _diagnostics.export_current()
	DisplayServer.clipboard_set(text)
	var button := _copy_previous_button if previous else _copy_current_button
	button.text = "Diagnostic copie"

func _show_defeat_recovery() -> void:
	result_open = true
	modal_title.text = "Cœur détruit"
	modal_body.text = "Progression conservée\n\nCœur niveau %d\n%d XP" % [profile.level(), profile.xp]
	_modal_action = "new"
	modal_continue.text = "Nouveau donjon"
	modal.show()

func _save() -> void:
	if g.persistence_enabled and save_api != null and not g.raid_active:
		_save_failed = not save_api.write_save(SAVE_PATH, save_api.capture(g.sim, g.raid, profile))

func _refresh() -> void:
	var anchoring: bool = not g._has_core()
	if _anchor_layout != anchoring:
		_layout()
	bottom.visible = not anchoring and not g.raid_active and not tray_collapsed
	core_panel.visible = not anchoring
	tray_toggle.visible = not anchoring and not g.raid_active and not modal.visible and not tray_collapsed
	navigation.visible = not anchoring and not g.raid_active and tray_collapsed
	integrity.visible = not anchoring
	raid_button.visible = not anchoring
	follow_button.visible = not anchoring
	walls_button.visible = true
	confirm.text = "Ancrer" if anchoring else "Confirmer"
	wealth.text = "OR\n%d" % g.gold if anchoring else "OR\n%d / %d" % [g.gold, g._storage_capacity()]
	integrity.text = "Cœur  %d%%" % g.core_hp
	level_label.text = "Niv. %d   %d / %d XP" % [profile.level(), profile.xp, profile.next_threshold()]
	if profile.level() == 4:
		level_label.text = "Niv. 4   MAX   %d XP" % profile.xp
	raid_emblem.visible = g.raid_active
	phase.add_theme_font_size_override("font_size", 24 if g.raid_active else 18)
	phase.add_theme_color_override("font_color", Color("f6ac40") if g.raid_active else GOLD)
	if g.raid_active and not g.hero.is_empty():
		phase.text = "RAID %s" % _clock_text(g.raid.elapsed_seconds)
		follow_button.icon = portraits.get(str(g.hero.get("kind", "thief")))
	elif not g._has_core():
		phase.text = "ANCRAGE DU CŒUR"
	elif not g._has_entrance():
		phase.text = "PRÉPARATION\nEntrée absente"
	elif not g._has_required_storage():
		phase.text = "PRÉPARATION\nRéserve insuffisante"
	else:
		phase.text = "Prochain raid dans\n%s" % _clock_text(ceili(g.raid_timer))
	if _save_failed:
		phase.text = "Sauvegarde\nindisponible"
		raid_emblem.hide()
	_align_header_height()
	raid_button.disabled = not g._ready_for_raid() or g.raid_active or g.game_over
	follow_button.disabled = not g.raid_active
	follow_button.add_theme_stylebox_override("normal", _selected_tool_style if following else _normal_tool_style)
	for id in buttons:
		var item: Dictionary = buttons[id]
		item.button.visible = id in CATEGORIES[category]
		item.button.disabled = g.raid_active or not profile.allows(id) or g.game_over
		item.button.add_theme_stylebox_override("normal", _selected_tool_style if tool == id else _normal_tool_style)
		if not profile.allows(id):
			item.label.text = "%s Niv.%d" % [item.entry[1], profile.required_level(id)]
		else:
			item.label.text = "%s %s" % [item.entry[1], str(item.entry[2]) if item.entry[2] else ""]
	for index in category_buttons.size():
		category_buttons[index].add_theme_stylebox_override("normal", _selected_tool_style if category == index and not tray_collapsed else _normal_tool_style)
	var context_action: bool = tool == Tool.ABSORB or g.loot_bags.any(func(bag): return bag.pos == selected)
	actions.visible = selected.x >= 0 and not g.raid_active and not modal.visible and (anchoring or not tray_collapsed or context_action)
	if actions.visible:
		collect.visible = g.loot_bags.any(func(bag): return bag.pos == selected)
		collect.disabled = g.gold >= g._storage_capacity()
		confirm.disabled = not preview.get("valid", false)
		var title := "Cœur" if anchoring else (str(buttons[tool].entry[1]) if buttons.has(tool) else "Case")
		if tool == Tool.ABSORB:
			title = "Absorber"
		detail.text = "%s   (%d, %d)   %d or" % [title, selected.x + 1, selected.y + 1, int(preview.get("cost", 0))]
		if anchoring:
			detail.text = "Ancrage du cœur"
		if not preview.get("valid", false):
			detail.text += "   " + str(preview.get("reason", "Indisponible"))

func _dig_tile_corners(cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	var height: float = g.dungeon.ROCK_H
	if not g.dungeon.mobile_walls_visible:
		height = maxf(g.dungeon.FLOOR_H, height * g.dungeon.MOBILE_CUTAWAY_SCALE)
	height += 0.025
	for offset in [Vector2(0.08, 0.08), Vector2(0.92, 0.08), Vector2(0.92, 0.92), Vector2(0.08, 0.92)]:
		var point := Vector3(cell.x + offset.x, height, cell.y + offset.y)
		points.append(g._to_world_screen(g.dungeon._world_to_screen(point, g._play_view(), g.cam_zoom)))
	return points

func _dig_cell_at(position: Vector2) -> Vector2i:
	var physical: Vector2i = g._screen_to_grid(position)
	# Chest interaction keeps priority; rock relief must not displace the marked target.
	if g._inside(physical) and g.grid[physical.y][physical.x] == GameTypes.Tile.VAULT:
		return physical
	for y in g.ROWS:
		for x in g.COLS:
			var cell := Vector2i(x, y)
			if g.sim.dig_failure_reason(cell).is_empty() and Geometry2D.is_point_in_polygon(position, _dig_tile_corners(cell)):
				return cell
	return physical

func _dig_corner_lines(points: PackedVector2Array) -> PackedVector2Array:
	var lines := PackedVector2Array()
	for index in 4:
		for neighbour in [(index + 3) % 4, (index + 1) % 4]:
			lines.append(points[index])
			lines.append(points[index].lerp(points[neighbour], 0.18))
	return lines

func _draw() -> void:
	if g == null or g.dungeon == null:
		return
	if _dig_enabled():
		for cell in diggable_cells:
			if cell == dig_hover:
				continue
			draw_multiline(_dig_corner_lines(_dig_tile_corners(cell)), Color(GOLD, 0.65), 1.5, true)
	if dig_hover.x >= 0 and _dig_enabled():
		var color := GOLD if dig_hover_valid else RED
		var points := _dig_tile_corners(dig_hover)
		draw_colored_polygon(points, Color(color, 0.06))
		draw_multiline(_dig_corner_lines(points), color, 2.5, true)
	if selected.x >= 0 and not g.raid_active:
		if not g._has_core():
			var corners := PackedVector2Array()
			var lo := Vector2i(maxi(0, selected.x - 1), maxi(0, selected.y - 1))
			var hi := Vector2i(mini(g.COLS, selected.x + 3), mini(g.ROWS, selected.y + 3))
			for point in [lo, Vector2i(hi.x, lo.y), hi, Vector2i(lo.x, hi.y), lo]:
				var p := Vector3(point.x, 0.175, point.y)
				corners.append(g._to_world_screen(g.dungeon._world_to_screen(p, g._play_view(), g.cam_zoom)))
			draw_polyline(corners, GOLD if preview.get("valid", false) else RED, 2, true)
			return
		var point: Vector2 = g._cell_pos(selected)
		var color := GREEN if preview.get("valid", false) else RED
		var diamond := _placement_corners(selected)
		draw_colored_polygon(diamond, Color(color, 0.04))
		diamond.append(diamond[0])
		draw_polyline(diamond, color, 1.5, true)
		if icons.has(tool) and g._has_core() and tool not in [Tool.TRAP_SPIKE, Tool.TRAP_SNARE, Tool.TRAP_VOID]:
			var icon_size: Vector2 = icons[tool].get_size()
			icon_size *= 60.0 / maxf(icon_size.x, icon_size.y)
			draw_texture_rect(icons[tool], Rect2(point + Vector2(0, -42) - icon_size * 0.5, icon_size), false, Color(color, 0.8))
	for popup in damage_popups:
		draw_string(ThemeDB.fallback_font, popup.point + Vector2(-20, -65 - (1.0 - popup.time) * 35), popup.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(RED, popup.time))

func _placement_corners(cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.ONE, Vector2i.DOWN]:
		var world := Vector3(cell.x + offset.x, 0.185, cell.y + offset.y)
		points.append(g._to_world_screen(g.dungeon._world_to_screen(world, g._play_view(), g.cam_zoom)))
	return points
