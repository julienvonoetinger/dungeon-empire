extends Control
## The shelf above the build toolbar arms the normal placement tools.

signal tool_chosen(tool: int)
signal closed

const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Catalog = preload("res://scripts/game/ui/hud_catalog.gd")
const TOOL_ICONS := {
	GameTypes.Tool.DIG: preload("res://assets/ui/master/build/pickaxe.svg"),
	GameTypes.Tool.BUILD_DOOR: preload("res://assets/ui/black-gold/door.svg"),
	GameTypes.Tool.BUILD_REINFORCED_DOOR: preload("res://assets/ui/master/build/reinforced-door.svg"),
	GameTypes.Tool.BUILD_MAGIC_DOOR: preload("res://assets/ui/master/build/arcane-door.svg"),
	GameTypes.Tool.TRAP_SPIKE: preload("res://assets/ui/master/badges/spike.svg"),
	GameTypes.Tool.TRAP_SNARE: preload("res://assets/ui/master/badges/snare.svg"),
	GameTypes.Tool.TRAP_VOID: preload("res://assets/ui/master/badges/void.svg"),
	GameTypes.Tool.STORE: preload("res://assets/ui/black-gold/chest.svg"),
	GameTypes.Tool.GOLD_BAG: preload("res://assets/game/introduction/village-gold-bag.png"),
	GameTypes.Tool.STORE_LOCKED: preload("res://assets/ui/master/build/locked-chest.svg"),
	GameTypes.Tool.STORE_MAGIC: preload("res://assets/ui/master/build/sealed-chest.svg"),
}
const FAMILY_TOOLS := {Catalog.DOORS:GameTypes.Tool.BUILD_DOOR, Catalog.TRAPS:GameTypes.Tool.TRAP_SPIKE, Catalog.CHESTS:GameTypes.Tool.STORE}
const COIN = preload("res://assets/ui/black-gold/coin.svg")
const OUTSIDE := -1
const CARD_WIDTH := 145.0
const SHELF_HEIGHT := 50.0
const PRICE_SIZE := 12

var choices: Array[Array] = []
var hud_buttons: Array[BaseButton] = []
var category := Catalog.DOORS
var cards: Array[Rect2] = []
var shelf := Rect2()
var _session: IsometricGameSession
var _hover := OUTSIDE
var _pointer := -2
var _start := Vector2.ZERO
var _dragged := false
var _price_style := UI.flat(Color("0c1625d9"), 7)

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	hide()

func _has_point(point: Vector2) -> bool:
	# Let the HUD handle its own buttons, including touch capture and cancellation.
	var hud_point := get_global_transform() * point
	for button in hud_buttons:
		if not button.disabled and button.is_visible_in_tree() and button.get_global_rect().has_point(hud_point):
			return false
	return Rect2(Vector2.ZERO, size).has_point(point)

func open(session: IsometricGameSession, group: int, items: Array[Array]) -> void:
	_session = session
	category = group
	set_choices(items)
	cancel_pointer()
	show()
	grab_focus()

func set_choices(items: Array[Array]) -> void:
	if choices != items:
		choices = items
		cards.clear()
		cancel_pointer()
	queue_redraw()

func fit(safe: Rect2, footer_top: float) -> void:
	cards.clear()
	if choices.is_empty(): return
	var width := minf(safe.size.x, choices.size() * CARD_WIDTH)
	shelf = Rect2(roundf(safe.get_center().x - width / 2), footer_top - SHELF_HEIGHT, width, SHELF_HEIGHT)
	for i in choices.size():
		var left := roundf(shelf.position.x + width * i / choices.size())
		var right := roundf(shelf.position.x + width * (i + 1) / choices.size())
		cards.append(Rect2(left, shelf.position.y, right - left, shelf.size.y))
	queue_redraw()

func choice_point(index: int) -> Vector2:
	return cards[index].get_center()

static func item_name(item: Array) -> String:
	match item[0]:
		GameTypes.Tool.BUILD_DOOR: return TranslationServer.translate("Wooden")
		GameTypes.Tool.BUILD_REINFORCED_DOOR: return TranslationServer.translate("Reinforced")
		GameTypes.Tool.BUILD_MAGIC_DOOR: return TranslationServer.translate("Arcane")
		GameTypes.Tool.TRAP_SPIKE: return TranslationServer.translate("Spikes")
		GameTypes.Tool.TRAP_VOID: return TranslationServer.translate("Void")
		GameTypes.Tool.STORE_LOCKED: return TranslationServer.translate("Locked")
		GameTypes.Tool.STORE_MAGIC: return TranslationServer.translate("Sealed")
	return TranslationServer.translate(item[1])

static func item_icon(item: Array) -> Texture2D:
	return TOOL_ICONS[item[0]]

static func family_icon(category_id: int) -> Texture2D:
	return TOOL_ICONS[FAMILY_TOOLS[category_id]]

static func minimum_cost(session: IsometricGameSession, tool: int) -> int:
	if tool == GameTypes.Tool.STORE_LOCKED: return GameTypes.VAULT_PROTECTION_COSTS[1]
	if tool == GameTypes.Tool.STORE_MAGIC:
		var cost: int = GameTypes.VAULT_PROTECTION_COSTS[2]
		if session.sim.vault_locks.values().has(1): cost -= GameTypes.VAULT_PROTECTION_COSTS[1]
		return cost
	return GameTypes.fixed_tool_cost(tool)

func _draw() -> void:
	if cards.is_empty(): return
	var font := get_theme_default_font()
	for i in cards.size():
		var card := cards[i]
		var item := choices[i]
		var available := _session.sim.gold >= minimum_cost(_session, item[0])
		if available and _hover == i:
			draw_rect(card.grow_side(SIDE_TOP, -1), Color("a76cff2e"))
		var compact := card.size.x < 126
		var art_size := 25.0 if compact else 32.0
		var gap := 4.0 if compact else 7.0
		var font_size := 13 if compact else 15
		var title := item_name(item)
		var text_space := card.size.x - art_size - gap - 4
		while font_size > 11 and font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > text_space:
			font_size -= 1
		var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var price := Catalog.price_text(item, true)
		var badge := price_badge(price)
		var column_width := maxf(title_width, badge.size.x)
		art_size = minf(art_size, maxf(0, card.size.x - column_width - gap - 4))
		var width := art_size + gap + column_width
		var left := roundf(card.get_center().x - width / 2)
		var art := Rect2(left, roundf(card.get_center().y - art_size / 2), art_size, art_size)
		draw_texture_rect(item_icon(item), art, false, Color.WHITE if available else UI.MUTED.darkened(.32))
		var text_left := art.end.x + gap
		var top := card.get_center().y - (font.get_height(font_size) + 2 + badge.size.y) / 2
		var baseline := Vector2(text_left + title_width / 2, roundf(top + font.get_ascent(font_size)))
		_text(title, baseline, font_size, UI.TEXT if available else UI.MUTED)
		badge.position = Vector2(text_left, roundf(top + font.get_height(font_size) + 2))
		_draw_price(badge, price, available)

func price_badge(price: String) -> Rect2:
	var width := get_theme_default_font().get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_SIZE).x
	if price.is_valid_int(): width += 14
	return Rect2(Vector2.ZERO, Vector2(ceilf(width) + 10, 18))

func _draw_price(rect: Rect2, price: String, available: bool) -> void:
	draw_style_box(_price_style, rect)
	var middle := rect.get_center()
	if price.is_valid_int():
		draw_texture_rect(COIN, Rect2(rect.position + Vector2(5, 3), Vector2(12, 12)), false)
		middle.x += 7
	var font := get_theme_default_font()
	middle.y += (font.get_ascent(PRICE_SIZE) - font.get_descent(PRICE_SIZE)) / 2
	_text(price, middle, PRICE_SIZE, Color("ffd998") if available else UI.MUTED)

func _text(value: String, baseline: Vector2, font_size: int, tint: Color) -> void:
	var font := get_theme_default_font()
	var pos := baseline - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0)
	draw_string_outline(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("090e19"))
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

func _choice_at(point: Vector2) -> int:
	for i in cards.size():
		if cards[i].has_point(point): return i
	return OUTSIDE

func _activate(index: int) -> void:
	if index < 0: closed.emit()
	else: tool_chosen.emit(choices[index][0])

func _set_hover(index: int) -> void:
	if _hover != index:
		_hover = index
		queue_redraw()

func cancel_pointer() -> void:
	_pointer = -2
	_dragged = false
	_set_hover(OUTSIDE)

func _press(id: int, at: Vector2, down: bool) -> void:
	if down:
		_pointer = id
		_start = at
		_dragged = false
		_set_hover(_choice_at(at))
	elif _pointer == id:
		var index := _choice_at(at)
		var activate := not _dragged and at.distance_to(_start) <= 14 and index == _choice_at(_start)
		cancel_pointer()
		if activate: _activate(index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed: return
		if event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_focus_prev") or event.is_action("ui_focus_next"):
			var step := -1 if event.is_action("ui_left") or event.is_action("ui_focus_prev") else 1
			var next := posmod(_hover + step, choices.size()) if _hover >= 0 else (0 if step > 0 else choices.size() - 1)
			_set_hover(next)
		elif event.is_action("ui_accept") and _hover >= 0: _activate(_hover)
		elif event.is_action("ui_cancel"): closed.emit()
		else: return
	elif event is InputEventMouse and event.device == -1:
		pass # Touch is handled directly.
	elif _session.get_node("Input")._touches.size() > 1:
		cancel_pointer()
	elif event is InputEventScreenTouch:
		if event.canceled: cancel_pointer()
		else: _press(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_press(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion or (event is InputEventScreenDrag and event.index == _pointer):
		if _pointer != -2 and event.position.distance_to(_start) > 14: _dragged = true
		_set_hover(OUTSIDE if _dragged else _choice_at(event.position))
	accept_event()
