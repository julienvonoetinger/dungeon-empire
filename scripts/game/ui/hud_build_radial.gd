extends Control
## Joint sectors have the same geometry in both orientations. World input is
## captured by HUD while open; the opening release cannot also activate a wedge.
signal tool_chosen(tool: int)
signal catalogue_requested(category: int)
signal closed
const UI=preload("res://scripts/game/ui/hud_theme.gd")
const Catalog=preload("res://scripts/game/ui/hud_catalog.gd")
const Types=preload("res://scripts/game/game_types.gd")
const RADIUS:=126.0
const INNER:=76.0
const CENTRE:=28.0
var session: IsometricGameSession
var cell:=Vector2i(-1,-1)
var category:=0
var choices: Array=[]
var family_valid: Array[bool]=[]
var caption: Label
var all_button: Button
var cancel_button: Button
var _down:=false
var _press:=Vector2.ZERO
var _hover:=-1

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(260,256)
	size=custom_minimum_size
	caption=UI.label(self,"",13)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	caption.position=Vector2(8,208); caption.size=Vector2(150,44)
	all_button=UI.button(self,"Tout",func(): catalogue_requested.emit(category))
	for state in ["normal","hover","pressed"]:
		var circle:=UI.command_surface(state=="pressed",0)
		circle.set_corner_radius_all(24); circle.corner_detail=12
		all_button.add_theme_stylebox_override(state,circle)
	all_button.add_theme_font_size_override("font_size",11)
	all_button.position=Vector2(106,106); all_button.size=Vector2(48,48)
	cancel_button=UI.button(self,"Fermer",func(): closed.emit())
	cancel_button.custom_minimum_size=Vector2(86,48)
	cancel_button.position=Vector2(166,208); cancel_button.size=Vector2(86,48)
	hide()

func open_at(target: Vector2i) -> void:
	cell=target
	family_valid.clear()
	for group in 4:
		var valid:=false
		for item in Catalog.TOOLS:
			if item[4]==group and session.progression.allows(item[0]):
				valid=valid or bool(session.check_action(cell,item[0]).get("valid",false))
		family_valid.append(valid)
	category=0 if session.sim.grid[cell.y][cell.x]==Types.Tile.ROCK else 2
	if not family_valid[category]:
		for index in 4:
			if family_valid[index]: category=index; break
	_choose_family(category)
	_down=false
	show()

func fit_available(area: Vector2) -> void:
	# Keep 48-unit radial thickness. Move instructions sideways instead of
	# scaling the interaction targets on short landscape phones.
	var compact:=area.y<256 and area.x>=420
	custom_minimum_size=Vector2(420,208) if compact else Vector2(260,256)
	size=custom_minimum_size
	caption.position=Vector2(268,68) if compact else Vector2(8,208)
	caption.size=Vector2(144,64) if compact else Vector2(150,44)
	cancel_button.position=Vector2(296,140) if compact else Vector2(166,208)

func _choose_family(index: int) -> void:
	category=index; choices.clear(); _hover=-1
	for item in Catalog.TOOLS:
		if item[4]==index and session.progression.allows(item[0]):
			choices.append(item)
			# More than five wedges would drop below 48 units at this radius.
			# The full family remains available through Tout.
			if choices.size()==5: break
	caption.text=Catalog.GROUPS[category]+" · choisir un objet"
	queue_redraw()

func _sector(a: float,b: float,inside: float,outside: float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for i in 25: points.append(Vector2(130,130)+Vector2.from_angle(lerpf(a,b,i/24.0))*outside)
	for i in range(24,-1,-1): points.append(Vector2(130,130)+Vector2.from_angle(lerpf(a,b,i/24.0))*inside)
	return points

func _draw() -> void:
	if not is_instance_valid(caption): return
	var font:=get_theme_default_font()
	for index in 4:
		var a: float=-PI+index*PI/2
		var polygon:=_sector(a,a+PI/2,CENTRE,INNER)
		draw_colored_polygon(polygon,Color("56316b") if index==category else Color("211b29"))
		draw_polyline(polygon,Color("a996b3") if family_valid[index] else Color("504455"),1.5,true)
		var at:=Vector2(130,130)+Vector2.from_angle(a+PI/4)*48
		draw_texture_rect(UI.icon(Catalog.GROUP_ICONS[index]),Rect2(at-Vector2.ONE*14,Vector2.ONE*28),false,Color.WHITE if family_valid[index] else Color(.4,.4,.4))
	var count:=choices.size()
	for index in count:
		var item: Array=choices[index]
		var valid: bool=session.check_action(cell,item[0]).get("valid",false)
		var a: float=-PI+PI*index/maxi(count,1)
		var b: float=-PI+PI*(index+1)/maxi(count,1)
		var polygon:=_sector(a,b,INNER+2,RADIUS)
		draw_colored_polygon(polygon,Color("62313e") if _hover==index else Color("1a1119"))
		draw_polyline(polygon,Color("d7c8b4") if valid else Color("655664"),1.5,true)
		var at:=Vector2(130,130)+Vector2.from_angle((a+b)/2)*100
		draw_texture_rect(UI.icon(item[3]),Rect2(at-Vector2(17,24),Vector2.ONE*34),false,Color.WHITE if valid else Color(.48,.48,.48))
		var cost:=str(session.check_action(cell,item[0]).get("cost",0))
		if not valid: cost=item[2].replace(" or","").replace("Gratuit","0").replace("Selon dégâts","—")
		var tw:=font.get_string_size(cost,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		draw_string(font,at+Vector2(-tw/2,26),cost,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dfbf76"))

func _choice_at(point: Vector2) -> int:
	var p:=point-Vector2(130,130)
	if p.length()<INNER or p.length()>RADIUS or p.y>0: return -1
	return mini(choices.size()-1,int((p.angle()+PI)/PI*choices.size()))

func cancel_pointer() -> void:
	_down=false

func _gui_input(event: InputEvent) -> void:
	if session.get_node("Input")._touches.size()>1:
		cancel_pointer(); accept_event(); return
	if event is InputEventMouseMotion:
		_hover=_choice_at(event.position)
		if _hover>=0: caption.text=choices[_hover][1]+" · "+choices[_hover][2]
		queue_redraw()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: _down=true; _press=event.position
		elif _down:
			_down=false
			if event.position.distance_to(_press)>14: return
			var p: Vector2=event.position-Vector2(130,130)
			if p.length()>=CENTRE and p.length()<INNER:
				var index:=int(fposmod(p.angle()+PI,TAU)/(PI/2))
				_choose_family(index)
			else:
				var index:=_choice_at(event.position)
				if index>=0:
					var action:=session.check_action(cell,choices[index][0])
					if action.get("valid",false): tool_chosen.emit(choices[index][0])
					else: caption.text=str(action.get("reason","Pose impossible"))
		accept_event()
