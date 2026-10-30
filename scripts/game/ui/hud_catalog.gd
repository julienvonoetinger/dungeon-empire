extends PanelContainer

signal tool_chosen(tool: int)
signal closed
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
const GROUPS := ["Terrain", "Doors", "Traps", "Treasures"]
const GROUP_ICONS := ["pick", "door", "spike", "chest"]
const TOOLS := [
	[Types.Tool.DIG, "Dig", "5 gold", "pick", 0],
	[Types.Tool.BUILD_ENTRANCE, "Entrance", "Free", "door", 0],
	[Types.Tool.REPAIR, "Repair", "Varies", "hammer", 0],
	[Types.Tool.TRAP_SPIKE, "Spikes", "35 gold", "spike", 2],
	[Types.Tool.BUILD_DOOR, "Door", "40 gold", "door", 1],
	[Types.Tool.TRAP_SNARE, "Snare", "30 gold", "snare", 2],
	[Types.Tool.TRAP_VOID, "Void", "45 gold", "void", 2],
	[Types.Tool.BUILD_MAGIC_DOOR, "Arcane door", "80 gold", "door", 1],
	[Types.Tool.STORE, "Chest", "Free", "chest", 3],
	[Types.Tool.STORE_LOCKED, "Locked", "40 gold", "locked", 3],
	[Types.Tool.STORE_MAGIC, "Sealed", "80 gold", "chest", 3],
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
	close.tooltip_text = "Close catalog"
	count_label=UI.label(box,"",12,UI.MUTED)
	tabs=HBoxContainer.new(); box.add_child(tabs)
	tabs.add_theme_constant_override("separation",4)
	for index in GROUPS.size():
		var tab:=UI.button(tabs,GROUPS[index],func(): _choose_category(index))
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
		card.tooltip_text = definition[1]
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
		var caption := UI.label(words, definition[1], 13)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.label(words, definition[2], 11, UI.GOLD)
		var lock_label := UI.label(words, "", 11, UI.MUTED)
		words.minimum_size_changed.connect(func(): card.custom_minimum_size.y=maxf(72,words.get_combined_minimum_size().y+20))
		cards.append({"button": card, "contents": contents, "lock": lock_label, "id": id, "category": definition[4]})
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
	heading.text = GROUPS[index]
	for card in cards: card.button.visible = card.category == index
	for i in tab_buttons.size(): tab_buttons[i].set_pressed_no_signal(i==index)
	if is_instance_valid(count_label):
		var unlocked:=0; var total:=0
		for card in cards:
			if card.category==index:
				total+=1
				if not card.lock.visible: unlocked+=1
		count_label.text="%d / %d unlocked · tap to select" % [unlocked,total]

func refresh(session: IsometricGameSession) -> void:
	for card in cards:
		var unlocked: bool = session.progression.allows(card.id)
		card.button.disabled = not session.can_edit() or not session.sim._has_core() or not unlocked
		card.contents.modulate = Color.WHITE if not card.button.disabled else Color("9f9e9c")
		card.lock.text = "Lv. %d" % session.progression.required_level(card.id) if not unlocked else ""
		card.lock.visible = not unlocked
		card.button.set_pressed_no_signal(session.tool == card.id)
	_choose_category(category)

static func definition(tool: int) -> Array:
	for item in TOOLS:
		if item[0] == tool: return item
	return [Types.Tool.NONE, "Core", "Free", "gem", 0]
