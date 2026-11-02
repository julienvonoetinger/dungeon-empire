extends PanelContainer

signal dismissed
signal layout_changed
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Catalog = preload("res://scripts/game/ui/hud_catalog.gd")
const Types = preload("res://scripts/game/game_types.gd")
var session: IsometricGameSession
var title: Label
var detail: Label
var glyph: TextureRect
var confirm: Button
var collect: Button
var absorb: Button
var transfer: Button
var repair: Button
var remove: Button
var removal_pending := false
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
	visibility_changed.connect(func():
		if not visible: removal_pending = false)
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
	close.tooltip_text = "Cancel / close"
	close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	confirm = UI.button(header, "CONFIRM", _confirm, "", true)
	transfer = UI.button(header, "Transfer gold", _open_transfer, "arrow")
	repair = UI.button(header,"Repair",func():
		var cell:=session.selected
		session.choose_tool(Types.Tool.REPAIR)
		session.select_cell(cell),"hammer")
	remove = UI.button(header,"Remove",func():
		removal_pending = true
		_transfer_open = false
		refresh(),"cross")
	actions = HFlowContainer.new()
	content.add_child(actions)
	collect = UI.button(actions, "Collect loot", func(): session.collect_selected(), "coin", true)
	absorb = UI.button(actions, "Absorb · +2 HP", func(): session.absorb_selected(), "gem")
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
	maximum = UI.button(amount_row, "All", func(): _set_amount(_limit))
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
	send = UI.button(transfers, "TRANSFER", _send, "", true)
	transfers.hide()

func refresh() -> void:
	var p := session.selected
	var placing := session.tool != Types.Tool.NONE or not session.sim._has_core()
	if p != _source:
		_source = p
		removal_pending = false
		_transfer_open = false
		_destination = Vector2i(-1, -1)
	var tile: int = session.sim.grid[p.y][p.x] if p.x >= 0 else Types.Tile.ROCK
	if placing:
		var item := Catalog.definition(session.tool)
		title.text = item[1]
		glyph.texture = UI.icon(item[3])
		detail.text = "Tap to place · %s" % item[2]
		if not session.preview.is_empty():
			detail.text = "%d gold · %s" % [session.preview.get("cost", 0), "Ready to confirm" if session.preview.get("valid", false) else str(session.preview.get("reason", "Cannot place here"))]
	else:
		var names := ["Rock", "Floor", "Entrance", "Core", "Chest", "Spikes", "Snare", "Door", "Void", "Arcane door"]
		title.text = names[tile]
		glyph.texture = UI.icon("chest" if tile == Types.Tile.VAULT else "gem" if tile == Types.Tile.CORE else "door" if session.sim._is_door_tile(tile) else "pick")
		detail.text = "Tile %d, %d" % [p.x + 1, p.y + 1]
		if tile == Types.Tile.VAULT:
			var store := session.sim.storage_cells(p)
			if store.size() > 1: title.text = "Treasure room"
			detail.text = "%d / %d gold" % [session.sim.stored_gold(store), Types.store_capacity(store)]
		elif session.sim._is_door_tile(tile):
			var hp:=int(session.sim.door_hp.get(p,Types.DOOR_MAX_HP))
			detail.text="%d / %d HP" % [hp,Types.DOOR_MAX_HP] if hp>0 else "Unlocked" if session.sim.door_opened.get(p,false) else "Broken · Needs repair"
		elif Types.is_trap_tile(tile): detail.text = "%d / %d charges" % [session.sim.trap_charges.get(p, 0), Types.trap_max_charges(tile)]
	if removal_pending:
		title.text = "Remove structure"
		detail.text = "Return this tile to floor? No refund."
	confirm.visible = placing or removal_pending
	var repair_action:=session.check_action(p,Types.Tool.REPAIR)
	repair.visible=not placing and not removal_pending and (Types.is_trap_tile(tile) or session.sim._is_door_tile(tile) or tile==Types.Tile.VAULT)
	repair.disabled=not repair_action.get("valid",false)
	repair.text="Repair · %d gold" % repair_action.get("cost",0)
	repair.tooltip_text=str(repair_action.get("reason",""))
	remove.visible=not placing and not removal_pending and (Types.is_trap_tile(tile) or session.sim._is_door_tile(tile) or tile==Types.Tile.VAULT)
	remove.disabled=not session.can_edit()
	confirm.disabled = not session.can_edit() or not session.preview.get("valid", false)
	if removal_pending: confirm.disabled = not session.check_action(p,Types.Tool.DIG).get("valid",false)
	collect.visible = p.x >= 0 and session.sim.loot_bags.any(func(b): return b.pos == p and b.gold > 0)
	absorb.visible = p.x >= 0 and session.sim.corpses.any(func(c): return c.pos == p)
	collect.disabled = not session.can_edit()
	absorb.disabled = not session.can_edit()
	actions.visible = not removal_pending and (collect.visible or absorb.visible)
	var vault := not placing and not removal_pending and p.x >= 0 and tile == Types.Tile.VAULT
	if not vault: _transfer_open = false
	transfer.visible = vault and not _transfer_open
	transfers.visible = vault and _transfer_open
	if transfers.visible: _refresh_transfer()
	layout_changed.emit()

func _confirm() -> void:
	# Contextual removal never arms a world tool, even before confirmation.
	session.confirm_action(Types.Tool.DIG if removal_pending else -1)

func _open_transfer() -> void:
	_transfer_open = true
	_amount = session.sim.stored_gold(session.sim.storage_cells(session.selected))
	refresh()

func _close() -> void:
	if removal_pending:
		removal_pending = false
		refresh()
	elif _transfer_open:
		_transfer_open = false
		refresh()
	else: dismissed.emit()

func _refresh_transfer() -> void:
	_destinations.clear()
	var source := session.sim.storage_cells(session.selected)
	for cell in session.sim._vault_positions():
		if source.has(cell): continue
		var store := session.sim.storage_cells(cell)
		if store.front() == cell: _destinations.append(cell)
	if not _destinations.has(_destination):
		_destination = _destinations[0] if not _destinations.is_empty() else Vector2i(-1, -1)
	_limit = 0
	if _destination.x >= 0:
		var target := session.sim.storage_cells(_destination)
		var target_gold := session.sim.stored_gold(target)
		var capacity := Types.store_capacity(target)
		_limit = maxi(0, mini(session.sim.stored_gold(source), capacity - target_gold))
		var name_label := "treasure room" if target.size() > 1 else "chest %d" % (_destinations.find(_destination) + 1)
		target_label.text = "To %s · %d / %d gold\nTile %d, %d" % [name_label, target_gold, capacity, _destination.x + 1, _destination.y + 1]
	else: target_label.text = "Build another chest to transfer gold."
	_amount = clampi(_amount, 0, _limit)
	amount_label.text = "%d gold" % _amount
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
	_amount = session.sim.stored_gold(session.sim.storage_cells(session.selected))
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
