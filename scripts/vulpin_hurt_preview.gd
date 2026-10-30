@tool
extends Control
## Isolated one-shot reaction review; does not create a game or apply damage.
const FRAMES: SpriteFrames = preload("res://assets/previews/vulpin-hurt/frames.tres")
const KIT: Resource = preload("res://assets/dungeon/isometric-kit/catalog.tres")
const CONTACT: Texture2D = preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const DIRECTIONS := [&"se", &"sw", &"nw", &"ne"]
const TITLES := ["Southeast", "Southwest", "Northwest", "Northeast"]
const PHASES := ["Impact", "Recoil", "Full recoil", "Brace", "Return", "Recover", "Balance", "Idle"]
const ANCHOR := Vector2(128.0, 195.92598)
const REPEAT_GAP := .8

var actors: Array[AnimatedSprite2D] = []
var reaction_time := 0.0
var reaction_duration := 0.0
var playback_speed := 1.0
var hit_count := 0
var active := false
var repeat_enabled := true
var _playing := true
var _repeat_elapsed := 0.0
var _starts: Array[float] = []
var _pause_button: Button
var _speed_select: OptionButton
var _repeat_button: CheckButton
var _status: Label

func _ready() -> void:
	for frame in FRAMES.get_frame_count(&"se"):
		_starts.append(reaction_duration)
		reaction_duration += FRAMES.get_frame_duration(&"se", frame) / FRAMES.get_animation_speed(&"se")
	_build_preview()
	seek_reaction(reaction_duration)
	set_playing(not Engine.is_editor_hint())
	set_process(not Engine.is_editor_hint())
	if not Engine.is_editor_hint():
		trigger_hit()

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
	title.text = "Vulpin · hit reaction"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("e6d0fa"))
	column.add_child(title)
	var grid := GridContainer.new()
	grid.name = "Directions"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	for index in DIRECTIONS.size():
		_add_direction(grid, index)
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 6)
	column.add_child(toolbar)
	var trigger := _button("Take a hit")
	trigger.pressed.connect(trigger_hit)
	toolbar.add_child(trigger)
	_pause_button = _button("Pause")
	_pause_button.pressed.connect(func() -> void: set_playing(not _playing))
	toolbar.add_child(_pause_button)
	var step := _button("Next frame")
	step.pressed.connect(next_pose)
	toolbar.add_child(step)
	_speed_select = OptionButton.new()
	_speed_select.custom_minimum_size = Vector2(156, 48)
	for caption in ["Slow · 0.5×", "Normal · 1×", "Fast · 1.5×", "Double · 2×"]:
		_speed_select.add_item(caption)
	_speed_select.select(1)
	_speed_select.item_selected.connect(set_speed_index)
	toolbar.add_child(_speed_select)
	_repeat_button = CheckButton.new()
	_repeat_button.text = "Repeat"
	_repeat_button.custom_minimum_size = Vector2(128, 48)
	_repeat_button.button_pressed = repeat_enabled
	_repeat_button.toggled.connect(set_repeat_enabled)
	toolbar.add_child(_repeat_button)
	_status = Label.new()
	_status.custom_minimum_size = Vector2(172, 48)
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color("e1c77d"))
	toolbar.add_child(_status)

func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(128, 48)
	return button

func _add_direction(grid: GridContainer, index: int) -> void:
	var panel := PanelContainer.new()
	panel.name = "Direction_" + str(DIRECTIONS[index])
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141e2b")
	style.border_color = Color("3d4961")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	grid.add_child(panel)
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
	var group := Node2D.new()
	stage.add_child(group)
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = KIT.get("textures")["floor-b1"]
	floor_sprite.centered = false
	floor_sprite.position = Vector2(-135, -69)
	floor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	group.add_child(floor_sprite)
	var shadow := Sprite2D.new()
	shadow.texture = CONTACT
	shadow.modulate = Color(0, 0, 0, .5)
	shadow.scale = Vector2(38, 19) / CONTACT.get_size()
	group.add_child(shadow)
	var actor := AnimatedSprite2D.new()
	actor.sprite_frames = FRAMES
	actor.animation = DIRECTIONS[index]
	actor.centered = false
	actor.offset = -ANCHOR
	actor.scale = Vector2.ONE * .85
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	group.add_child(actor)
	actors.append(actor)
	stage.resized.connect(_fit_stage.bind(stage, group))
	_fit_stage.call_deferred(stage, group)

func _fit_stage(stage: Control, group: Node2D) -> void:
	var bounds := Rect2(-150, -178, 300, 254)
	var display_scale := minf(stage.size.x / bounds.size.x, stage.size.y / bounds.size.y)
	group.scale = Vector2.ONE * display_scale
	group.position = stage.size * .5 - bounds.get_center() * display_scale

func seek_reaction(seconds: float) -> void:
	reaction_time = clampf(seconds, 0.0, reaction_duration)
	# SpriteFrames durations have float rounding; finish cleanly at the
	# nominal endpoint at every speed.
	if reaction_duration - reaction_time <= .000001:
		reaction_time = reaction_duration
	active = reaction_time < reaction_duration
	var frame := 0
	for index in _starts.size():
		if reaction_time + .000001 >= _starts[index]:
			frame = index
	for actor in actors:
		actor.set_frame_and_progress(frame, 0.0)
	_status.text = PHASES[frame]

func trigger_hit() -> void:
	hit_count += 1
	_repeat_elapsed = 0.0
	seek_reaction(0.0)
	set_playing(true)

func set_playing(value: bool) -> void:
	_playing = value
	_pause_button.text = "Pause" if value else "Play"

func set_speed_index(index: int) -> void:
	playback_speed = [0.5, 1.0, 1.5, 2.0][clampi(index, 0, 3)]
	_speed_select.select(clampi(index, 0, 3))

func set_repeat_enabled(value: bool) -> void:
	repeat_enabled = value
	_repeat_elapsed = 0.0
	_repeat_button.set_pressed_no_signal(value)

func next_pose() -> void:
	set_playing(false)
	_repeat_elapsed = 0.0
	seek_reaction(_starts[(actors[0].frame + 1) % _starts.size()])

func _process(delta: float) -> void:
	if not _playing:
		return
	if active:
		seek_reaction(reaction_time + delta * playback_speed)
		if not active:
			_repeat_elapsed = 0.0
	elif repeat_enabled:
		_repeat_elapsed += delta * playback_speed
		if _repeat_elapsed >= REPEAT_GAP:
			trigger_hit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			trigger_hit()
		elif event.keycode == KEY_RIGHT:
			next_pose()
		else:
			return
		get_viewport().set_input_as_handled()
