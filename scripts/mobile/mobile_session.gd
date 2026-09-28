extends Control

const Profile = preload("res://scripts/game/core_progression.gd")
const Router = preload("res://scripts/mobile/mobile_input_router.gd")
const Commands = preload("res://scripts/mobile/mobile_build.gd")
const SAVE_PATH := "user://mobile_run_v1.save"
const Tool := GameTypes.Tool
const GREEN := Color("65d9ad")
const GOLD := Color("f1cb72")
const RED := Color("f17b82")
const TOOLS := [
	[Tool.DIG, "Creuser", 5],
	[Tool.STORE, "Réserve", 60],
	[Tool.TRAP_SPIKE, "Pointes", 35],
	[Tool.TRAP_SNARE, "Entrave", 30],
	[Tool.TRAP_VOID, "Néant", 45],
	[Tool.BUILD_DOOR, "Porte", 40],
	[Tool.BUILD_MAGIC_DOOR, "Sceau", 80],
	[Tool.BUILD_ENTRANCE, "Entrée", 0],
	[Tool.REPAIR, "Réparer", 0],
	[Tool.ABSORB, "Absorber", 0]]

var g
var profile = Profile.new()
var router = Router.new()
var commands = Commands.new()
var camera_rules = preload("res://scripts/mobile/mobile_camera_controller.gd").new()
var save_api
var tool := Tool.DIG
var selected := Vector2i(-1, -1)
var preview := {}
var following := false
var result_open := false
var paused := false
var top: PanelContainer
var bottom: PanelContainer
var actions: PanelContainer
var cameras: VBoxContainer
var wealth: Label
var integrity: Label
var level_label: Label
var phase: Label
var detail: Label
var confirm: Button
var collect: Button
var raid_button: Button
var follow_button: Button
var modal: ColorRect
var modal_title: Label
var modal_body: Label
var modal_continue: Button
var buttons := {}
var icons := {}
var _last_size := Vector2.ZERO
var _refresh_time := 0.0
var _modal_action := "continue"
var _save_failed := false
var display_font: Font
var portraits := {}
var hero_card: PanelContainer
var hero_picture: TextureRect
var hero_name: Label
var hero_health: ProgressBar
var category := 0
var category_buttons: Array[Button] = []
var damage_popups: Array = []
var _previous_hero_hp := -1
var _previous_core_hp := 100
var _normal_tool_style: StyleBoxFlat
var _selected_tool_style: StyleBoxFlat
var _pre_raid_view := {}
var build_options: HBoxContainer
var _raid_layout := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/mobile/cinzel.ttf"):
		display_font = load("res://assets/mobile/cinzel.ttf")
	var atlas: Texture2D = load("res://assets/mobile/command-atlas-v1.png")
	for index in 12:
		var icon := AtlasTexture.new()
		icon.atlas = atlas
		icon.region = Rect2(Vector2(index % 4, index / 4) * Vector2(atlas.get_width() / 4.0, atlas.get_height() / 3.0), Vector2(atlas.get_width() / 4.0, atlas.get_height() / 3.0))
		icons[index] = icon
	var portrait_atlas: Texture2D = load("res://assets/mobile/hero-portraits-v1.png")
	var kinds := ["thief", "paladin", "ranger", "mage"]
	for index in 4:
		var portrait := AtlasTexture.new()
		portrait.atlas = portrait_atlas
		portrait.region = Rect2(Vector2(index % 2, index / 2) * Vector2(portrait_atlas.get_size() / 2), portrait_atlas.get_size() / 2)
		portraits[kinds[index]] = portrait
	_build_ui()
	router.tapped.connect(_tap)
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
	if not restored and g.starter_enabled and ResourceLoader.exists("res://scripts/mobile/mobile_starter.gd"):
		load("res://scripts/mobile/mobile_starter.gd").populate(g.sim, g.raid)
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

func _style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
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
	if display_font != null and size_px >= 22:
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
	panel.add_theme_stylebox_override("panel", _style(Color("101619ed"), Color("806338")))
	add_child(panel)
	return panel

func _build_ui() -> void:
	_normal_tool_style = _style(Color("101619"), Color("947440"))
	_selected_tool_style = _style(Color("252326"), GOLD)
	top = _band()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	top.add_child(header)
	var coin := TextureRect.new()
	coin.texture = icons[10]
	coin.custom_minimum_size = Vector2(48, 48)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(coin)
	wealth = _label("")
	header.add_child(wealth)
	integrity = _label("", 20, GREEN)
	header.add_child(integrity)
	level_label = _label("", 18)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(level_label)
	header.add_child(_button("II", _pause_menu, "Pause"))
	bottom = _band()
	var tray := VBoxContainer.new()
	bottom.add_child(tray)
	phase = _label("", 20, GOLD)
	tray.add_child(phase)
	var options := HBoxContainer.new()
	build_options = options
	options.add_theme_constant_override("separation", 16)
	tray.add_child(options)
	var categories := VBoxContainer.new()
	categories.add_theme_constant_override("separation", 4)
	options.add_child(categories)
	for index in 3:
		var button := _button(["Bâtir", "Pièges", "Cœur"][index], func(): _category(index))
		button.custom_minimum_size = Vector2(132, 48)
		categories.add_child(button)
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
		button.custom_minimum_size = Vector2(150, 152)
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_top = 4
		box.offset_bottom = -4
		button.add_child(box)
		var image := TextureRect.new()
		image.texture = icons[id]
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(100, 108)
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
	cameras.add_theme_constant_override("separation", 8)
	add_child(cameras)
	cameras.add_child(_button("+", func(): _zoom(size * 0.5, 1.2), "Zoom avant"))
	cameras.add_child(_button("-", func(): _zoom(size * 0.5, 1.0 / 1.2), "Zoom arriere"))
	cameras.add_child(_button("↶", func(): _rotate(-1), "Rotation gauche"))
	cameras.add_child(_button("↷", func(): _rotate(1), "Rotation droite"))
	var core_button := _button("", _center_core, "Recentrer sur le Cœur")
	core_button.icon = icons[11]
	core_button.expand_icon = true
	core_button.add_theme_constant_override("icon_max_width", 40)
	cameras.add_child(core_button)
	follow_button = _button("", _toggle_follow, "Suivre le héros")
	follow_button.icon = portraits.thief
	follow_button.expand_icon = true
	follow_button.add_theme_constant_override("icon_max_width", 44)
	cameras.add_child(follow_button)
	raid_button = _button("Raid", _start_raid)
	cameras.add_child(raid_button)
	hero_card = _band()
	var hero_row := HBoxContainer.new()
	hero_card.add_child(hero_row)
	hero_picture = TextureRect.new()
	hero_picture.custom_minimum_size = Vector2(76, 76)
	hero_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_row.add_child(hero_picture)
	var hero_info := VBoxContainer.new()
	hero_info.custom_minimum_size.x = 240
	hero_row.add_child(hero_info)
	hero_name = _label("", 20, GOLD)
	hero_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hero_info.add_child(hero_name)
	hero_health = ProgressBar.new()
	hero_health.custom_minimum_size = Vector2(240, 24)
	hero_health.show_percentage = false
	hero_health.add_theme_stylebox_override("fill", _style(GREEN))
	hero_health.add_theme_stylebox_override("background", _style(Color("080d0c")))
	hero_info.add_child(hero_health)
	hero_card.hide()
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
	top.size = Vector2(size.x - inset.x - inset.z, 72)
	var tray_height := 64 if g.raid_active else 206
	build_options.visible = not g.raid_active
	bottom.position = Vector2(inset.x, size.y - tray_height - inset.w)
	bottom.size = Vector2(minf(940, size.x - 136 - inset.x - inset.z), tray_height)
	actions.position = Vector2(inset.x, bottom.position.y - 80)
	actions.size = Vector2(minf(850, size.x - 160), 72)
	cameras.position = Vector2(size.x - inset.z - 96, top.position.y + 86)
	cameras.size.x = 96
	hero_card.position = Vector2(inset.x, top.position.y + 82)
	hero_card.size = Vector2(360, 96)
	g._world_host.size = size
	_last_size = size
	_raid_layout = g.raid_active

func tick(delta: float) -> void:
	if size != _last_size or _raid_layout != g.raid_active:
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

func route(event: InputEvent) -> void:
	var position := Vector2(-1, -1)
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouse:
		position = event.position
	var over := modal.visible or top.get_global_rect().has_point(position) or bottom.get_global_rect().has_point(position) or cameras.get_global_rect().has_point(position)
	if actions.visible and actions.get_global_rect().has_point(position):
		over = true
	if hero_card.visible and hero_card.get_global_rect().has_point(position):
		over = true
	router.handle_event(event, over)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		router.cancel()
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
	category = index
	_cancel()
	_refresh()

func _tap(position: Vector2) -> void:
	if paused or result_open or g.raid_active or g.game_over:
		return
	var cell: Vector2i = g._screen_to_grid(position)
	if not g._inside(cell):
		_cancel()
		return
	selected = cell
	if not g._has_core():
		selected = Vector2i(cell.x / 2 * 2, cell.y / 2 * 2)
	_update_preview()
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
	selected = Vector2i(-1, -1)
	g.mobile_selection = selected
	preview = {}
	if is_instance_valid(actions):
		actions.hide()

func _pan(delta: Vector2) -> void:
	following = false
	camera_rules.pan = g.cam_pan
	camera_rules.pan_by(Vector2(-delta.x, -delta.y / sin(deg_to_rad(40.0))))
	g.cam_pan = camera_rules.pan.clamp(Vector2(-1800, -1800), Vector2(1800, 1800))

func _zoom(position: Vector2, factor: float) -> void:
	camera_rules.zoom = g.cam_zoom
	camera_rules.zoom_by(factor)
	g._zoom_at(position, camera_rules.zoom / g.cam_zoom)

func _rotate(steps: int) -> void:
	camera_rules.yaw = g.cam_yaw
	camera_rules.rotate_steps(steps)
	g._orbit_yaw(camera_rules.yaw - g.cam_yaw)

func _center(cell: Vector2i) -> void:
	var point: Vector2 = g._cell_pos(cell)
	var target := Vector2(size.x * 0.48, size.y * 0.43)
	g.cam_pan += Vector2(point.x - target.x, (point.y - target.y) / sin(deg_to_rad(40.0)))

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
	g.cam_zoom = maxf(g.cam_zoom, 2.25)
	g._start_raid()
	following = true

func _raid_finished(result: Dictionary) -> void:
	var reward: Dictionary = profile.claim(result)
	if reward.is_empty():
		return
	g.gold += int(reward.gold)
	if g._has_core():
		g.sim._spill_overflow_at(g._core_origin())
	_save()
	result_open = true
	following = false
	modal_title.text = "Cœur détruit" if g.game_over else "Raid terminé"
	modal_body.text = "Héros vaincus : %d    Fuites : %d\nOr emporté : %d    Butin restant : %d\nIntégrité : %d / 100\n\n+%d XP    +%d or    Cœur niveau %d" % [int(result.get("killed", 0)), int(result.get("escaped", 0)), int(result.get("carried_out", 0)), g.sim._unsecured_loot_total(), g.core_hp, reward.xp, reward.gold, profile.level()]
	if reward.level > reward.before_level:
		modal_body.text += "\nDébloqué : " + {2: "Entrave", 3: "Néant", 4: "Sceau magique"}.get(int(reward.level), "")
	_modal_action = "new" if g.game_over else "continue"
	modal_continue.text = "Nouveau donjon" if g.game_over else "Préparation"
	modal.show()

func _pause_menu() -> void:
	if result_open:
		return
	paused = true
	modal_title.text = "Pause"
	modal_body.text = "Cœur niveau %d\n%d XP\n\n%s" % [profile.level(), profile.xp, "Sauvegarde indisponible" if _save_failed else "Progression locale conservée"]
	_modal_action = "continue"
	modal_continue.text = "Reprendre"
	modal.show()

func _continue() -> void:
	if result_open and not _pre_raid_view.is_empty():
		g.cam_zoom = _pre_raid_view.zoom
		g.cam_pan = _pre_raid_view.pan
		_pre_raid_view.clear()
	if _modal_action == "new":
		g._new_map()
		g.raid_index = profile.last_raid_id
		_center_core()
		_save()
	paused = false
	result_open = false
	modal.hide()

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
	wealth.text = "Or  %d / %d" % [g.gold, g._storage_capacity()]
	integrity.text = "Cœur  %d%%" % g.core_hp
	level_label.text = "Niv. %d   %d / %d XP" % [profile.level(), profile.xp, profile.next_threshold()]
	if profile.level() == 4:
		level_label.text = "Niv. 4   MAX   %d XP" % profile.xp
	if g.raid_active and not g.hero.is_empty():
		phase.text = "RAID %d   %s   %d / %d PV" % [g.raid_index, str(g.hero.get("display", "Héros")), g.hero.hp, g.hero.max_hp]
		hero_card.show()
		hero_picture.texture = portraits.get(str(g.hero.get("kind", "thief")))
		follow_button.icon = hero_picture.texture
		hero_name.text = "%s   %d PV" % [str(g.hero.get("name", "Héros")), g.hero.hp]
		hero_health.max_value = g.hero.max_hp
		hero_health.value = g.hero.hp
	elif not g._has_core():
		phase.text = "ANCRAGE DU CŒUR"
	elif not g._has_entrance():
		phase.text = "PRÉPARATION   Entrée absente"
	elif not g._has_required_storage():
		phase.text = "PRÉPARATION   Capacité de réserve insuffisante"
	else:
		phase.text = "PRÉPARATION   Prochain raid : %ds" % ceili(g.raid_timer)
	if not g.raid_active:
		hero_card.hide()
	if _save_failed:
		phase.text += "   Sauvegarde indisponible"
	raid_button.disabled = not g._ready_for_raid() or g.raid_active or g.game_over
	follow_button.disabled = not g.raid_active
	follow_button.add_theme_stylebox_override("normal", _selected_tool_style if following else _normal_tool_style)
	for id in buttons:
		var item: Dictionary = buttons[id]
		item.button.visible = id in [[Tool.DIG, Tool.STORE, Tool.BUILD_DOOR, Tool.BUILD_ENTRANCE], [Tool.TRAP_SPIKE, Tool.TRAP_SNARE, Tool.TRAP_VOID, Tool.BUILD_MAGIC_DOOR], [Tool.REPAIR, Tool.ABSORB]][category]
		item.button.disabled = g.raid_active or not profile.allows(id) or g.game_over
		item.button.add_theme_stylebox_override("normal", _selected_tool_style if tool == id else _normal_tool_style)
		if not profile.allows(id):
			item.label.text = "%s Niv.%d" % [item.entry[1], profile.required_level(id)]
		else:
			item.label.text = "%s %s" % [item.entry[1], str(item.entry[2]) if item.entry[2] else ""]
	for index in category_buttons.size():
		category_buttons[index].modulate = GOLD if category == index else Color.WHITE
	actions.visible = selected.x >= 0 and not g.raid_active and not modal.visible
	if actions.visible:
		collect.visible = g.loot_bags.any(func(bag): return bag.pos == selected)
		collect.disabled = g.gold >= g._storage_capacity()
		confirm.disabled = not preview.get("valid", false)
		var title := "Cœur" if not g._has_core() else str(buttons[tool].entry[1])
		detail.text = "%s   (%d, %d)   %d or" % [title, selected.x + 1, selected.y + 1, int(preview.get("cost", 0))]
		if not preview.get("valid", false):
			detail.text += "   " + str(preview.get("reason", "Indisponible"))

func _draw() -> void:
	if g == null or g.dungeon == null:
		return
	if selected.x >= 0 and not g.raid_active:
		var point: Vector2 = g._cell_pos(selected)
		var color := GREEN if preview.get("valid", false) else RED
		var extent := 28.0 * float(g.cam_zoom)
		var diamond := PackedVector2Array([point + Vector2(0, -extent * 0.5), point + Vector2(extent, 0), point + Vector2(0, extent * 0.5), point + Vector2(-extent, 0)])
		draw_colored_polygon(diamond, Color(color, 0.22))
		diamond.append(diamond[0])
		draw_polyline(diamond, color, 3, true)
		if icons.has(tool) and g._has_core():
			draw_texture_rect(icons[tool], Rect2(point - Vector2(30, 72), Vector2(60, 60)), false, Color(color, 0.8))
	if g.raid_active and not g.hero.is_empty():
		var point: Vector2 = g.dungeon.hero_screen_anchor()
		point.x = clampf(point.x, 32, size.x - 120)
		point.y = clampf(point.y, 125, bottom.position.y - 32)
		draw_arc(point, 24, 0, TAU, 32, GOLD, 3, true)
		var hp := float(g.hero.hp) / maxf(1, float(g.hero.max_hp))
		draw_rect(Rect2(point + Vector2(-30, -44), Vector2(60, 8)), Color("171c20"))
		draw_rect(Rect2(point + Vector2(-30, -44), Vector2(60 * hp, 8)), GREEN)
	for popup in damage_popups:
		draw_string(ThemeDB.fallback_font, popup.point + Vector2(-20, -65 - (1.0 - popup.time) * 35), popup.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(RED, popup.time))
