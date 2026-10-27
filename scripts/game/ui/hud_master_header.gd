extends Control
## One quiet status band; no decorative gauge implies an adjustable value.
signal menu_requested
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
var band: TextureRect
var eye: TextureRect
var phase: Label
var gold_title: Label
var timer: Label
var gold: Label
var health: Label
var coin: TextureRect
var prey: TextureRect
var eye_button: Button
var time_bar: ProgressBar
var gold_bar: ProgressBar
var time_socket: Panel
var gold_socket: Panel
var health_plate: Panel
var _phase := 0.0
var eye_material: ShaderMaterial

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_STOP
	band=TextureRect.new(); add_child(band)
	band.texture=load("res://assets/ui/master/header.png")
	band.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	band.mouse_filter=MOUSE_FILTER_IGNORE
	eye=TextureRect.new(); add_child(eye)
	eye.texture=load("res://assets/ui/master/eye.png")
	eye.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	eye.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eye.mouse_filter=MOUSE_FILTER_IGNORE
	eye_material=ShaderMaterial.new()
	eye_material.shader=load("res://scripts/game/ui/master_eye.gdshader")
	eye.material=eye_material
	phase=UI.label(self,"",10,UI.MUTED)
	gold_title=UI.label(self,"OR",10,UI.MUTED)
	timer=UI.label(self,"",24,Color("dfbf76"))
	gold=UI.label(self,"",24,Color("dfbf76"))
	health_plate=Panel.new(); add_child(health_plate); health_plate.mouse_filter=MOUSE_FILTER_IGNORE
	var plate:=UI.flat(Color("141723"),4)
	plate.border_color=Color("59526b"); plate.set_border_width_all(1)
	health_plate.add_theme_stylebox_override("panel",plate)
	health=UI.label(self,"",12,Color("debfef"))
	var display_font:=load("res://assets/ui/master/fonts/Cinzel.ttf").duplicate() as FontFile
	display_font.multichannel_signed_distance_field=true
	var bold:=FontVariation.new(); bold.base_font=display_font; bold.variation_opentype={"wght":700.0}
	for label in [timer,gold,health]: label.add_theme_font_override("font",bold)
	coin=UI.picture(self,"coins",24)
	prey=UI.picture(self,"prey",18)
	for label in [phase,gold_title,timer,gold,health]:
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	time_socket=_gauge_socket(); gold_socket=_gauge_socket()
	time_bar=_inset_bar(time_socket); gold_bar=_inset_bar(gold_socket)
	eye_button=Button.new(); add_child(eye_button)
	eye_button.flat=true; eye_button.tooltip_text="Le maître du donjon · Pause / domaine"
	for state in ["normal","hover","pressed"]: eye_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	eye_button.pressed.connect(func(): menu_requested.emit())
	resized.connect(_layout)
	_layout()

func _gauge_socket() -> Panel:
	var socket:=Panel.new(); add_child(socket); socket.mouse_filter=MOUSE_FILTER_IGNORE
	# Keep the child fill inside the rail on mobile rendering backends.
	socket.clip_contents=true
	var trough:=UI.flat(Color("080b12"),3)
	trough.border_color=Color("556073"); trough.set_border_width_all(1)
	trough.shadow_color=Color("080a10"); trough.shadow_size=1
	socket.add_theme_stylebox_override("panel",trough)
	return socket

func _inset_bar(socket: Panel) -> ProgressBar:
	var gauge:=UI.bar(socket,3,true)
	gauge.add_theme_stylebox_override("background",UI.flat(Color("080b12"),0))
	# Avoid the thin rounded/AA border path implicated by the Android report.
	# A plain borderless fill stays inside the existing rounded rail.
	var fill:=UI.flat(UI.GOLD,0)
	fill.anti_aliasing=false
	gauge.add_theme_stylebox_override("fill",fill)
	gauge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gauge.offset_left=2; gauge.offset_right=-2; gauge.offset_top=2; gauge.offset_bottom=-2
	return gauge

func _value_group(label: Label, glyph: TextureRect, lane: Rect2, font_size: int) -> void:
	var font:=label.get_theme_font("font")
	var extent:=20.0
	var gap:=6.0
	# Measure the actual text instead of centering it in an unrelated wide box.
	while font_size>14 and font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>lane.size.x-extent-gap:
		font_size-=1
	label.add_theme_font_size_override("font_size",font_size)
	var width:=minf(ceilf(font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)+2,lane.size.x-extent-gap)
	var height:=ceilf(font.get_height(font_size))
	var start:=lane.get_center().x-(extent+gap+width)/2
	glyph.custom_minimum_size=Vector2.ONE*extent
	glyph.position=Vector2(start,lane.get_center().y-extent/2); glyph.size=Vector2.ONE*extent
	label.position=Vector2(start+extent+gap,lane.get_center().y-height/2); label.size=Vector2(width,height)

func _layout() -> void:
	if not is_instance_valid(eye_button): return
	var w:=size.x
	var short:=size.y<90
	var extent:=72.0 if short else 84.0
	band.position=Vector2(0,4 if short else 8); band.size=Vector2(w,80 if short else 88)
	eye.position=Vector2((w-extent)/2,0); eye.size=Vector2.ONE*extent
	eye_button.position=eye.position; eye_button.size=eye.size
	var side: float=(w-extent)/2-28
	var right:=w-18-side
	phase.position=Vector2(18,16 if short else 23); phase.size=Vector2(side,14)
	var caption_size:=10
	while caption_size>8 and phase.get_theme_font("font").get_string_size(phase.text,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size).x>side:
		caption_size-=1
	phase.add_theme_font_size_override("font_size",caption_size)
	gold_title.position=Vector2(right,phase.position.y); gold_title.size=phase.size
	var value_y:=29.0 if short else 36.0
	var value_height:=27.0 if short else 29.0
	_value_group(timer,prey,Rect2(18,value_y,side,value_height),20 if short else 22)
	_value_group(gold,coin,Rect2(right,value_y,side,value_height),20 if short else 22)
	health_plate.position=Vector2(w/2-51,size.y-20); health_plate.size=Vector2(102,20)
	health.position=health_plate.position+Vector2(4,1); health.size=health_plate.size-Vector2(8,2)
	# The painted lower iron rail occupies y=90..108 of the 135px source.
	# Both troughs sit inside that rail, with their fill inset on all sides.
	for socket in [time_socket,gold_socket]: socket.size=Vector2(side,7)
	time_socket.position=Vector2(18,59 if short else 68)
	gold_socket.position=Vector2(right,time_socket.position.y)

func refresh(session: IsometricGameSession, delta: float=0) -> void:
	var old_phase:=phase.text
	var old_timer:=timer.text
	var old_gold:=gold.text
	var raid:=session.raid.raid_active
	var stopped:=session.paused or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked
	var building:=session.catalog_open or session.tool!=Types.Tool.NONE or session.selected.x>=0
	var ready:=session.ready_for_raid()
	var seconds:=int(session.raid.elapsed_seconds) if raid else ceili(session.raid.raid_timer)
	phase.text="PROIES ENTRÉES" if raid else "PROCHAINES PROIES"
	if size.x<400: phase.text="RAID" if raid else "PROIES"
	if stopped: phase.text="PAUSE"
	elif building and not raid: phase.text="CONSTRUCTION"
	if not raid and not ready:
		phase.text="CŒUR REQUIS" if not session.sim._has_core() else "ENTRÉE REQUISE" if not session.sim._has_entrance() else "STOCKAGE REQUIS"
	if session.result_open: phase.text="RAID TERMINÉ"
	if session.sim.game_over: phase.text="CŒUR DÉTRUIT"
	timer.text="%02d:%02d" % [seconds/60,seconds%60] if raid or ready else "—:—"
	gold.text=str(session.sim.gold)
	health.text="CŒUR · %d %%" % session.sim.core_hp
	time_bar.value=100*clampf(session.raid.raid_timer/Types.RAID_DELAY,0,1) if not raid else 100
	time_bar.modulate=Color(.65,.65,.65) if stopped or building else Color.WHITE
	var capacity:=session.sim._vault_positions().size()*Types.VAULT_CAPACITY
	gold_bar.value=100*clampf(float(session.sim.gold)/maxi(capacity,1),0,1)
	gold_bar.tooltip_text="Or disponible / capacité de stockage"
	if not stopped: _phase=fmod(_phase+delta*.12,TAU)
	eye_material.set_shader_parameter("phase",_phase)
	eye_material.set_shader_parameter("life",float(session.sim.core_hp)/100)
	tooltip_text=phase.text+" · "+timer.text+" · "+str(session.sim.gold)+" or"
	if phase.text!=old_phase or timer.text!=old_timer or gold.text!=old_gold: _layout()
