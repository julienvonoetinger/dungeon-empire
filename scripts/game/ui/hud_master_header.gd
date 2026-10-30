extends Control
## Approved stone C header. Wings resize independently of the eye and its ten HP runes.
signal menu_requested
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
const EYE_CENTER := Vector2(204.0/410.0, 167.0/342.0)
const RUNE_RADIUS := Vector2(105.0/410.0, 105.0/342.0)
const COUNTDOWN_ICON = preload("res://assets/ui/master/dark-icons/hourglass.png")
const RAID_ICON = preload("res://assets/ui/master/dark-icons/raid.png")
const COIN_ICON = preload("res://assets/ui/master/dark-icons/coins.png")
var band: Control
var left_wing: NinePatchRect
var right_wing: NinePatchRect
var eye: TextureRect
var phase_description := ""
var timer: Label
var gold: Label
var health: Label
var coin: TextureRect
var timer_icon: TextureRect
var eye_button: Button
var time_bar: ProgressBar
var gold_bar: ProgressBar
var time_socket: Panel
var gold_socket: Panel
const EyeBehavior=preload("res://scripts/game/ui/master_eye_behavior.gd")
var behavior=EyeBehavior.new()
## Viewport coordinates supplied by the world/HUD adapter, not grid coordinates.
var world_target:=Vector2.INF
var _session:IsometricGameSession
var _pointer:=Vector2.INF
var _pointer_age:=99.0
var _touches:Dictionary={}
var _multi_touch:=false
var _focused:=true
var eye_material: ShaderMaterial

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_STOP
	band=Control.new(); add_child(band)
	band.mouse_filter=MOUSE_FILTER_IGNORE
	left_wing=_stone_wing("left"); right_wing=_stone_wing("right")
	eye=TextureRect.new(); add_child(eye)
	eye.texture=load("res://assets/ui/master/header-c-center.png")
	eye.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	eye.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eye.mouse_filter=MOUSE_FILTER_IGNORE
	eye_material=ShaderMaterial.new()
	eye_material.shader=load("res://scripts/game/ui/master_eye.gdshader")
	eye_material.set_shader_parameter("eye_center",EYE_CENTER)
	eye.material=eye_material
	timer=UI.label(self,"",28,Color("e2deeb"))
	gold=UI.label(self,"",28,Color("e2deeb"))
	health=UI.label(self,"",12,Color("d6c8e3"))
	var display_font:=load("res://assets/ui/master/fonts/Grenze.ttf").duplicate() as FontFile
	display_font.multichannel_signed_distance_field=true
	var bold:=FontVariation.new(); bold.base_font=display_font; bold.variation_opentype={"wght":700.0}
	# Lining, tabular figures avoid old-style descending digits and timer jitter.
	bold.opentype_features={"lnum":1,"tnum":1}
	for label in [timer,gold,health]:
		label.add_theme_font_override("font",bold)
		label.add_theme_color_override("font_outline_color",Color("10111c"))
		label.add_theme_constant_override("outline_size",1)
	# The small carved lip already has a dark face: an outline and a drop
	# shadow would extend the percentage beyond its shallow painted interior.
	health.add_theme_constant_override("outline_size",0)
	health.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	coin=UI.picture(self,"coins",24)
	coin.texture=COIN_ICON
	timer_icon=TextureRect.new(); add_child(timer_icon)
	timer_icon.texture=COUNTDOWN_ICON
	timer_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	timer_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	timer_icon.mouse_filter=MOUSE_FILTER_IGNORE
	for label in [timer,gold,health]:
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
	get_window().size_changed.connect(clear_pointer)
	_layout()

func _stone_wing(side: String) -> NinePatchRect:
	var wing:=NinePatchRect.new(); band.add_child(wing)
	wing.texture=load("res://assets/ui/master/header-c-"+side+".png")
	wing.patch_margin_left=40; wing.patch_margin_right=40
	wing.mouse_filter=MOUSE_FILTER_IGNORE
	return wing

func rune_sample_uv(index: int) -> Vector2:
	# Source-calibrated centers, clockwise from twelve o'clock.
	var angle:=TAU*index/10.0
	return EYE_CENTER+Vector2(sin(angle),-cos(angle))*RUNE_RADIUS

func _input(event:InputEvent) -> void:
	# Observe only; never mark an event handled or compete with world gestures.
	if event is InputEventScreenTouch:
		if event.pressed: _touches[event.index]=true
		else: _touches.erase(event.index)
		if _touches.size()>1: _multi_touch=true; _pointer=Vector2.INF
		if not _multi_touch and not event.canceled: _pointer=event.position; _pointer_age=0
		if event.canceled: _pointer=Vector2.INF
		if _touches.is_empty(): _multi_touch=false
	elif event is InputEventScreenDrag and _touches.size()==1 and not _multi_touch:
		_pointer=event.position; _pointer_age=0
	elif (event is InputEventMouseMotion or event is InputEventMouseButton) and event.device!=-1 and _touches.is_empty() and not _multi_touch:
		_pointer=event.position; _pointer_age=0

func clear_pointer() -> void:
	_pointer=Vector2.INF; _pointer_age=99; _touches.clear(); _multi_touch=false

func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED: _focused=false; clear_pointer()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN or what==NOTIFICATION_APPLICATION_RESUMED: _focused=true

func _eye_feedback(kind:String) -> void:
	if kind=="reset": behavior.reset(); clear_pointer(); world_target=Vector2.INF
	else: behavior.react(kind)

func _refresh_eye(session:IsometricGameSession,delta:float) -> void:
	if _session!=session:
		if is_instance_valid(_session): _session.presentation_event.disconnect(_eye_feedback)
		_session=session; session.presentation_event.connect(_eye_feedback); behavior.reset()
	behavior.observe(session)
	var frozen:=session.paused or session.confirmation_open or session.save_blocked or not _focused
	if not frozen and _touches.is_empty(): _pointer_age+=delta
	var tracking:=session.raid.raid_active and not session.raid.hero.is_empty()
	var observing:=session.selected.x>=0 or session.catalog_open or session.tool!=Types.Tool.NONE
	var base:="traque" if tracking else ("observe" if observing else "veille")
	var point:=Vector2.INF
	if tracking: point=world_target
	elif _pointer_age<2 and _pointer.is_finite(): point=_pointer
	elif observing: point=world_target
	if behavior.reaction=="fauche": point=coin.get_global_transform_with_canvas()*(coin.size/2)
	var target:=Vector2.ZERO
	if point.is_finite() and not session.sim.game_over:
		var local:=get_global_transform_with_canvas().affine_inverse()*point
		var center:=eye.position+EYE_CENTER*eye.size
		# Normalize relative to the usable screen, so a portrait tap still reads.
		var span:=get_viewport_rect().size/get_global_transform_with_canvas().get_scale().abs()
		target=Vector2((local.x-center.x)/maxf(90,span.x*.35),(local.y-center.y)/maxf(100,span.y*.55)).limit_length(1)
	behavior.step(delta,base,target,frozen,session.sim.game_over)
	behavior.apply(eye_material)

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
	var gauge:=UI.bar(socket,3)
	gauge.add_theme_stylebox_override("background",UI.flat(Color("080b12"),0))
	# Avoid the thin rounded/AA border path implicated by the Android report.
	# A plain borderless fill stays inside the existing rounded rail.
	var fill:=UI.flat(Color("b66af2"),0)
	fill.anti_aliasing=false
	gauge.add_theme_stylebox_override("fill",fill)
	gauge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gauge.offset_left=2; gauge.offset_right=-2; gauge.offset_top=2; gauge.offset_bottom=-2
	return gauge

func _value_group(label: Label, glyph: TextureRect, lane: Rect2, font_size: int) -> void:
	var font:=label.get_theme_font("font")
	var extent:=22.0 if size.x<400 else 26.0
	var gap:=4.0 if size.x<400 else 6.0
	# Measure the actual text instead of centering it in an unrelated wide box.
	while font_size>14 and (font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>lane.size.x-extent-gap or font.get_height(font_size)>lane.size.y):
		font_size-=1
	label.add_theme_font_size_override("font_size",font_size)
	var width:=minf(ceilf(font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)+2,lane.size.x-extent-gap)
	var height:=ceilf(font.get_height(font_size))
	var start:=lane.get_center().x-(extent+gap+width)/2
	glyph.custom_minimum_size=Vector2.ONE*extent
	glyph.position=Vector2(start,lane.get_center().y-extent/2); glyph.size=Vector2.ONE*extent
	# Grenze's lining numerals sit below its tall ascender-centered line box.
	# Keep the visible figures level with the icon and the painted face midpoint.
	var ink_offset:=-roundf(font_size*.11)
	label.position=Vector2(start+extent+gap,lane.get_center().y-height/2+ink_offset); label.size=Vector2(width,height)

func _layout() -> void:
	if not is_instance_valid(eye_button) or size.x<=0 or size.y<=0: return
	var w:=size.x
	var short:=size.y<90
	var art_scale:=size.y/192.0
	var extent:=eye.texture.get_width()*art_scale
	band.position=Vector2.ZERO; band.size=size
	var wing_width:=(w-extent)/2.0
	for wing in [left_wing,right_wing]:
		wing.scale=Vector2.ONE*art_scale
		wing.size=Vector2(wing_width/art_scale,192)
	left_wing.position=Vector2.ZERO
	right_wing.position=Vector2(wing_width+extent,0)
	eye.position=Vector2(wing_width,0); eye.size=Vector2(extent,size.y)
	eye_button.position=eye.position; eye_button.size=eye.size
	var padding:=12.0 if w<400 else 18.0
	var side:=wing_width-2*padding
	var right:=w-padding-side
	# Center inside the painted stone face, between the upper fissure (source
	# y=84) and the gauge groove (y=230), not inside the whole header rectangle.
	# All three art slices share the same 342px-high source crop.
	var value_y:=size.y*84.0/342.0
	var value_height:=size.y*(230.0-84.0)/342.0
	_value_group(timer,timer_icon,Rect2(padding,value_y,side,value_height),24 if short else 28)
	_value_group(gold,coin,Rect2(right,value_y,side,value_height),24 if short else 28)
	# The percentage belongs to the carved lip, not an extra bordered panel.
	health.add_theme_font_size_override("font_size",10 if short else 12)
	var health_height:=ceilf(health.get_theme_font("font").get_height(health.get_theme_font_size("font_size")))
	# Rectangle inside the bevels of the prepared230x192 central stone slice.
	# Position the glyphs here, rather than against the unrelated header bottom.
	var health_lip:=Rect2(eye.position+Vector2(76,166)*art_scale,Vector2(78,18)*art_scale)
	var health_ink_offset:=0.0 if short else -1.0
	health.position=Vector2(health_lip.position.x,health_lip.get_center().y-health_height/2+health_ink_offset)
	health.size=Vector2(health_lip.size.x,health_height)
	# Cover the empty painted trough at y=230..260 of the shared 342px crop.
	# Native rails stay inside the masonry, with a clipped borderless fill.
	for socket in [time_socket,gold_socket]: socket.size=Vector2(side,8)
	time_socket.position=Vector2(padding,size.y*.68)
	gold_socket.position=Vector2(right,time_socket.position.y)

func refresh(session: IsometricGameSession, delta: float=0) -> void:
	var old_timer:=timer.text
	var old_gold:=gold.text
	var raid:=session.raid.raid_active
	var stopped:=session.paused or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked
	var building:=session.catalog_open or session.tool!=Types.Tool.NONE or session.selected.x>=0
	var ready:=session.ready_for_raid()
	var seconds:=int(session.raid.elapsed_seconds) if raid else ceili(session.raid.raid_timer)
	phase_description="Raid en cours" if raid else "Prochain raid"
	if stopped: phase_description="Pause"
	elif building and not raid: phase_description="Construction · compte à rebours suspendu"
	if not raid and not ready:
		phase_description="Cœur requis" if not session.sim._has_core() else "Entrée requise" if not session.sim._has_entrance() else "Stockage requis"
	if session.result_open: phase_description="Raid terminé"
	if session.sim.game_over: phase_description="Cœur détruit"
	timer_icon.texture=RAID_ICON if raid else COUNTDOWN_ICON
	timer_icon.modulate=Color(.65,.65,.65) if stopped or building else Color.WHITE
	timer.text="%02d:%02d" % [seconds/60,seconds%60] if raid or ready else "—:—"
	gold.text=str(session.sim.gold)
	health.text="%d %%" % session.sim.core_hp
	health.tooltip_text="Vie du cœur · "+health.text
	time_bar.value=100*clampf(session.raid.raid_timer/Types.RAID_DELAY,0,1) if not raid else 100
	time_bar.modulate=Color(.65,.65,.65) if stopped or building else Color.WHITE
	var capacity:=session.sim._vault_positions().size()*Types.VAULT_CAPACITY
	gold_bar.value=100*clampf(float(session.sim.gold)/maxi(capacity,1),0,1)
	gold_bar.tooltip_text="Or disponible / capacité de stockage"
	_refresh_eye(session,delta)
	eye_material.set_shader_parameter("life",float(session.sim.core_hp)/100)
	tooltip_text=phase_description+" · "+timer.text+" · "+str(session.sim.gold)+" or"
	if timer.text!=old_timer or gold.text!=old_gold: _layout()
