extends ColorRect

var session
var source := Vector2i(-1, -1)
var destinations: Array[Vector2i] = []
var title: Label
var balance: Label
var choose: Button
var options: VBoxContainer
var target: OptionButton
var quantity: SpinBox
var submit: Button
var panel: PanelContainer
var protection: Label
var upgrade_locked: Button
var upgrade_magic: Button
var repair: Button

func setup(ui) -> void:
	session = ui
	color = Color(0.02, 0.03, 0.04, 0.8)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = ui._band()
	panel.reparent(center)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	title = ui._label("Coffre", 24, ui.GOLD)
	content.add_child(title)
	balance = ui._label("", 20)
	content.add_child(balance)
	protection = ui._label("", 18)
	content.add_child(protection)
	upgrade_locked = ui._button("Verrouiller : 40 or", func(): _protect(1))
	upgrade_magic = ui._button("Sceller : 80 or", func(): _protect(2))
	repair = ui._button("Reverrouiller : 15 or", _repair)
	for action in [upgrade_locked, upgrade_magic, repair]:
		action.custom_minimum_size.y = 44
		content.add_child(action)
	choose = ui._button("Transf\u00e9rer", _choose_destination)
	choose.custom_minimum_size.y = 44
	content.add_child(choose)
	options = VBoxContainer.new()
	options.add_theme_constant_override("separation", 8)
	content.add_child(options)
	options.add_child(ui._label("Destination", 18))
	target = OptionButton.new()
	target.custom_minimum_size.y = 44
	target.add_theme_font_size_override("font_size", 18)
	target.item_selected.connect(func(_index): _update_limit())
	options.add_child(target)
	options.add_child(ui._label("Quantit\u00e9", 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	options.add_child(row)
	quantity = SpinBox.new()
	quantity.step = 1
	quantity.min_value = 1
	quantity.custom_minimum_size = Vector2(100, 44)
	quantity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity.value_changed.connect(func(value): submit.disabled = value < 1)
	row.add_child(quantity)
	var all_button: Button = ui._button("Tout transf\u00e9rer", _transfer_all)
	all_button.custom_minimum_size.y = 44
	row.add_child(all_button)
	submit = ui._button("Confirmer", _commit)
	submit.custom_minimum_size.y = 44
	options.add_child(submit)
	var cancel: Button = ui._button("Fermer", close)
	cancel.custom_minimum_size.y = 44
	content.add_child(cancel)
	resized.connect(_resize_panel)
	_resize_panel()
	hide()

func _resize_panel() -> void:
	panel.custom_minimum_size.x = minf(420, maxf(240, size.x - 40))

func open(cell: Vector2i) -> void:
	if session.paused or session.g.raid_active or session.g.game_over or session.result_open or session.modal.visible:
		return
	var vaults: Dictionary = session.g._storage_state().vaults
	if not vaults.has(cell):
		return
	source = cell
	session.router.cancel()
	session._cancel()
	session.paused = true
	title.text = "Coffre (%d, %d)" % [cell.x, cell.y]
	balance.text = "%d / %d or" % [vaults[cell], GameTypes.VAULT_CAPACITY]
	var tier := int(session.g.sim.vault_locks.get(cell, 0))
	var intact: bool = session.g.sim.vault_protected(cell)
	protection.text = "Sans protection" if tier == 0 else ("Verrou intact" if tier == 1 else "Sceau intact") if intact else "Protection ouverte"
	protection.modulate = Color("c985ec") if tier == 2 and intact else session.GOLD if intact else Color("b4b4b4")
	upgrade_locked.visible = tier == 0
	upgrade_locked.disabled = session.g.gold < GameTypes.VAULT_PROTECTION_COSTS[1]
	upgrade_magic.visible = tier < 2
	var magic_cost: int = GameTypes.VAULT_PROTECTION_COSTS[2] - GameTypes.VAULT_PROTECTION_COSTS[tier]
	var unlocked: bool = session.profile.allows(GameTypes.Tool.STORE_MAGIC)
	upgrade_magic.text = "Sceller : %d or" % magic_cost if unlocked else "Sceau : niveau 4 requis"
	upgrade_magic.disabled = not unlocked or session.g.gold < magic_cost
	repair.visible = tier > 0 and not intact
	repair.text = "Reverrouiller : 15 or" if tier == 1 else "Restaurer le sceau : 15 or"
	repair.disabled = session.g.gold < GameTypes.COST_REPAIR_VAULT
	destinations.clear()
	target.clear()
	for p in vaults:
		if p != source and int(vaults[p]) < GameTypes.VAULT_CAPACITY:
			destinations.append(p)
			target.add_item("Coffre (%d, %d) : %d / %d" % [p.x, p.y, vaults[p], GameTypes.VAULT_CAPACITY])
	choose.disabled = int(vaults[cell]) <= 0 or destinations.is_empty()
	choose.tooltip_text = "Coffre vide" if int(vaults[cell]) <= 0 else "Aucun coffre disponible" if destinations.is_empty() else ""
	choose.show()
	options.hide()
	show()
	session._refresh()

func _choose_destination() -> void:
	if choose.disabled:
		return
	choose.hide()
	options.show()
	target.select(0)
	_update_limit()

func _protect(tier: int) -> void:
	if not visible or tier not in [1, 2]:
		return
	var tool := GameTypes.Tool.STORE_LOCKED if tier == 1 else GameTypes.Tool.STORE_MAGIC
	if session.commands.commit(session.g.sim, session.profile, tool, source):
		_after_protection_change()

func _repair() -> void:
	if visible and session.g.sim.repair_vault(source):
		_after_protection_change()

func _after_protection_change() -> void:
	session._save()
	session.g._sync_world()
	session._sync_vault_badges()
	close()
	open(source)

func _update_limit() -> void:
	var vaults: Dictionary = session.g._storage_state().vaults
	var limit := 0
	if target.selected >= 0 and target.selected < destinations.size():
		var destination := destinations[target.selected]
		if vaults.has(destination):
			limit = mini(int(vaults.get(source, 0)), GameTypes.VAULT_CAPACITY - int(vaults[destination]))
	quantity.min_value = 1 if limit > 0 else 0
	quantity.max_value = limit
	quantity.value = limit
	submit.disabled = limit <= 0

func _transfer_all() -> void:
	_update_limit()
	_commit()

func _commit() -> void:
	if target.selected < 0 or target.selected >= destinations.size() or session.g.raid_active or session.g.game_over:
		close()
		return
	var moved: int = session.g.sim.transfer_gold(source, destinations[target.selected], int(quantity.value))
	if moved > 0:
		session._save()
		session.g._sync_world()
		session._sync_vault_badges()
	close()

func close() -> void:
	if not visible:
		return
	hide()
	session.paused = false
	session._refresh()
