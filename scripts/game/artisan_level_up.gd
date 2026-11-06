extends Control
## One pulse from the Core, sampled from the tutorial clock (also when seeking).
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const LIGHT := preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const DURATION := 2.8
var card := PanelContainer.new()
var title: Label
var detail: Label
var origin := Vector2.ZERO
var progress := 0.
var unit := 1.
var safe := Rect2()
var locate_core: Callable

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UI.surface("panel",12))
	add_child(card)
	var column := VBoxContainer.new()
	card.add_child(column)
	title = UI.label(column,"",28,UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail = UI.label(column,"",16,UI.TEXT)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hide()

func present(seconds: float, ui_unit: float, safe_area: Rect2, new_level: int, ability: String) -> void:
	visible = seconds >= 0. and seconds < DURATION
	if not visible: return
	title.text = "Niveau %d" % new_level
	detail.text = ability
	unit = ui_unit
	progress = seconds / DURATION
	safe = Rect2(safe_area.position*unit,safe_area.size*unit)
	_position_card()
	card.modulate.a = smoothstep(0.,.12,progress) * (1.-smoothstep(.80,1.,progress))
	queue_redraw()

func _process(_delta: float) -> void:
	# The world viewport can finish resizing even when the tutorial clock is paused.
	if is_visible_in_tree() and not origin.is_equal_approx(locate_core.call()):
		_position_card()
		queue_redraw()

func _position_card() -> void:
	origin = locate_core.call()
	card.scale = Vector2.ONE * unit
	card.reset_size()
	var extent := card.size * unit
	var at := origin - Vector2(extent.x*.5,extent.y+(20.+22.*smoothstep(0.,.4,progress))*unit)
	card.position = at.clamp(safe.position,(safe.end-extent).max(safe.position))

func _draw() -> void:
	draw_set_transform(origin,0.,Vector2.ONE*unit)
	var glow := sin(PI*sqrt(progress))
	var radius := lerpf(9.,68.,smoothstep(0.,1.,progress))
	var extent := Vector2.ONE * (65.+radius)
	draw_texture_rect(LIGHT,Rect2(-extent*.5,extent),false,Color(UI.ACCENT,glow*.95))
	draw_arc(Vector2.ZERO,radius,0.,TAU,72,Color(UI.ACCENT,glow*.8),2.,true)
	draw_arc(Vector2.ZERO,radius*.82,0.,TAU,72,Color(UI.GOLD,glow*.6),1.,true)
	for i in 12:
		var ray := Vector2.from_angle(TAU*i/12.+.14)
		var spark := ray*(radius+5.+6.*sin(i*2.4))
		draw_line(spark,spark+ray*glow*7.,Color(UI.GOLD,glow),1.7,true)
