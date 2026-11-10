extends PanelContainer

signal tool_chosen(tool: int)
signal closed
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
const GROUPS := ["Terrain", "Doors", "Traps", "Storage"]
const GROUP_ICONS := ["pick", "door", "spike", "bag"]
const DOORS := 1
const TRAPS := 2
const CHESTS := 3
const TOOLS := [
	[Types.Tool.BUILD_ENTRANCE, "Entrance", "Free", "door", 0],
	[Types.Tool.REPAIR, "Repair", "Varies", "hammer", 0],
	[Types.Tool.TRAP_SPIKE, "Spike trap", Types.COST_SPIKE, "spike", TRAPS],
	[Types.Tool.BUILD_DOOR, "Wooden door", Types.COST_DOOR, "door", DOORS],
	[Types.Tool.BUILD_REINFORCED_DOOR, "Reinforced door", Types.COST_REINFORCED_DOOR, "door", DOORS],
	[Types.Tool.TRAP_SNARE, "Snare", Types.COST_SNARE, "snare", TRAPS],
	[Types.Tool.TRAP_VOID, "Void trap", Types.COST_VOID, "void", TRAPS],
	[Types.Tool.BUILD_MAGIC_DOOR, "Arcane door", Types.COST_MAGIC_DOOR, "door", DOORS],
	[Types.Tool.STORE, "Chest", "Free", "chest", CHESTS],
	[Types.Tool.GOLD_BAG, "Gold bag", "Free", "bag", CHESTS],
	[Types.Tool.STORE_LOCKED, "Locked chest", Types.VAULT_PROTECTION_COSTS[1], "locked", CHESTS],
	[Types.Tool.STORE_MAGIC, "Sealed chest", Types.VAULT_PROTECTION_COSTS[2], "chest", CHESTS],
]
var category := 1
var cards: Array[Dictionary] = []
var heading: Label
var row: GridContainer
var tabs: HBoxContainer
var tab_buttons: Array[Button]=[]
var count_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	heading = UI.label(header,"",17)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := UI.button(header, "✕", func(): closed.emit())
	close.tooltip_text = tr("Close catalog")
	count_label=UI.label(box,"",12,UI.MUTED)
	tabs=HBoxContainer.new(); box.add_child(tabs)
	tabs.add_theme_constant_override("separation",4)
	for index in GROUPS.size():
		var tab:=UI.button(tabs,tr(GROUPS[index]),func(): _choose_category(index))
		tab.add_theme_font_size_override("font_size",11)
		tab.add_theme_stylebox_override("normal",UI.command_surface(false,4))
		tab.add_theme_stylebox_override("pressed",UI.command_surface(true,4))
		tab.toggle_mode=true; tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tab_buttons.append(tab)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UI.slim_scrollbar(scroll)
	box.add_child(scroll)
	row = GridContainer.new()
	row.columns = 1
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for definition in TOOLS:
		var id: int = definition[0]
		var card := UI.button(row, "", func(): tool_chosen.emit(id))
		card.custom_minimum_size = Vector2(0, 72)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.toggle_mode = true
		card.tooltip_text = tr(definition[1])
		card.accessibility_name = card.tooltip_text
		var contents := HBoxContainer.new()
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(contents)
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_left = 14; contents.offset_right = -14
		contents.offset_top = 10; contents.offset_bottom = -10
		contents.add_theme_constant_override("separation", 10)
		var picture := UI.picture(contents, definition[3], 30)
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var words := VBoxContainer.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		words.add_theme_constant_override("separation", 1)
		contents.add_child(words)
		var caption := UI.label(words, tr(definition[1]), 13)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.label(words, price_text(definition), 11, UI.GOLD)
		words.minimum_size_changed.connect(func(): card.custom_minimum_size.y=maxf(72,words.get_combined_minimum_size().y+20))
		cards.append({"button": card, "contents": contents, "unlocked": false, "id": id, "category": definition[4]})
	_choose_category(category)

func fit_width(width: float) -> void:
	# Full-width portrait sheets hold two comfortable cards per row.
	row.columns = 2 if width >= 350 else 1
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)

func preferred_height() -> float:
	var box: Control = get_child(0)
	return box.get_child(0).get_combined_minimum_size().y+count_label.get_combined_minimum_size().y+tabs.get_combined_minimum_size().y+row.get_combined_minimum_size().y+42

func _choose_category(index: int) -> void:
	category = index
	heading.text = tr(GROUPS[index])
	var available := 0
	for card in cards:
		card.button.visible = card.category == index and card.unlocked
		if card.button.visible: available += 1
	for i in tab_buttons.size(): tab_buttons[i].set_pressed_no_signal(i==index)
	if is_instance_valid(count_label):
		count_label.text=tr("Available: %d") % available

func refresh(session: IsometricGameSession) -> void:
	for card in cards:
		var unlocked: bool = session.progression.allows(card.id)
		card.button.disabled = not session.can_edit() or not session.sim._has_core() or not unlocked
		card.contents.modulate = Color.WHITE if not card.button.disabled else Color("9f9e9c")
		card.unlocked = unlocked
		card.button.set_pressed_no_signal(session.tool == card.id)
	_choose_category(category)

static func price_text(item: Array, compact := false) -> String:
	if item[2] is int:
		return str(item[2]) if compact else TranslationServer.translate("%d gold") % item[2]
	return TranslationServer.translate(item[2])

static func unlocked_items(category_id: int, progression: CoreProgression) -> Array[Array]:
	var items: Array[Array] = []
	for item in TOOLS:
		if item[4] == category_id and progression.allows(item[0]): items.append(item)
	return items

static func definition(tool: int) -> Array:
	# Legacy/probe commands can still use Dig; it is no longer a menu item.
	if tool == Types.Tool.DIG: return [tool, "Dig", Types.COST_DIG, "pick", 0]
	for item in TOOLS:
		if item[0] == tool: return item
	return [Types.Tool.NONE, "Core", "Free", "gem", 0]
