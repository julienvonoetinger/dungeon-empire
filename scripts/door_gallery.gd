@tool
extends Control
## Isolated catalogue of production doors. No game session or save access.
const Renderer = preload("res://scripts/mobile_dungeon_renderer.gd")
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const MATERIALS := ["wood", "iron", "arcane", "grille"]
const TITLES := ["Porte en bois", "Porte renforcée", "Porte magique", "Herse"]
const DIRECTIONS := ["west", "north", "east", "south"]
var direction := "west"
var opened := false
var rooms: Array[Node2D] = []
var stages: Array[Control] = []
var grid := GridContainer.new()
var scroll := ScrollContainer.new()
var orientation := OptionButton.new()
var state_button := Button.new()
var _previous_scale := Vector2i.ZERO

func _ready() -> void:
	if not Engine.is_editor_hint():
		_previous_scale = get_window().content_scale_size
		get_window().content_scale_size = Vector2i.ZERO
		get_window().title = "Dungeon Empire · Les portes"
	theme = UI.create()
	var background := ColorRect.new()
	background.color = UI.INK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_"+side, 16)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	UI.label(column, "Les portes du donjon", 26, UI.GOLD)
	var toolbar := HFlowContainer.new()
	column.add_child(toolbar)
	toolbar.add_theme_constant_override("h_separation", 12)
	orientation.custom_minimum_size = Vector2(150, 44)
	for caption in ["Vue ouest", "Vue nord", "Vue est", "Vue sud"]:
		orientation.add_item(caption)
	orientation.item_selected.connect(func(index: int): set_direction(DIRECTIONS[index]))
	toolbar.add_child(orientation)
	state_button.text = "État : fermées"
	state_button.custom_minimum_size = Vector2(170, 44)
	state_button.toggle_mode = true
	state_button.toggled.connect(set_opened)
	toolbar.add_child(state_button)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	UI.slim_scrollbar(scroll)
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for index in MATERIALS.size():
		var card := PanelContainer.new()
		var surface := UI.flat(Color("172132"), 8)
		surface.border_color = Color("524165")
		surface.set_border_width_all(1)
		surface.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", surface)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var content := VBoxContainer.new()
		card.add_child(content)
		var title := UI.label(content, TITLES[index], 21, UI.GOLD)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var stage := Control.new()
		stage.custom_minimum_size = Vector2(0, 190)
		stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.clip_contents = true
		content.add_child(stage)
		var room := Renderer.new()
		room.vortex_animation_enabled = false
		stage.add_child(room)
		rooms.append(room)
		stages.append(stage)
		stage.resized.connect(_fit_rooms)
	resized.connect(_layout)
	refresh_preview()
	_layout()

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		get_window().content_scale_size = _previous_scale

func set_direction(value: String) -> void:
	if value not in DIRECTIONS: return
	direction = value
	orientation.select(DIRECTIONS.find(value))
	refresh_preview()

func set_opened(value: bool) -> void:
	opened = value
	state_button.set_pressed_no_signal(value)
	state_button.text = "État : ouvertes" if value else "État : fermées"
	refresh_preview()

func refresh_preview() -> void:
	var along_x := direction in ["west", "east"]
	var door := Vector2i(1, 0) if along_x else Vector2i(0, 1)
	var cells := {}
	for i in 3: cells[Vector2i(i, 0) if along_x else Vector2i(0, i)] = true
	for index in rooms.size():
		rooms[index].render_plan({"cells": cells, "openings": {},
			"floor_variants": true, "door_materials": {door: MATERIALS[index]},
			"open_doors": {door: opened}}, {door: "doors/"+direction}, false, false)
	_fit_rooms()

func _layout() -> void:
	grid.columns = 2 if size.x >= 620 else 1
	_fit_rooms.call_deferred()

func _fit_rooms() -> void:
	# One common frame keeps all four materials at exactly the same scale.
	if rooms.is_empty(): return
	var bounds: Rect2 = rooms[0].get_content_rect()
	for room in rooms: bounds = bounds.merge(room.get_content_rect())
	bounds = bounds.grow(10)
	for index in rooms.size():
		var available := stages[index].size
		if available.x <= 0 or available.y <= 0: continue
		var factor := minf(available.x/bounds.size.x, available.y/bounds.size.y)
		rooms[index].scale = Vector2.ONE * factor
		rooms[index].position = available*.5 - bounds.get_center()*factor
