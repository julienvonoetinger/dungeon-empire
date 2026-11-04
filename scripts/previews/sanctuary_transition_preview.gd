extends Node
const GAME = preload("res://scenes/game/DungeonGame.tscn")
var game: Node
var intro: CanvasLayer
var clock := 23.5
var paused := false
var timeline := HSlider.new()
var pause_button := Button.new()
var readout := Label.new()
var duration := 0.0

func _ready() -> void:
	get_window().title="Invocation · Descente vers le donjon"
	get_window().content_scale_size=Vector2i.ZERO
	game=GAME.instantiate()
	game.persistence_enabled=false
	add_child(game)
	game.restart(false,true)
	game.set_process(false)
	intro=game.get_node("Introduction")
	intro.dialogue.bottom_reserve=48.
	intro.set_process(false)
	duration=intro.Film.DURATION+intro.ENTRY_DURATION
	if OS.get_cmdline_user_args().has("--from-start"):
		clock=0.
	if OS.get_cmdline_user_args().has("--core-review"):
		clock=intro.Film.DURATION+5.5
		paused=true
	var controls := CanvasLayer.new()
	controls.layer=20
	add_child(controls)
	var panel := PanelContainer.new()
	controls.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top=-48
	var row := HBoxContainer.new()
	panel.add_child(row)
	pause_button.text="Pause"
	pause_button.pressed.connect(func(): paused=not paused;_button_text())
	row.add_child(pause_button)
	for entry in [["Début",0.0],["Entrée",23.5]]:
		var button := Button.new()
		button.text=entry[0]
		var start: float=entry[1]
		button.pressed.connect(func():clock=start;paused=false;_button_text();present(clock))
		row.add_child(button)
	timeline.min_value=0.
	timeline.max_value=duration
	timeline.step=.01
	timeline.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	timeline.value_changed.connect(func(value):clock=value;present(clock))
	row.add_child(timeline)
	row.add_child(readout)
	present(clock)
	_button_text()

func _button_text() -> void:
	pause_button.text="Reprendre" if paused else "Pause"

func present(time: float) -> void:
	if time<intro.Film.DURATION:
		if intro.shot!=intro.Shot.RITUAL: intro._set_shot(intro.Shot.RITUAL)
		intro.elapsed=time
		intro.film.present(time)
		intro.dialogue.present("ritual",time)
		intro.film.modulate.a=1.
		intro.veil.color=Color(.025,.009,.045,smoothstep(intro.Film.DURATION-1.,intro.Film.DURATION,time))
	elif time<duration:
		if intro.shot!=intro.Shot.ENTRANCE: intro._set_shot(intro.Shot.ENTRANCE)
		intro.elapsed=time-intro.Film.DURATION
		intro._walk_in(intro.elapsed/intro.ENTRY_DURATION)
	elif intro.shot!=intro.Shot.LESSON:
		intro._set_shot(intro.Shot.LESSON)
	intro.set_process(false)
	timeline.set_value_no_signal(time)
	intro.view.set_core_cinematic_time(maxf(0.,time-intro.Film.DURATION))
	readout.text="%.1f s" % time

func _process(delta: float) -> void:
	if paused: return
	clock=minf(clock+delta,duration)
	present(clock)
	if clock>=duration:
		paused=true
		_button_text()
