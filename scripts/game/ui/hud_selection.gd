extends PanelContainer

signal dismissed
signal layout_changed
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Catalog = preload("res://scripts/game/ui/hud_catalog.gd")
const Types = preload("res://scripts/game/game_types.gd")
const Notices = preload("res://scripts/game/ui/hud_notices.gd")
var session: IsometricGameSession
var title: Label
var detail: Label
var glyph: TextureRect
var confirm: Button
var collect: Button
var absorb: Button
var transfer: Button
var repair: Button
var transfers: VBoxContainer
var target_label: Label
var amount_label: Label
var previous: Button
var next: Button
var less: Button
var more: Button
var less_one: Button
var more_one: Button
var maximum: Button
var send: Button
var actions: HFlowContainer
var steps: GridContainer
var content: VBoxContainer
var _transfer_open := false
var _source := Vector2i(-1, -1)
var _destination := Vector2i(-1, -1)
var _destinations: Array[Vector2i] = []
var _amount := 0
var _limit := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.minimum_size_changed.connect(func(): layout_changed.emit())
	scroll.add_child(content)
	var header := VBoxContainer.new()
	content.add_child(header)
	# Icon, name and close share one line, centred on the text block.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	header.add_child(top)
	glyph = UI.picture(top, "gem", 32)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	words.add_theme_constant_override("separation", 0)
	top.add_child(words)
	title = UI.label(words, "", 18)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail = UI.label(words, "", 14, UI.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := UI.button(top, "", _close, "cross")
	close.tooltip_text = "Annuler / fermer"
	close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	confirm = UI.button(header, "CONFIRMER", func(): session.confirm_action(), "", true)
	transfer = UI.button(header, "Transférer l’or", _open_transfer, "arrow")
	repair = UI.button(header,"Réparer",func():
		var cell:=session.selected
		session.choose_tool(Types.Tool.REPAIR)
		session.select_cell(cell),"hammer")
	actions = HFlowContainer.new()
	content.add_child(actions)
	collect = UI.button(actions, "Ramasser le butin", func(): session.collect_selected(), "coin", true)
	absorb = UI.button(actions, "Absorber · +2 PV", func(): session.absorb_selected(), "gem")
	for button in [collect,absorb]:
		button.add_theme_font_size_override("font_size",13)
		button.add_theme_constant_override("icon_max_width",22)
	transfers = VBoxContainer.new()
	content.add_child(transfers)
	var target_row := HBoxContainer.new()
	transfers.add_child(target_row)
	previous = UI.button(target_row, "‹", func(): _cycle(-1))
	target_label = UI.label(target_row, "", 15)
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next = UI.button(target_row, "›", func(): _cycle(1))
	var amount_row := HBoxContainer.new()
	transfers.add_child(amount_row)
	amount_label = UI.label(amount_row, "", 18, UI.GOLD)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	maximum = UI.button(amount_row, "Tout", func(): _set_amount(_limit))
	maximum.custom_minimum_size.x = 72
	# Equal steps in a grid: no single button wraps alone onto a new line.
	steps = GridContainer.new()
	steps.columns = 4
	steps.add_theme_constant_override("h_separation", 4)
	steps.add_theme_constant_override("v_separation", 4)
	transfers.add_child(steps)
	less = UI.button(steps, "−25", func(): _set_amount(_amount - 25))
	less_one = UI.button(steps, "−1", func(): _set_amount(_amount - 1))
	more_one = UI.button(steps, "+1", func(): _set_amount(_amount + 1))
	more = UI.button(steps, "+25", func(): _set_amount(_amount + 25))
	for step in [less, less_one, more_one, more]: step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	send = UI.button(transfers, "TRANSFÉRER", _send, "", true)
	transfers.hide()

func refresh() -> void:
	var p := session.selected
	var placing := session.tool != Types.Tool.NONE or not session.sim._has_core()
	if p != _source:
		_source = p
		_transfer_open = false
		_destination = Vector2i(-1, -1)
	var tile: int = session.sim.grid[p.y][p.x] if p.x >= 0 else Types.Tile.ROCK
	if placing:
		var item := Catalog.definition(session.tool)
		title.text = item[1]
		glyph.texture = UI.icon(item[3])
		detail.text = "Touchez pour poser · %s" % item[2]
		if not session.preview.is_empty():
			detail.text = "%d or · %s" % [session.preview.get("cost", 0), "Prêt à confirmer" if session.preview.get("valid", false) else Notices.french(str(session.preview.get("reason", "Pose impossible")))]
	else:
		var names := ["Roche", "Sol", "Entrée", "Cœur", "Coffre", "Pointes", "Entrave", "Porte", "Néant", "Porte magique"]
		title.text = names[tile]
		glyph.texture = UI.icon("chest" if tile == Types.Tile.VAULT else "gem" if tile == Types.Tile.CORE else "door" if session.sim._is_door_tile(tile) else "pick")
		detail.text = "Case %d, %d" % [p.x + 1, p.y + 1]
		if tile == Types.Tile.VAULT: detail.text = "%d / %d or" % [session.sim.vault_gold.get(p, 0), Types.VAULT_CAPACITY]
		elif session.sim._is_door_tile(tile):
			var hp:=int(session.sim.door_hp.get(p,Types.DOOR_MAX_HP))
			detail.text="%d / %d PV" % [hp,Types.DOOR_MAX_HP] if hp>0 else "Déverrouillée" if session.sim.door_opened.get(p,false) else "Brisée · À réparer"
		elif Types.is_trap_tile(tile): detail.text = "%d / %d charges" % [session.sim.trap_charges.get(p, 0), Types.trap_max_charges(tile)]
	confirm.visible = placing
	var repair_action:=session.check_action(p,Types.Tool.REPAIR)
	repair.visible=not placing and (Types.is_trap_tile(tile) or session.sim._is_door_tile(tile) or tile==Types.Tile.VAULT)
	repair.disabled=not repair_action.get("valid",false)
	repair.text="Réparer · %d or" % repair_action.get("cost",0)
	repair.tooltip_text=Notices.french(str(repair_action.get("reason","")))
	confirm.disabled = not session.can_edit() or not session.preview.get("valid", false)
	collect.visible = p.x >= 0 and session.sim.loot_bags.any(func(b): return b.pos == p and b.gold > 0)
	absorb.visible = p.x >= 0 and session.sim.corpses.any(func(c): return c.pos == p)
	collect.disabled = not session.can_edit()
	absorb.disabled = not session.can_edit()
	actions.visible = collect.visible or absorb.visible
	var vault := not placing and p.x >= 0 and tile == Types.Tile.VAULT
	if not vault: _transfer_open = false
	transfer.visible = vault and not _transfer_open
	transfers.visible = vault and _transfer_open
	if transfers.visible: _refresh_transfer()
	layout_changed.emit()

func _open_transfer() -> void:
	_transfer_open = true
	_amount = Types.VAULT_CAPACITY
	refresh()

func _close() -> void:
	if _transfer_open:
		_transfer_open = false
		refresh()
	else: dismissed.emit()

func _refresh_transfer() -> void:
	_destinations.clear()
	for cell in session.sim._vault_positions():
		if cell != session.selected: _destinations.append(cell)
	if not _destinations.has(_destination):
		_destination = _destinations[0] if not _destinations.is_empty() else Vector2i(-1, -1)
	_limit = 0
	if _destination.x >= 0:
		var source_gold := int(session.sim.vault_gold.get(session.selected, 0))
		var target_gold := int(session.sim.vault_gold.get(_destination, 0))
		_limit = maxi(0, mini(source_gold, Types.VAULT_CAPACITY - target_gold))
		target_label.text = "Vers coffre %d · %d / %d or\nCase %d, %d" % [_destinations.find(_destination) + 1, target_gold, Types.VAULT_CAPACITY, _destination.x + 1, _destination.y + 1]
	else: target_label.text = "Construisez un autre coffre pour transférer."
	_amount = clampi(_amount, 0, _limit)
	amount_label.text = "%d or" % _amount
	previous.disabled = _destinations.size() < 2
	next.disabled = previous.disabled
	less.disabled = _amount <= 0
	less_one.disabled = less.disabled
	more.disabled = _amount >= _limit
	more_one.disabled = more.disabled
	maximum.disabled = _amount >= _limit
	send.disabled = _amount <= 0 or not session.can_edit()

func _cycle(direction: int) -> void:
	if _destinations.is_empty(): return
	_destination = _destinations[posmod(_destinations.find(_destination) + direction, _destinations.size())]
	_amount = Types.VAULT_CAPACITY
	_refresh_transfer()

func _set_amount(value: int) -> void:
	_amount = clampi(value, 0, _limit)
	_refresh_transfer()

func _send() -> void:
	if _destination.x >= 0 and _amount > 0:
		session.transfer_selected(_destination, _amount)

func fit_width(width: float, maximum_height: float) -> void:
	size.x = width
	# Keep all actions reachable even when loot and a body share a vault cell.
	content.custom_minimum_size.x = maxf(0, width - 36)
	steps.columns = 4 if width - 36 >= 4 * 48 + 12 else 2
	size.y = minf(maximum_height, content.get_combined_minimum_size().y + 24)
