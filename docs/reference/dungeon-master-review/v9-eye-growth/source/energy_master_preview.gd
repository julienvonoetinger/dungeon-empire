extends Control
## Standalone preview. No game session, save access, or introduction integration.
const Entity = preload("res://scripts/previews/energy_master.gd")
const DURATION := 24.0
var viewport := SubViewport.new()
var entity: Node3D
var camera := Camera3D.new()
var stage := TextureRect.new()
var controls := VBoxContainer.new()
var timeline := HSlider.new()
var view_slider := HSlider.new()
var pause_button := Button.new()
var gaze_button := Button.new()
var orbit_button := CheckButton.new()
var status := Label.new()
var clock := 0.0
var paused := false
var view_angle := 0.0

func _ready() -> void:
	get_window().title = "Maître du donjon · Prototype d’énergie"
	get_window().content_scale_size = Vector2i.ZERO
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("202431")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := Label.new()
	title.text = "Maître du donjon"
	title.add_theme_font_size_override("font_size",24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 10
	var subtitle := Label.new()
	subtitle.text = "Noyau noir · vortex · regard"
	subtitle.modulate = Color("b2adc7")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.position.y = 40
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.size = Vector2i(640,640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202431")
	world_environment.environment = environment
	viewport.add_child(world_environment)
	entity = Entity.new()
	viewport.add_child(entity)
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.2
	camera.near = 0.05
	camera.far = 30.0
	camera.current = true
	stage.texture = viewport.get_texture()
	stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	add_child(controls)
	controls.add_theme_constant_override("separation",6)
	var row := HBoxContainer.new()
	controls.add_child(row)
	pause_button.text = "Pause"
	pause_button.pressed.connect(func(): set_paused(not paused))
	row.add_child(pause_button)
	var replay := Button.new()
	replay.text = "Rejouer"
	replay.pressed.connect(func(): set_time(0.0); set_paused(false))
	row.add_child(replay)
	gaze_button.text = "Regard"
	gaze_button.toggle_mode = true
	gaze_button.toggled.connect(func(_value): _present())
	row.add_child(gaze_button)
	orbit_button.text = "Rotation"
	orbit_button.toggled.connect(func(_value): _present())
	row.add_child(orbit_button)
	for child in row.get_children():
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		child.custom_minimum_size.y = 42
	timeline.max_value = DURATION
	timeline.step = 0.01
	timeline.custom_minimum_size.y = 22
	timeline.value_changed.connect(set_time)
	controls.add_child(timeline)
	var view_row := HBoxContainer.new()
	controls.add_child(view_row)
	var view_label := Label.new()
	view_label.text = "Vue"
	view_row.add_child(view_label)
	view_slider.min_value = -55
	view_slider.max_value = 55
	view_slider.step = 0.5
	view_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_slider.custom_minimum_size.y = 24
	view_slider.value_changed.connect(set_view_angle)
	view_row.add_child(view_slider)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size",13)
	status.modulate = Color("c8bedb")
	controls.add_child(status)
	resized.connect(_fit)
	_fit()
	_present()

func _fit() -> void:
	stage.position = Vector2(8,65)
	stage.size = Vector2(maxf(1,size.x-16),maxf(1,size.y-220))
	var resolution := clampi(int(minf(stage.size.x,stage.size.y)*1.25),256,960)
	viewport.size = Vector2i(resolution,resolution)
	controls.position = Vector2(maxf(8,(size.x-600)/2.0),size.y-146)
	controls.size = Vector2(minf(600,size.x-16),138)

func set_paused(value: bool) -> void:
	paused = value
	pause_button.text = "Reprendre" if paused else "Pause"

func set_time(value: float) -> void:
	clock = clampf(value,0.0,DURATION)
	timeline.set_value_no_signal(clock)
	_present()

func set_view_angle(value: float) -> void:
	view_angle = clampf(value,-55.0,55.0)
	view_slider.set_value_no_signal(view_angle)
	_present()

func _process(delta: float) -> void:
	if not paused:
		set_time(fposmod(clock+delta,DURATION))

func _present() -> void:
	if not is_instance_valid(entity): return
	var manifestation := smoothstep(0.0,3.0,clock)*(1.0-smoothstep(22.0,24.0,clock))
	var attention := smoothstep(5.5,9.0,clock)*(1.0-smoothstep(17.0,21.0,clock))
	if gaze_button.button_pressed: attention = 1.0
	entity.present(clock,attention,manifestation)
	var angle := deg_to_rad(view_angle)
	if orbit_button.button_pressed: angle += sin(clock*0.22)*0.48
	camera.position = Vector3(sin(angle)*7.0,0.35,cos(angle)*7.0)
	camera.look_at(Vector3.ZERO)
	var phase := "Observation" if attention > 0.5 else "Présence"
	if clock < 3.0: phase = "Le vortex s’ouvre"
	elif clock < 8.0: phase = "L’œil grandit"
	elif clock < 9.0: phase = "Le regard se forme"
	if clock >= 22.0: phase = "Dissipation"
	status.text = "%s · %.1f / 24 s" % [phase,clock]
