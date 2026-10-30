extends Control
## Joint sectors keep fixed family directions at each screen size. World input is
## captured by HUD while open; the opening release cannot also activate a wedge.
signal tool_chosen(tool: int)
signal closed
const UI=preload("res://scripts/game/ui/hud_theme.gd")
const Catalog=preload("res://scripts/game/ui/hud_catalog.gd")
const Types=preload("res://scripts/game/game_types.gd")
const PREFERRED_RADIUS:=176.0
const PAD:=4.0
const FOOTER:=56.0
const SIDE_HELP:=168.0
var radius:=PREFERRED_RADIUS
var inner:=88.0
var centre_radius:=40.0
var price_width:=24.0
var session: IsometricGameSession
var cell:=Vector2i(-1,-1)
var category:=0
var choices: Array=[]
var family_valid: Array[bool]=[]
var caption: Label
var close_button: Button
var close_icon: TextureRect
var close_label: Label
var _down:=false
var _press:=Vector2.ZERO
var _hover:=-1
var _touch_index:=-1
var _dragged:=false

class RoundButton extends Button:
	func _has_point(point: Vector2) -> bool:
		return point.distance_to(size/2)<=minf(size.x,size.y)/2

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_STOP
	caption=UI.label(self,"",13)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	close_button=RoundButton.new(); add_child(close_button)
	close_button.custom_minimum_size=Vector2(48,48)
	close_button.mouse_filter=MOUSE_FILTER_STOP
	close_button.pressed.connect(func(): closed.emit())
	var contents:=VBoxContainer.new(); close_button.add_child(contents)
	contents.mouse_filter=MOUSE_FILTER_IGNORE
	contents.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	contents.offset_left=4; contents.offset_right=-4
	contents.offset_top=4; contents.offset_bottom=-4
	contents.alignment=BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation",2)
	close_icon=UI.picture(contents,"cross",20)
	close_icon.size_flags_horizontal=SIZE_SHRINK_CENTER
	close_label=UI.label(contents,"Close",13)
	close_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	close_button.tooltip_text="Close build menu"
	for state in ["normal","hover","pressed"]:
		close_button.add_theme_stylebox_override(state,UI.round_surface(state=="pressed"))
	mouse_exited.connect(func():
		if not _down: _set_hover(-1))
	fit_available(Vector2(760,620))
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
	cancel_pointer()
	show()

func fit_available(area: Vector2) -> void:
	# Prefer the larger review geometry. On short landscape screens move help
	# beside the rings first; only then reduce radii, never scale the whole HUD.
	radius=minf(PREFERRED_RADIUS,(area.x-PAD*2)/2)
	var sideways:=false
	while radius>100:
		inner=clampf(radius*.5,72,88)
		var height:=radius+inner+PAD*2
		if height+FOOTER<=area.y: break
		if height<=area.y and radius*2+PAD*2+SIDE_HELP<=area.x:
			sideways=true
			break
		radius-=1
	inner=clampf(radius*.5,72,88)
	centre_radius=inner-48
	price_width=24 if radius>=148 else 20
	var ring_height:=radius+inner+PAD*2
	var ring_width:=radius*2+PAD*2
	custom_minimum_size=Vector2(ring_width+SIDE_HELP,ring_height) if sideways else Vector2(ring_width,ring_height+FOOTER)
	size=custom_minimum_size
	close_button.position=menu_center()-Vector2.ONE*centre_radius
	close_button.size=Vector2.ONE*centre_radius*2
	close_label.add_theme_font_size_override("font_size",13 if centre_radius>=30 else 11)
	close_icon.custom_minimum_size=Vector2.ONE*(20 if centre_radius>=30 else 16)
	caption.position=Vector2(ring_width+8,ring_height/2-32) if sideways else Vector2(8,ring_height+4)
	caption.size=Vector2(SIDE_HELP-16,64) if sideways else Vector2(ring_width-16,48)
	caption.add_theme_font_size_override("font_size",14)
	queue_redraw()

func menu_center() -> Vector2:
	return Vector2.ONE*(radius+PAD)

func choice_point(index: int, price: bool=false) -> Vector2:
	var angle: float=-PI+PI*(index+.5)/maxi(choices.size(),1)
	var distance:=radius-price_width/2 if price else (inner+radius-price_width)/2
	return menu_center()+Vector2.from_angle(angle)*distance

func _choose_family(index: int) -> void:
	category=index; choices.clear(); _hover=-1
	for item in Catalog.TOOLS:
		if item[4]==index and session.progression.allows(item[0]):
			choices.append(item)
			# More than five wedges would drop below 48 units at this radius.
			# The full family remains available through the HUD Catalog button.
			if choices.size()==5: break
	_set_hover(-1)
	queue_redraw()

func _set_hover(index: int) -> void:
	_hover=index
	caption.text=Catalog.GROUPS[category]+" · choose an item"
	if index>=0:
		var item: Array=choices[index]
		var action:=session.check_action(cell,item[0])
		var cost:=_price(item,action)
		caption.text=item[1]+" · "+("Free" if cost=="0" else ("Varies" if cost=="—" else cost+" gold"))
	queue_redraw()

func _sector(a: float,b: float,inside: float,outside: float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for i in 25: points.append(menu_center()+Vector2.from_angle(lerpf(a,b,i/24.0))*outside)
	for i in range(24,-1,-1): points.append(menu_center()+Vector2.from_angle(lerpf(a,b,i/24.0))*inside)
	return points

func _paint_sector(a: float,b: float,inside: float,outside: float,selected: bool=false,enabled: bool=true,price: bool=false) -> void:
	# Map the painted stone disc to actual sector geometry, so unlocked action
	# counts and short-screen radii never depend on a fixed mockup image.
	var boundary:=_sector(a,b,inside,outside)
	draw_colored_polygon(boundary,Color("080e1a"))
	var gap:=1.5/maxf(inside,1)
	var face:=_sector(a+gap,b-gap,inside+1.5,outside-1.5)
	var uv:=PackedVector2Array()
	for point in face: uv.append((point-menu_center())/(outside*2)+Vector2(.5,.5))
	var tint:=Color.WHITE if enabled else Color(.6,.6,.68)
	draw_polygon(face,PackedColorArray([tint]),uv,UI.STONE_FACE)
	# Confine the painted bevel to a narrow rim: scaling the whole disc into
	# every sector would make its border intrude behind the action icons.
	var rim:=_sector(a+gap,b-gap,outside-5,outside-1.5)
	var rim_uv:=PackedVector2Array()
	for point in rim:
		var delta:=point-menu_center()
		var source_radius:=.41 if delta.length()<outside-3 else .495
		rim_uv.append(Vector2(.5,.5)+delta.normalized()*source_radius)
	draw_polygon(rim,PackedColorArray([tint]),rim_uv,UI.STONE_ROUND)
	if selected: draw_colored_polygon(face,Color(.5,.16,.72,.32))
	var edge:=face.duplicate(); edge.append(edge[0])
	draw_polyline(edge,UI.ACCENT if selected else Color("526d91") if enabled else Color("354157"),1.2,true)
	boundary.append(boundary[0]); draw_polyline(boundary,Color("090d18"),1.5,true)
	if price:
		var socket:=_sector(a+gap*2,b-gap*2,inside+4,outside-4)
		draw_colored_polygon(socket,Color("45305f") if selected else Color("0c1120"))
		socket.append(socket[0])
		draw_polyline(socket,UI.ACCENT if selected else Color("35445c"),1.0,true)

func _paint_icon(glyph: String,at: Vector2,extent: float,valid: bool) -> void:
	var texture:=UI.icon(glyph)
	var picture_size:=_icon_size(glyph,extent)
	draw_texture_rect(texture,Rect2(at-picture_size/2,picture_size),false,Color.WHITE if valid else Color(.6,.57,.65))

func _icon_size(glyph: String,extent: float) -> Vector2:
	var picture_size:=UI.icon(glyph).get_size()
	return picture_size*extent/maxf(picture_size.x,picture_size.y)

func _price(item: Array,action: Dictionary) -> String:
	if action.get("valid",false): return str(action.get("cost",0))
	return item[2].replace(" gold","").replace("Free","0").replace("Varies","—")

func _draw() -> void:
	if not is_instance_valid(caption): return
	var font:=get_theme_default_font()
	for index in 4:
		var a: float=-PI+index*PI/2
		_paint_sector(a,a+PI/2,centre_radius,inner,index==category)
		var at:=menu_center()+Vector2.from_angle(a+PI/4)*(centre_radius+inner)/2
		_paint_icon(Catalog.GROUP_ICONS[index],at,36,family_valid[index])
	var count:=choices.size()
	for index in count:
		var item: Array=choices[index]
		var action:=session.check_action(cell,item[0])
		var valid: bool=action.get("valid",false)
		var a: float=-PI+PI*index/maxi(count,1)
		var b: float=-PI+PI*(index+1)/maxi(count,1)
		var active:=_hover==index and valid
		_paint_sector(a,b,inner,radius-price_width,active,valid)
		_paint_sector(a,b,radius-price_width,radius,active,valid,true)
		var at:=choice_point(index)
		# Fit the complete icon inside the action area, including its corners.
		var extent:=48.0
		while extent>24:
			var fits:=true
			var icon_size:=_icon_size(item[3],extent)
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
				var delta: Vector2=at+corner*icon_size/2-menu_center()
				if delta.length()<inner+2 or delta.length()>radius-price_width-2 or delta.angle()<a+.02 or delta.angle()>b-.02: fits=false
			if fits: break
			extent-=2
		_paint_icon(item[3],at,extent,valid)
		var cost:=_price(item,action)
		var font_size:=16 if price_width>=24 else 14
		var tw:=font.get_string_size(cost,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var baseline:=(font.get_ascent(font_size)-font.get_descent(font_size))/2
		draw_string(font,choice_point(index,true)+Vector2(-tw/2,baseline),cost,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("fff2ff") if active else (UI.TEXT if valid else Color("a798af")))

func _choice_at(point: Vector2) -> int:
	var p:=point-menu_center()
	if choices.is_empty() or p.length()<inner or p.length()>radius or p.y>0: return -1
	return mini(choices.size()-1,int((p.angle()+PI)/PI*choices.size()))

func cancel_pointer() -> void:
	_down=false
	_touch_index=-1
	_dragged=false
	_set_hover(-1)

func _begin_pointer(point: Vector2) -> void:
	_down=true; _press=point; _dragged=false
	_set_hover(_choice_at(point))

func _move_pointer(point: Vector2) -> void:
	if _down and point.distance_to(_press)>14: _dragged=true
	_set_hover(-1 if _dragged else _choice_at(point))

func _release_pointer(point: Vector2) -> void:
	if not _down: return
	_down=false
	if _dragged or point.distance_to(_press)>14:
		_set_hover(-1)
		return
	var p:=point-menu_center()
	if p.length()>=centre_radius and p.length()<inner:
		var index:=int(fposmod(p.angle()+PI,TAU)/(PI/2))
		_choose_family(index)
	else:
		var index:=_choice_at(point)
		if index>=0:
			var action:=session.check_action(cell,choices[index][0])
			if action.get("valid",false): tool_chosen.emit(choices[index][0])
			else:
				caption.text=str(action.get("reason","Cannot place here"))
				session.report_rejected_action(cell,choices[index][0])

func _gui_input(event: InputEvent) -> void:
	if session.get_node("Input")._touches.size()>1:
		cancel_pointer(); accept_event(); return
	# Handle touch directly. Godot may also emit a synthetic mouse event for
	# that finger; consuming it here prevents a duplicate press or purchase.
	if event is InputEventMouse and event.device==-1:
		accept_event(); return
	if event is InputEventScreenTouch:
		if event.canceled: cancel_pointer()
		elif event.pressed:
			_touch_index=event.index
			_begin_pointer(event.position)
		elif event.index==_touch_index:
			_touch_index=-1
			_release_pointer(event.position)
		accept_event()
	elif event is InputEventScreenDrag and event.index==_touch_index:
		_move_pointer(event.position); accept_event()
	elif event is InputEventMouseMotion:
		_move_pointer(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: _begin_pointer(event.position)
		else: _release_pointer(event.position)
		accept_event()
