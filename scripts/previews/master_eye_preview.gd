extends Control
## Isolated visual laboratory: no game loop, no save, no gameplay commands.
const Header=preload("res://scripts/game/ui/hud_master_header.gd")
const Session=preload("res://scripts/game/game_session.gd")
const UI=preload("res://scripts/game/ui/hud_theme.gd")
const MODES=["veille","observe","traque","jubile","blesse","fauche","colere"]
const NAMES=["Idle","Observe","Hunt","Glee","Hurt","Broke","Anger"]
var header:Control
var session:IsometricGameSession
var detail:TextureRect
var status:Label
var hint:Label
var controls:VBoxContainer
var options:OptionButton
var hp:OptionButton
var pause:Button
var target:Label
var clock:=0.0
var choice:=0

func _ready() -> void:
	# This standalone laboratory has no game HUD stretch compensation layer.
	get_window().content_scale_size=Vector2i.ZERO
	theme=UI.create()
	var background:=ColorRect.new(); add_child(background); background.color=Color("101622")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.mouse_filter=MOUSE_FILTER_IGNORE
	session=Session.new(); session.persistence_enabled=false; add_child(session); session.set_process(false)
	session.restart(true); session.selected=Vector2i(-1,-1); session.sim.gold=225
	header=Header.new(); add_child(header); header.refresh(session)
	detail=TextureRect.new(); add_child(detail); detail.texture=header.eye.texture; detail.material=header.eye_material
	detail.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; detail.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail.mouse_filter=MOUSE_FILTER_IGNORE
	status=UI.label(self,"",18); status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint=UI.label(self,"Move your finger or mouse · In Hunt mode, the eye follows the moving target.",13)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	target=UI.label(self,"◆",24,Color("e3b884")); target.mouse_filter=MOUSE_FILTER_IGNORE
	controls=VBoxContainer.new(); add_child(controls)
	var row:=HBoxContainer.new(); controls.add_child(row)
	options=OptionButton.new(); row.add_child(options); options.custom_minimum_size=Vector2(140,48)
	for label in NAMES: options.add_item(label)
	options.item_selected.connect(select_mode)
	UI.button(row,"Replay",func(): select_mode(choice)).custom_minimum_size=Vector2(90,48)
	pause=UI.button(row,"Pause",func(): session.paused=not session.paused; pause.text="Resume" if session.paused else "Pause")
	pause.custom_minimum_size=Vector2(96,48)
	var health_row:=HBoxContainer.new(); controls.add_child(health_row)
	var label:=UI.label(health_row,"Core health",14); label.size_flags_horizontal=SIZE_EXPAND_FILL
	hp=OptionButton.new(); health_row.add_child(hp); hp.custom_minimum_size=Vector2(140,48)
	for value in [100,60,20,0]: hp.add_item(str(value)+" %",value)
	hp.item_selected.connect(func(index): session.sim.core_hp=hp.get_item_id(index); header.behavior.reset(); header.refresh(session))
	header.menu_requested.connect(func(): pause.pressed.emit())
	resized.connect(fit); fit(); select_mode(0)

func fit() -> void:
	if not is_instance_valid(controls): return
	header.size=Vector2(minf(size.x-12,760),84 if size.y<352 else 96)
	header.position=Vector2((size.x-header.size.x)/2,4)
	var available:=maxf(44,size.y-header.size.y-172)
	var extent:=minf(260,available)
	detail.size=Vector2(extent*230/192,extent)
	detail.position=Vector2((size.x-detail.size.x)/2,header.size.y+8)
	status.position=Vector2(6,size.y-168); status.size=Vector2(size.x-12,26)
	hint.position=Vector2(8,size.y-142); hint.size=Vector2(size.x-16,36)
	controls.position=Vector2((size.x-minf(380,size.x-12))/2,size.y-104); controls.size=Vector2(minf(380,size.x-12),100)
	options.custom_minimum_size.x=120 if size.x<360 else 140
	pause.custom_minimum_size.x=82 if size.x<360 else 96

func select_mode(index:int) -> void:
	choice=index; options.select(index); session.paused=false; pause.text="Pause"
	header.behavior.reset(); header.clear_pointer()
	session.raid.hero={"pos":Vector2i(8,8)} if index==2 else {}
	session.raid.raid_active=index==2; session.catalog_open=index==1
	header.refresh(session)
	if index>=3: header.behavior.react(MODES[index])

func _process(delta:float) -> void:
	if not is_instance_valid(header): return
	if not session.paused: clock+=delta
	target.position=Vector2(size.x/2+sin(clock*.8)*size.x*.35,header.size.y+maxf(20,(size.y-header.size.y-180)*.75))
	target.visible=choice==2
	header.world_target=target.position+target.size/2 if choice==2 else Vector2(size.x*.24,size.y*.55)
	header.refresh(session,delta)
	status.text=NAMES[MODES.find(header.behavior.mode)]+" · close-up"
