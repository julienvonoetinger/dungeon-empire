extends Node2D
## Dedicated no-save mobile animation viewer. Never instantiates a game session.
const ROOM=preload("res://scripts/wireframe_cell_study.gd")
const LAYOUT=preload("res://assets/layouts/study_5x5.tres")
const STATES=["idle","walk","run","hurt","lock-door","lock-chest","loot","dead"]
const LABELS=["Attente","Marche","Course","Dégâts","Crochetage porte","Crochetage coffre","Ramassage","Mort"]
const PROFILES=["balanced","compact","reference"]
const DIRS=["se","sw","nw","ne"]
const MOTION=[Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]
var room: Node2D
var camera: Camera2D
var actors: Array[AnimatedSprite2D]=[]
var controls: Array[Control]=[]
var ui: Control
var panel: Panel
var title: Label
var info: Label
var action_select: OptionButton
var profile_select: OptionButton
var pause_button: Button
var replay_button: Button
var slow_button: Button
var detail_button: Button
var world_rect:=Rect2()
var data: Dictionary
var state: String="walk"
var profile: String="balanced"
var elapsed:=0.0
var paused:=false
var slow:=false
var detail:=false
var ui_scale:=1.0
var pan:=Vector2.ZERO
var dragging:=false
var touch_id:=-1
var ready_for_test:=false

func _ready() -> void:
	room=ROOM.new();room.layout=LAYOUT;room.wall_variants=true;room.floor_variants=true;add_child(room)
	camera=Camera2D.new();add_child(camera)
	for d in DIRS:
		var a:=AnimatedSprite2D.new();a.name=d;a.centered=false;a.z_index=20;add_child(a);actors.append(a)
	var canvas:=CanvasLayer.new();add_child(canvas);ui=Control.new();ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(ui)
	panel=Panel.new();ui.add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color("172133");style.border_color=Color("796392");style.set_border_width_all(1);style.set_corner_radius_all(8);panel.add_theme_stylebox_override("panel",style)
	title=Label.new();title.text="Vulpin · Sprites peints";title.add_theme_font_size_override("font_size",19);panel.add_child(title)
	action_select=OptionButton.new();for label in LABELS:action_select.add_item(label)
	action_select.select(1);action_select.item_selected.connect(func(i):set_action(STATES[i]));panel.add_child(action_select)
	profile_select=OptionButton.new();for label in ["128 · Équilibré","96 · Léger","160 · Référence"]:profile_select.add_item(label)
	profile_select.item_selected.connect(func(i):set_profile(PROFILES[i]));panel.add_child(profile_select)
	pause_button=make_button("Pause",func():paused=not paused;pause_button.text="Lire" if paused else "Pause")
	replay_button=make_button("Rejouer",func():elapsed=0)
	slow_button=make_button("0,5×",func():slow=not slow;slow_button.button_pressed=slow);slow_button.toggle_mode=true
	detail_button=make_button("Détail ×2",func():detail=not detail;detail_button.button_pressed=detail;layout_ui());detail_button.toggle_mode=true
	info=Label.new();info.add_theme_font_size_override("font_size",13);info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;panel.add_child(info)
	controls.assign([action_select,profile_select,pause_button,replay_button,slow_button,detail_button])
	for control in controls:
		control.add_theme_font_size_override("font_size",16)
		var box:=StyleBoxFlat.new();box.bg_color=Color("29354a");box.border_color=Color("53627c");box.set_border_width_all(1);box.set_corner_radius_all(6);box.content_margin_left=12;box.content_margin_right=12;box.content_margin_top=8;box.content_margin_bottom=8
		control.add_theme_stylebox_override("normal",box)
		var active=box.duplicate();active.bg_color=Color("4a365e");active.border_color=Color("b998e0");control.add_theme_stylebox_override("pressed",active);control.add_theme_stylebox_override("hover",active)
	get_viewport().size_changed.connect(layout_ui)
	set_profile("balanced");layout_ui();ready_for_test=true

func make_button(label: String,callback: Callable) -> Button:
	var button:=Button.new();button.text=label;button.pressed.connect(callback);panel.add_child(button);return button

func set_profile(value: String) -> void:
	profile=value;profile_select.select(PROFILES.find(profile))
	var base: String="res://assets/vulpin-review/"+profile+"/"
	data=JSON.parse_string(FileAccess.get_file_as_string(base+"manifest.json"))
	var pages: Array[Texture2D]=[]
	for page in data.pages:pages.append(load(base+page.file))
	var frames:=SpriteFrames.new();frames.remove_animation("default");var parts: Dictionary={}
	for id in data.sprites:
		var s: Dictionary=data.sprites[id];var part:=AtlasTexture.new();part.atlas=pages[s.page]
		part.region=Rect2(s.rect[0],s.rect[1],s.rect[2],s.rect[3]);part.margin=Rect2(s.crop[0],s.crop[1],data.canvas-s.crop[2],data.canvas-s.crop[3]);part.filter_clip=true;parts[id]=part
	for name in data.clips:
		var clip: Dictionary=data.clips[name];frames.add_animation(name);frames.set_animation_loop(name,clip.loop);frames.set_animation_speed(name,clip.frames.size()/float(clip.seconds))
		for frame in clip.frames:frames.add_frame(name,parts[frame.sprite])
	for a in actors:a.sprite_frames=frames;a.offset=-Vector2(data.root[0],data.root[1]);a.scale=Vector2.ONE/float(data.scale)
	set_action(state)

func set_action(value: String) -> void:
	state=value;elapsed=0;action_select.select(STATES.find(state))
	for i in actors.size():actors[i].animation=DIRS[i]+"-"+state
	info.text="%s · %d images/vue · %.2f s\nPrototype peint · Glisser pour déplacer"%[str(int(data.density)),data.clips["se-"+state].frames.size(),data.clips["se-"+state].seconds]
	if state=="dead":info.text="%s · 1 sprite fixe par vue\nPrototype peint · Glisser pour déplacer"%str(int(data.density))
	_update_actors()

func _process(delta: float) -> void:
	if not ready_for_test:return
	if not paused:elapsed+=minf(delta,.1)*(.5 if slow else 1.0)
	_update_actors()

func _update_actors() -> void:
	var c: Dictionary=data.clips["se-"+state]
	# Four short in-place lanes show displacement matched to each stride. The
	# demonstration restarts after four cycles; this does not modify game speed.
	var time:=fmod(elapsed,c.seconds*4) if c.loop else minf(elapsed,c.seconds)
	var stride:=float(c.get("strideCells",0.0))
	for i in actors.size():
		var location: Vector2=room.grid_to_local(Vector2(2.5,2.5))+Vector2((-1 if i%2==0 else 1)*115,(-1 if i<2 else 1)*100)
		var at: Vector2=room.local_to_grid(location)+MOTION[i]*stride*(time/c.seconds-2)
		actors[i].position=room.grid_to_local(at)
		var phase: float=fmod(time,c.seconds)/c.seconds if c.loop else minf(time/c.seconds,.999999)
		actors[i].frame=mini(c.frames.size()-1,floori(phase*c.frames.size()))

func layout_ui() -> void:
	if not is_instance_valid(ui):return
	var size:=get_viewport_rect().size
	ui_scale=maxf(1,DisplayServer.screen_get_dpi()/160.0) if OS.has_feature("android") else 1.0
	ui.scale=Vector2.ONE*ui_scale;ui.size=size/ui_scale
	var safe:=Rect2(Vector2.ZERO,size)
	if OS.has_feature("android"):
		var reported:=Rect2(DisplayServer.get_display_safe_area())
		if reported.has_area():safe=safe.intersection(reported)
	var rect:=Rect2(safe.position/ui_scale,safe.size/ui_scale);var wide:=rect.size.x>rect.size.y
	var box:=Rect2(rect.position+Vector2(12,rect.size.y-334),Vector2(rect.size.x-24,322))
	if wide:box=Rect2(rect.position+Vector2(rect.size.x-292,12),Vector2(280,rect.size.y-24))
	panel.position=box.position;panel.size=box.size
	title.position=Vector2(12,8);title.size=Vector2(box.size.x-24,28)
	if wide:
		var tight:=rect.size.y<360
		action_select.position=Vector2(12,36 if tight else 44);action_select.size=Vector2(box.size.x-24,48)
		profile_select.position=Vector2(12,88 if tight else 100);profile_select.size=Vector2(box.size.x-24,48)
		for i in 4:
			controls[i+2].position=Vector2(12+(i%2)*(box.size.x-16)/2,(140 if tight else 156)+(i/2)*(52 if tight else 56));controls[i+2].size=Vector2((box.size.x-32)/2,48)
		info.position=Vector2(12,246 if tight else 270);info.size=Vector2(box.size.x-24,42)
		world_rect=Rect2(safe.position,Vector2((box.position.x-rect.position.x-12)*ui_scale,safe.size.y))
	else:
		action_select.position=Vector2(12,44);action_select.size=Vector2(box.size.x-24,48)
		profile_select.position=Vector2(12,100);profile_select.size=Vector2(box.size.x-24,48)
		for i in 4:
			controls[i+2].position=Vector2(12+(i%2)*(box.size.x-16)/2,156+(i/2)*56);controls[i+2].size=Vector2((box.size.x-32)/2,48)
		info.position=Vector2(12,270);info.size=Vector2(box.size.x-24,42)
		world_rect=Rect2(safe.position,Vector2(safe.size.x,(box.position.y-rect.position.y-12)*ui_scale))
	# Rotation cancels in-flight gestures, but keeps action, profile and playback.
	dragging=false;touch_id=-1
	var fit:=minf(1,minf(world_rect.size.y/(300*ui_scale),world_rect.size.x/(420*ui_scale)))
	camera.zoom=Vector2.ONE*.75*ui_scale*fit*(2 if detail else 1)
	camera.position=room.grid_to_local(Vector2(2.5,2.5))+Vector2(0,-45)+pan-(world_rect.get_center()-size/2)/camera.zoom
	camera.force_update_scroll()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id<0 and world_rect.has_point(event.position):touch_id=event.index
		elif event.index==touch_id and not event.pressed:touch_id=-1
	elif event is InputEventScreenDrag and event.index==touch_id:
		pan-=event.relative/camera.zoom;camera.position-=event.relative/camera.zoom
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed and world_rect.has_point(event.position)
	elif event is InputEventMouseMotion and dragging:pan-=event.relative/camera.zoom;camera.position-=event.relative/camera.zoom

