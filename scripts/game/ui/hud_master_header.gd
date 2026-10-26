extends Control
## One quiet status band; no decorative gauge implies an adjustable value.
signal menu_requested
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
var band: TextureRect
var eye: TextureRect
var phase: Label
var timer: Label
var gold: Label
var health: Label
var coin: TextureRect
var prey: TextureRect
var eye_button: Button
var time_bar: ProgressBar
var gold_bar: ProgressBar
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
	timer=UI.label(self,"",24,Color("dfbf76"))
	gold=UI.label(self,"",24,Color("dfbf76"))
	health=UI.label(self,"",12,Color("debfef"))
	var display_font:=load("res://assets/ui/master/fonts/Cinzel.ttf").duplicate() as FontFile
	display_font.multichannel_signed_distance_field=true
	var bold:=FontVariation.new(); bold.base_font=display_font; bold.variation_opentype={"wght":700.0}
	for label in [timer,gold,health]: label.add_theme_font_override("font",bold)
	coin=UI.picture(self,"coins",24)
	prey=UI.picture(self,"prey",18)
	for label in [phase,timer,gold,health]:
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	time_bar=UI.bar(self,3,true); gold_bar=UI.bar(self,3,true)
	eye_button=Button.new(); add_child(eye_button)
	eye_button.flat=true; eye_button.tooltip_text="Le maître du donjon · Pause / domaine"
	for state in ["normal","hover","pressed"]: eye_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	eye_button.pressed.connect(func(): menu_requested.emit())
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	var w:=size.x
	var short:=size.y<90
	var extent:=64.0 if short else 76.0
	band.position=Vector2(0,8); band.size=Vector2(w,56 if short else 64)
	eye.position=Vector2((w-extent)/2,0); eye.size=Vector2.ONE*extent
	eye_button.position=eye.position; eye_button.size=eye.size
	var side: float=(w-extent)/2-20
	phase.position=Vector2(12,16); phase.size=Vector2(side,14)
	timer.position=Vector2(12,29); timer.size=Vector2(side-22,29)
	prey.position=Vector2(side-6,34); prey.size=Vector2(18,18)
	coin.position=Vector2(w-side-12,31); coin.size=Vector2(24,24)
	gold.position=Vector2(w-side+16,29); gold.size=Vector2(side-28,29)
	health.position=Vector2(w/2-70,65 if short else 77); health.size=Vector2(140,18)
	for gauge in [time_bar,gold_bar]: gauge.size=Vector2(side,3)
	time_bar.position=Vector2(12,55 if short else 62); gold_bar.position=Vector2(w-side-12,55 if short else 62)

func refresh(session: IsometricGameSession, delta: float=0) -> void:
	var raid:=session.raid.raid_active
	var stopped:=session.paused or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked
	var building:=session.catalog_open or session.tool!=Types.Tool.NONE or session.selected.x>=0
	var ready:=session.ready_for_raid()
	var seconds:=int(session.raid.elapsed_seconds) if raid else ceili(session.raid.raid_timer)
	phase.text="PROIES ENTRÉES" if raid else "PROCHAINES PROIES"
	if size.x<340: phase.text="RAID" if raid else "PROIES"
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
