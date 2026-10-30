@tool
extends Control
## Four static idle views; no animation clock or game/save instantiated.
const FRAMES: SpriteFrames = preload("res://assets/previews/vulpin-idle/frames.tres")
const KIT: Resource = preload("res://assets/dungeon/isometric-kit/catalog.tres")
const CONTACT: Texture2D = preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const DIRECTIONS := [&"se", &"sw", &"nw", &"ne"]
const TITLES := ["Southeast", "Southwest", "Northwest", "Northeast"]

func _ready() -> void:
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
	title.text = "Vulpin · idle"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("e6d0fa"))
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	for index in DIRECTIONS.size():
		_add_direction(grid, index)
	var caption := Label.new()
	caption.text = "One still image per direction"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", Color("b8c2d4"))
	column.add_child(caption)

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
	var actor := Sprite2D.new()
	actor.name = "Idle_" + str(DIRECTIONS[index])
	actor.texture = FRAMES.get_frame_texture(DIRECTIONS[index], 0)
	actor.centered = false
	actor.offset = -Vector2(FRAMES.get_meta("ground_anchor"))
	actor.scale = Vector2.ONE * float(FRAMES.get_meta("hero_scale"))
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	group.add_child(actor)
	stage.resized.connect(_fit_stage.bind(stage, group))
	_fit_stage.call_deferred(stage, group)

func _fit_stage(stage: Control, group: Node2D) -> void:
	var bounds := Rect2(-150, -178, 300, 254)
	var display_scale := minf(stage.size.x / bounds.size.x, stage.size.y / bounds.size.y)
	group.scale = Vector2.ONE * display_scale
	group.position = stage.size * .5 - bounds.get_center() * display_scale
