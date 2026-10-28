@tool
extends Control
## Two back-and-forth walking paths; no game session or player save.
const CORRIDOR = preload("res://scripts/vulpin_walk_corridor.gd")
# Normal speed is the former 1.5x: 15 held poses/s, with matching root travel.
const BASE_WALK_RATE := 1.5
const TITLES := ["Sud-est ↔ Nord-ouest", "Sud-ouest ↔ Nord-est"]
const FACING := {&"se": "Sud-est", &"sw": "Sud-ouest", &"nw": "Nord-ouest", &"ne": "Nord-est"}

# Both gait scenes share layout and playback, but have their own rendered poses
# and stride. Defaults preserve the approved normal walking speed.
@export var preview_title := "Vulpin · marche en couloir"
@export var animation_frames: SpriteFrames = preload("res://assets/previews/vulpin-walk/frames.tres")
@export_range(1.0, 60.0) var pose_fps := 10.0
@export_range(.01, 10.0) var model_travel_units_per_second := .65
@export_range(.1, 4.0) var base_playback_rate := BASE_WALK_RATE

var actors: Array[AnimatedSprite2D] = []
var corridors: Array[Node2D] = []
var walk_time := 0.0
var playback_speed := 1.0
var _playing := false
var _pause_button: Button
var _frame_label: Label
var _speed_select: OptionButton
var _grid: GridContainer
var _direction_labels: Array[Label] = []

func _ready() -> void:
	_build_preview()
	set_playing(not Engine.is_editor_hint())
	set_process(not Engine.is_editor_hint())
	resized.connect(_fit_columns)
	_fit_columns()

func _build_preview() -> void:
	var background := ColorRect.new()
	background.color = Color("0e1521")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new()
	title.text = preview_title
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("e6d0fa"))
	column.add_child(title)
	_grid = GridContainer.new()
	_grid.name = "Corridors"
	_grid.columns = 2
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	column.add_child(_grid)
	for index in 2:
		_add_corridor(index)
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 6)
	column.add_child(toolbar)
	_pause_button = _button("Pause")
	_pause_button.pressed.connect(func() -> void: set_playing(not _playing))
	toolbar.add_child(_pause_button)
	var next_button := _button("Pose suivante")
	next_button.pressed.connect(next_pose)
	toolbar.add_child(next_button)
	var restart_button := _button("Recommencer")
	restart_button.pressed.connect(func() -> void: set_walk_time(0.0))
	toolbar.add_child(restart_button)
	_speed_select = OptionButton.new()
	_speed_select.name = "PlaybackSpeed"
	_speed_select.custom_minimum_size = Vector2(156, 48)
	for caption in ["Ralenti · 0,5×", "Normal · 1×", "Rapide · 1,5×", "Double · 2×"]:
		_speed_select.add_item(caption)
	_speed_select.select(1)
	_speed_select.item_selected.connect(set_speed_index)
	toolbar.add_child(_speed_select)
	_frame_label = Label.new()
	_frame_label.custom_minimum_size = Vector2(108, 48)
	_frame_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frame_label.add_theme_color_override("font_color", Color("e1c77d"))
	toolbar.add_child(_frame_label)
	set_walk_time(0.0)

func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(128, 48)
	return button

func _add_corridor(index: int) -> void:
	var panel := PanelContainer.new()
	panel.name = "Corridor_" + str(index)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141e2b")
	style.border_color = Color("3d4961")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	_grid.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var label := Label.new()
	label.text = TITLES[index]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	column.add_child(label)
	var stage := Control.new()
	stage.name = "Stage"
	stage.custom_minimum_size = Vector2(128, 72)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(stage)
	var corridor := CORRIDOR.new()
	corridor.name = "DungeonCorridor"
	stage.add_child(corridor)
	corridor.build(index, animation_frames, pose_fps, model_travel_units_per_second)
	corridors.append(corridor)
	actors.append(corridor.actor)
	var direction_label := Label.new()
	direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	direction_label.add_theme_color_override("font_color", Color("bba8d2"))
	column.add_child(direction_label)
	_direction_labels.append(direction_label)
	stage.resized.connect(_fit_stage.bind(stage, corridor))
	_fit_stage.call_deferred(stage, corridor)

func _fit_columns() -> void:
	_grid.columns = 1 if size.y > size.x else 2

func _fit_stage(stage: Control, corridor: Node2D) -> void:
	var bounds: Rect2 = corridor.get_content_rect()
	var display_scale := minf(stage.size.x / bounds.size.x, stage.size.y / bounds.size.y)
	corridor.scale = Vector2.ONE * display_scale
	corridor.position = stage.size * .5 - bounds.get_center() * display_scale

func set_playing(value: bool) -> void:
	_playing = value
	if is_instance_valid(_pause_button):
		_pause_button.text = "Pause" if value else "Lire"

func next_pose() -> void:
	set_playing(false)
	set_walk_time((floor(walk_time * pose_fps + .0001) + 1.0) / pose_fps)

func set_walk_time(seconds: float) -> void:
	walk_time = maxf(seconds, 0.0)
	for index in corridors.size():
		corridors[index].set_walk_time(walk_time)
		_direction_labels[index].text = ("Aller · " if corridors[index].outbound else "Retour · ") + FACING[actors[index].animation]
	if is_instance_valid(_frame_label):
		_frame_label.text = "Pose %d / %d" % [actors[0].frame + 1, animation_frames.get_frame_count(actors[0].animation)]

func set_speed_index(index: int) -> void:
	playback_speed = [0.5, 1.0, 1.5, 2.0][clampi(index, 0, 3)]
	if is_instance_valid(_speed_select):
		_speed_select.select(clampi(index, 0, 3))

func _process(delta: float) -> void:
	if _playing:
		set_walk_time(walk_time + delta * base_playback_rate * playback_speed)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			set_playing(not _playing)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			next_pose()
			get_viewport().set_input_as_handled()
