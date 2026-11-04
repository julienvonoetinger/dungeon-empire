extends Control
const Film = preload("res://scripts/game/invocation_sanctuary.gd")
var film := Film.new()
var clock := 0.0
var paused := false
var timeline := HSlider.new()
var pause_button := Button.new()
func _ready() -> void:
	get_window().title = "Invocation · Arrivée et rituel"
	get_window().content_scale_size = Vector2i.ZERO
	add_child(film)
	film.offset_bottom=-64
	film.clip_contents=true
	var panel := HBoxContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=12;panel.offset_right=-12;panel.offset_top=-50;panel.offset_bottom=-10
	pause_button.text="Pause"
	pause_button.pressed.connect(func(): paused=not paused;pause_button.text="Reprendre" if paused else "Pause")
	panel.add_child(pause_button)
	var replay := Button.new()
	replay.text="Rejouer"
	replay.pressed.connect(func(): clock=0;paused=false;pause_button.text="Pause")
	panel.add_child(replay)
	timeline.max_value=Film.DURATION
	timeline.step=.01
	timeline.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	timeline.value_changed.connect(func(value):clock=value;film.present(clock))
	panel.add_child(timeline)
func _process(delta: float) -> void:
	if not paused:
		clock=minf(clock+delta,Film.DURATION)
		timeline.set_value_no_signal(clock)
		film.present(clock)
		if clock>=Film.DURATION:
			paused=true
			pause_button.text="Reprendre"
