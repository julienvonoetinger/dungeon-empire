@tool
extends Control
## One-shot interaction with an unlocked chest. No lockpicking or state change.
const STAGE = preload("res://scripts/vulpin_chest_open_stage.gd")
const DIRECTIONS := ["se", "sw", "nw", "ne"]
const TITLES := ["Sud-est", "Sud-ouest", "Nord-ouest", "Nord-est"]
const FRAMES: SpriteFrames = preload("res://assets/previews/vulpin-chest-open/frames.tres")
const PHASES := ["Prêt", "Se penche", "Saisit", "Amorce", "Soulève", "Maintient", "Relâche", "Se redresse"]
const REPEAT_GAP := .8
var duration := 0.0
var active := true
var repeat_enabled := true
var _repeat_elapsed := 0.0
var _starts: Array[float] = []
var stages: Array[Node2D] = []
var animation_time := 0.0
var playback_speed := 1.0
var _playing := true
var _pause_button: Button
var _frame_label: Label
var _speed_select: OptionButton
var _repeat: CheckButton
var _ghost: CheckButton
var _guides: CheckButton

func _ready() -> void:
	for i in FRAMES.get_frame_count(&"se"):
		_starts.append(duration)
		duration += FRAMES.get_frame_duration(&"se", i) / FRAMES.get_animation_speed(&"se")
	_build_preview()
	set_playing(not Engine.is_editor_hint())
	set_process(not Engine.is_editor_hint())

func _build_preview() -> void:
	var background := ColorRect.new()
	background.color = Color("0e1521")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Vulpin · coffre non verrouillé"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("e6d0fa"))
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for i in 4: _add_stage(grid, i)
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 6)
	column.add_child(toolbar)
	_pause_button = _button("Pause")
	_pause_button.pressed.connect(func() -> void: set_playing(not _playing))
	toolbar.add_child(_pause_button)
	var next := _button("Pose suivante")
	next.pressed.connect(next_pose)
	toolbar.add_child(next)
	_speed_select = OptionButton.new()
	_speed_select.custom_minimum_size = Vector2(146,48)
	for caption in ["Ralenti · 0,5×", "Normal · 1×", "Rapide · 1,5×", "Double · 2×"]: _speed_select.add_item(caption)
	_speed_select.select(1)
	_speed_select.item_selected.connect(set_speed_index)
	toolbar.add_child(_speed_select)
	_ghost = CheckButton.new()
	_ghost.text = "Coffre atténué"
	_ghost.custom_minimum_size.y = 48
	_ghost.toggled.connect(set_ghost)
	toolbar.add_child(_ghost)
	_guides = CheckButton.new()
	_guides.text = "Repères"
	_guides.custom_minimum_size.y = 48
	_guides.toggled.connect(set_guides)
	toolbar.add_child(_guides)
	var replay := _button("Rejouer")
	replay.pressed.connect(replay_opening)
	toolbar.add_child(replay)
	_repeat = CheckButton.new()
	_repeat.text = "Répéter"
	_repeat.custom_minimum_size.y = 48
	_repeat.button_pressed = repeat_enabled
	_repeat.toggled.connect(set_repeat_enabled)
	toolbar.add_child(_repeat)
	_frame_label = Label.new()
	_frame_label.custom_minimum_size = Vector2(90,48)
	_frame_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frame_label.add_theme_color_override("font_color", Color("e1c77d"))
	toolbar.add_child(_frame_label)
	seek_time(0)

func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(108,48)
	return button

func _add_stage(grid: GridContainer, index: int) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141e2b")
	style.border_color = Color("3d4961")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	grid.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var label := Label.new()
	label.text = TITLES[index]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	column.add_child(label)
	var viewport := Control.new()
	viewport.custom_minimum_size = Vector2(128,60)
	viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(viewport)
	var stage := STAGE.new()
	viewport.add_child(stage)
	stage.build(DIRECTIONS[index])
	stages.append(stage)
	viewport.resized.connect(_fit_stage.bind(viewport, stage))
	_fit_stage.call_deferred(viewport, stage)

func _fit_stage(viewport: Control, stage: Node2D) -> void:
	var bounds: Rect2 = stage.get_content_rect()
	var display_scale := minf(viewport.size.x / bounds.size.x, viewport.size.y / bounds.size.y)
	stage.scale = Vector2.ONE * display_scale
	stage.position = viewport.size * .5 - bounds.get_center() * display_scale

func seek_time(seconds: float) -> void:
	animation_time = clampf(seconds, 0, duration)
	if duration - animation_time <= .000001: animation_time = duration
	active = animation_time < duration
	var frame := 0
	for i in _starts.size():
		if animation_time + .000001 >= _starts[i]: frame = i
	for stage in stages: stage.set_pose(frame)
	if is_instance_valid(_frame_label): _frame_label.text = PHASES[frame]

func next_pose() -> void:
	set_playing(false)
	_repeat_elapsed = 0
	seek_time(_starts[(stages[0].actor.frame + 1) % _starts.size()])

func replay_opening() -> void:
	_repeat_elapsed = 0
	seek_time(0)
	set_playing(true)

func set_repeat_enabled(value: bool) -> void:
	repeat_enabled = value
	_repeat_elapsed = 0
	_repeat.set_pressed_no_signal(value)

func set_playing(value: bool) -> void:
	_playing = value
	_pause_button.text = "Pause" if value else "Lire"

func set_speed_index(index: int) -> void:
	playback_speed = [0.5,1.0,1.5,2.0][clampi(index,0,3)]
	_speed_select.select(clampi(index,0,3))

func set_ghost(value: bool) -> void:
	_ghost.set_pressed_no_signal(value)
	for stage in stages: stage.set_ghost(value)

func set_guides(value: bool) -> void:
	_guides.set_pressed_no_signal(value)
	for stage in stages: stage.set_guides(value)

func _process(delta: float) -> void:
	if not _playing: return
	if active:
		seek_time(animation_time + delta * playback_speed)
		if not active: _repeat_elapsed = 0
	elif repeat_enabled:
		_repeat_elapsed += delta * playback_speed
		if _repeat_elapsed >= REPEAT_GAP: replay_opening()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: set_playing(not _playing)
		elif event.keycode == KEY_RIGHT: next_pose()
		else: return
		get_viewport().set_input_as_handled()
