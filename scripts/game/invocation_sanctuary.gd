extends Control
## Procession, incantation, manifestation and kneeling share one explicit clock.
const ENVIRONMENT := preload("res://scenes/game/InvocationSanctuary.tscn")
const TERRAIN_BOUNDS := Rect2(-1800,-2000,3600,4000)
const DISPATCH_BEAT := 8.0
const DURATION := 40.4 + DISPATCH_BEAT
const Actor = preload("res://scripts/game/invocation_actor.gd")
const Master = preload("res://scripts/previews/wraith_master.gd")
const LIGHT = preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const Paths = preload("res://scripts/game/invocation_paths.gd")
const Magic = preload("res://scripts/game/invocation_magic.gd")
const MASTER_HOVER_CENTER := Vector2(-6,-181)
const Passage = preload("res://scripts/game/invocation_passage.gd")
var gate := Passage.new()
var ground_magic := Magic.new()
var air_magic := Magic.new()

var sanctuary: Node2D
var actors: Array[Node2D] = []
var stops: Array[Vector2] = [Vector2(0,235),Vector2(-105,420),Vector2(105,420),Vector2(-105,555),Vector2(105,555)]
var navigation = Paths.new()
var departure_navigation=Paths.new(true)
var departure_route:=PackedVector2Array()
var return_lengths: Array[float] = []
var routes: Array[PackedVector2Array] = []
var seconds := 0.0
var kneel_progress := 0.0
var master_view := SubViewport.new()
var master: Node3D
var master_root := Node2D.new()
var master_sprite := Sprite2D.new()
var ritual_light := Sprite2D.new()
var starts: Array[Vector2] = []
var camera_focus:=Vector2.ZERO
var camera_scale:=1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sanctuary = ENVIRONMENT.instantiate()
	add_child(sanctuary)
	for i in 5:
		var actor := Actor.new()
		actor.is_invoker = i == 0
		actor.scale = Vector2.ONE * (.95 if i == 0 else .9)
		sanctuary.add_child(actor)
		actors.append(actor)
	ritual_light.texture = LIGHT
	ritual_light.position = Magic.CENTER
	ritual_light.scale = Vector2(430,190)/Vector2(LIGHT.get_size())
	sanctuary.add_child(ritual_light)
	_setup_master()
	sanctuary.add_child(ground_magic)
	air_magic.aerial=true
	sanctuary.add_child(air_magic)
	sanctuary.add_child(gate)
	gate.bind_wall(sanctuary.get_node("Paroi4"))
	departure_route=departure_navigation.route(stops[0],Passage.GATE_CENTER)
	for stone_name in ["Menhir3","Menhir4","Menhir5","Menhir6","Menhir1","Menhir2"]:
		var stone: Sprite2D=sanctuary.get_node(stone_name)
		var crystal: Vector2 = stone.get_meta("crystal")
		air_magic.stones.append(stone.position + crystal)
	resized.connect(_fit)
	_fit()
	present(0.0)

func _fit() -> void:
	if not is_instance_valid(sanctuary) or size.x < 1. or size.y < 1.: return
	var focus := Vector2(0,100)
	var fit := minf(size.x/1440.,size.y/1130.)
	if size.y > size.x:
		focus = Vector2(-12,88)
		fit = size.x/660.
	var margin := (focus-TERRAIN_BOUNDS.position).min(TERRAIN_BOUNDS.end-focus)
	var cover := maxf(size.x/(2.*margin.x),size.y/(2.*margin.y))
	sanctuary.scale = Vector2.ONE*maxf(fit,cover)
	sanctuary.position = size*.5-focus*sanctuary.scale
	camera_focus=focus
	camera_scale=sanctuary.scale.x
	starts.clear()
	routes.clear()
	return_lengths.clear()
	var bottom := (size.y-sanctuary.position.y)/sanctuary.scale.y
	for i in 5:
		var spawn := Vector2(stops[i].x,bottom+260+i*48)
		if i >= 3: spawn.y=maxf(spawn.y,starts[i-2].y+160.0)
		starts.append(navigation.spawn_below(spawn))
		var route: PackedVector2Array = navigation.route(starts[i],stops[i])
		routes.append(route)
		var length := 0.0
		for j in range(1,route.size()):
			length += route[j-1].distance_to(route[j])
		return_lengths.append(length)
	var was_visible := visible
	# A hidden film may lend its viewport to the dungeon arrival shot.
	# Resizing must not reset that shot's model pose or disable its renderer.
	if was_visible: present(seconds)

func present(time: float) -> void:
	seconds = clampf(time,0.0,DURATION)
	if starts.size() != 5: return
	for i in 5:
		var delay := i*.38
		var progress := clampf((seconds-delay)/(9.5-delay),0.0,1.0)
		# Constant speed through most of the approach, easing only to a stop.
		var end_phase := clampf((progress-.85)/.15,0.0,1.0)
		var travel := progress if progress < .85 else .85+.15*(end_phase+end_phase*end_phase-end_phase*end_phase*end_phase)
		actors[i].position = Paths.sample(routes[i],travel)
		var mode := "idle"
		var frame := 0
		if progress > 0.0 and progress < 1.0:
			mode = "walk"
			frame = int((seconds-delay)*24.0) % 24
		elif seconds >= 10.0 and seconds < 20.0:
			mode = "chant"
			frame = int((seconds-10.0)*24.0) % 48
		elif seconds >= 22.0 + i*.12:
			mode = "bow" if i == 0 else "kneel"
			frame = clampi(int((seconds-22.0-i*.12)*24.0),0,31)
		actors[i].visible = true
		actors[i].present(mode,frame)
		if i > 0:
			_present_messenger(i)
		_sort_at(actors[i],actors[i].position.y)
	kneel_progress = clampf((seconds-22.48)/(31.0/24.0),0.0,1.0)
	var manifestation := smoothstep(20.0,22.0,seconds)
	master_sprite.visible = seconds > 20.0
	master_sprite.modulate.a = manifestation
	master_sprite.scale = Vector2.ONE*(.35+.65*manifestation)*1.10
	# Form inside the light burst before rising to the final hovering position.
	master_sprite.position = Magic.MANIFESTATION_CENTER.lerp(MASTER_HOVER_CENTER,smoothstep(20.6,22.0,seconds))-master_root.position
	# Hold the passage choreography while the invoker addresses the survivors.
	var passage_time := seconds - clampf(seconds-24.,0.,DISPATCH_BEAT)
	var contraction:=smoothstep(26.8,28.8,passage_time)
	master_sprite.scale*=lerpf(1.,.42/1.10,contraction)
	var travel_ground: Vector2=gate.master_ground(passage_time)
	if passage_time>26.8:
		master_sprite.position=travel_ground-master_root.position+Vector2(0,lerpf(-235.,-76.,contraction))
	master_sprite.modulate.a*=1.-smoothstep(33.55,34.,passage_time)
	master.rotation.y=PI*smoothstep(24.5,26.2,passage_time)-.65*smoothstep(30.4,31.4,passage_time)
	master_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if master_sprite.visible else SubViewport.UPDATE_DISABLED
	if master_sprite.visible: master.present(fposmod(seconds-20.0,6.0))
	ritual_light.modulate = Color(.62,.23,1.0,(.16*smoothstep(11.0,20.0,passage_time)+.2*manifestation))
	_sort_at(ritual_light,55.0)
	ground_magic.present(seconds)
	air_magic.present(seconds)
	_sort_at(ground_magic,54.6)
	_sort_at(master_root,travel_ground.y if passage_time>28.8 else 55.)
	# Its ground anchor moves behind the altar before the hovering body clears it.
	# Keep the flying sprite above the altar until their screen bounds separate.
	var altar: Sprite2D=sanctuary.get_node("Dalle")
	var master_bounds:=Rect2(master_root.position+master_sprite.position-Vector2(256,256)*master_sprite.scale,Vector2(512,512)*master_sprite.scale)
	var altar_bounds: Rect2=altar.get_rect()
	altar_bounds.position+=altar.position
	if master_bounds.intersects(altar_bounds) and master_root.get_index()<altar.get_index():
		sanctuary.move_child(master_root,altar.get_index())
	if passage_time>=31. and master_root.get_index()<gate.stairs.get_index():
		sanctuary.move_child(master_root,gate.stairs.get_index())
	_sort_at(air_magic,190.0)
	gate.source=master_root.position+master_sprite.position
	gate.present(passage_time)
	_sort_at(gate,54.8)
	gate.mask_master(master_sprite,master_root.position,passage_time)
	_present_invoker_departure(passage_time)
	var group_focus := camera_focus.lerp(Vector2(0,260),smoothstep(24.2,26.5,seconds))
	var pan:=smoothstep(24.5,29.5,passage_time)
	var zoom:=lerpf(1.,1.18,pan) if size.x>size.y else 1.
	sanctuary.scale=Vector2.ONE*camera_scale*zoom
	sanctuary.position=size*.5-group_focus.lerp(Vector2(70,-220),pan)*camera_scale*zoom
	show()

func _present_messenger(index: int) -> void:
	var actor := actors[index]
	# The two nearest the exit move first, leaving room for the front pair.
	var rise := 29.3 + float([0.62,0.78,0.0,0.16][index-1])
	if seconds < rise: return
	var elapsed := seconds-rise
	if elapsed < .65:
		actor.present("kneel",roundi(31.*(1.-smoothstep(0.,.65,elapsed))))
		return
	if elapsed < 1.1:
		actor.present_messenger("turn",roundi(8.*(elapsed-.65)/.45))
		return
	var running := elapsed-1.1
	# Accelerate out of the pivot. Reverse the already cleared approach route.
	var distance := 235.*(running - .14*(1.-exp(-running/.14)))
	var route := routes[index]
	var length := return_lengths[index]
	if distance >= length:
		actor.position = starts[index]
		actor.hide()
		return
	actor.position = Paths.sample(route,1.-distance/length)
	var ahead := Paths.sample(route,1.-(distance+4.)/length)
	var facing := Actor.direction_for(ahead-actor.position)
	actor.present_messenger("run-"+facing,int(running*24.)%12)

func _present_invoker_departure(passage_time: float) -> void:
	var actor: Node2D=actors[0]
	actor.modulate.a=1.
	actor.sprite.material=null
	actor.shadow.modulate.a=.7
	if seconds < 25.2: return
	if seconds < 26.0:
		actor.present("bow",roundi(31.*(1.-smoothstep(25.2,26.0,seconds))))
		return
	if passage_time < 29.3:
		var turn := smoothstep(26.0,26.7,seconds) * (1.-smoothstep(32.6,33.3,seconds))
		var headings := ["n","nw","w","sw","s"]
		actor.present_direction("idle",0,headings[roundi(turn*4.)])
		return
	var progress:=smoothstep(29.3,35.7,passage_time)
	var cycles: float=Actor.walk_cycles(departure_route,progress,actor.scale.x)
	actor.position=Paths.sample(departure_route,progress)
	var next:=Paths.sample(departure_route,minf(1.,progress+.005))
	var direction: String=Actor.direction_for(next-actor.position)
	if passage_time>=35.7:
		actor.position=gate.master_ground(passage_time-4.7)
		var ground_distance: float=absf(actor.position.x-Passage.GATE_CENTER.x)*sqrt(1.25)
		cycles+=ground_distance/(Actor.stride_pixels("ne")*actor.scale.x)
		direction="ne"
	actor.present_direction("walk",int(cycles*24.)%24,direction)
	_sort_at(actor,actor.position.y)
	if passage_time>=35.7:
		if actor.get_index()<gate.stairs.get_index(): sanctuary.move_child(actor,gate.stairs.get_index())
		gate.mask_invoker(actor,passage_time-4.7)
		actor.shadow.modulate.a=.7*(1.-smoothstep(35.7,36.,passage_time))
		actor.modulate.a=1.-smoothstep(38.25,38.7,passage_time)

func release() -> void:
	master_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	hide()

func _sort_at(node: Node2D, depth: float) -> void:
	# Keep the authored terrain order; insert actors among actual scenery sprites.
	var target := sanctuary.get_child_count()-1
	for child in sanctuary.get_children():
		if child == node or not child is Sprite2D: continue
		if child == ritual_light or str(child.name).contains("Ombre"): continue
		var name_string := str(child.name)
		if not (name_string.begins_with("Menhir") or name_string.begins_with("Paroi") or name_string.begins_with("Eboulis") or name_string.begins_with("RocheApproche") or name_string.begins_with("Crete") or name_string == "Dalle" or name_string.begins_with("Bougies")): continue
		if child.position.y > depth:
			target = child.get_index()
			if node.get_index() < target: target -= 1
			break
	sanctuary.move_child(node,maxi(0,target))

func _setup_master() -> void:
	master_view.own_world_3d = true
	master_view.transparent_bg = true
	master_view.size = Vector2i(512,512)
	master_view.msaa_3d = Viewport.MSAA_2X
	add_child(master_view)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0,0,0,0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b8acd0")
	environment.environment.ambient_light_energy = .7
	master_view.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(-.35,-.4,0)
	key.light_energy = 1.4
	master_view.add_child(key)
	master = Master.new()
	master_view.add_child(master)
	var camera := Camera3D.new()
	master_view.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.4
	camera.position = Vector3(0,1.45,5)
	camera.look_at(Vector3(0,.85,0))
	camera.current = true
	sanctuary.add_child(master_root)
	master_root.position = Vector2(-6,54)
	master_root.add_child(master_sprite)
	master_sprite.texture = master_view.get_texture()
	master_sprite.position = Magic.MANIFESTATION_CENTER-master_root.position
