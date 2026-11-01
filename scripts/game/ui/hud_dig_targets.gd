extends Control
## Screen-space assistance only for rock without a clear finger-sized target.
## Input stays in GameInput so a pan beginning on a badge remains a pan.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
const RADIUS := 24.0
const SEPARATION := 52.0
const NONE := Vector2i(-1,-1)
var hud: CanvasLayer
var targets: Array[Dictionary] = []
var pressed_cell := NONE
var _signature := 0
var _transform := Transform2D.IDENTITY
var _blocked: Array[Rect2] = []
var _view: Node2D
var _rock_samples: Dictionary = {}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(hud) or not is_instance_valid(hud.modal): return
	_view=hud.session.get_node("PlayArea/World/Dungeon")
	var input=hud.session.get_node("Input")
	var enabled: bool=_view.dig_guides_visible and hud.session.can_edit() and not hud.shade.visible
	if input._pointer!=-2 and input._dragged: enabled=false
	_blocked.clear()
	for control in [hud.header,hud.utilities,hud.speeds,hud.pose_bar,hud.hint]:
		if control.visible: _blocked.append(control.get_global_rect().grow(4))
	for item in _view._markers:
		var badge: Control=item.node.badge
		if not is_instance_valid(badge) or not badge.is_visible_in_tree(): continue
		var t:=badge.get_global_transform_with_canvas()
		_blocked.append(Rect2(t.origin/hud.scale.x,badge.size*t.get_scale()/hud.scale.x).grow(4))
	_transform=_view.get_global_transform_with_canvas()
	var signature:=hash([enabled,_transform,hud.scale,hud._safe,_view.dig_cells,_blocked])
	if signature==_signature: return
	_signature=signature
	targets.clear()
	_rock_samples.clear()
	if enabled:
		for cell in _view.dig_cells:
			var anchor: Vector2=_screen(_view.grid_to_local(Vector2(cell)+Vector2(.5,.5)))
			# Off-screen rock stays off-screen; panning reveals it normally.
			if not hud._safe.has_point(anchor) or _inside_hud(anchor): continue
			if _easy_target(cell,anchor): continue
			var outward:=Vector2.ZERO
			for direction in Types.DIRS:
				var next: Vector2i=cell+direction
				if hud.session.sim._inside(next) and hud.session.sim.grid[next.y][next.x]!=Types.Tile.ROCK:
					outward-=_view.grid_to_local(Vector2(direction))
			if outward.length_squared()<.01: outward=Vector2.UP
			outward=outward.normalized()
			var center:=_find_space(anchor,outward)
			if center.is_finite():
				var endpoint:=_visible_anchor(cell,center)
				if endpoint.is_finite(): targets.append({"cell":cell,"anchor":endpoint,"center":center})
	var assisted: Dictionary={}
	for target in targets: assisted[target.cell]=true
	if _view.assisted_dig_cells!=assisted:
		_view.assisted_dig_cells=assisted
		_view._floor_guide.queue_redraw()
	queue_redraw()

func _screen(point: Vector2) -> Vector2:
	return (_transform*point)/hud.scale.x

func _world(point: Vector2) -> Vector2:
	return _transform.affine_inverse()*(point*hud.scale.x)

func _inside_hud(point: Vector2) -> bool:
	for rect in _blocked:
		if rect.has_point(point): return true
	return false

func _easy_target(cell: Vector2i, center: Vector2) -> bool:
	# Nine samples require a clear 48-unit disc on this very cell. Small or
	# partly hidden diamonds get a screen-size button rather than an unsafe hitbox.
	for offset in [Vector2.ZERO,Vector2(24,0),Vector2(-24,0),Vector2(0,24),Vector2(0,-24),Vector2(17,17),Vector2(-17,17),Vector2(17,-17),Vector2(-17,-17)]:
		var point: Vector2=center+offset
		var local_point:=_world(point)
		if not hud._safe.has_point(point) or _inside_hud(point): return false
		if _view.pick_cell(local_point)!=cell or _view.solid_covers_point(local_point): return false
	return true

func _visible_anchor(cell: Vector2i, center: Vector2) -> Vector2:
	var best:=Vector2.INF
	var distance:=INF
	for x in [.15,.35,.5,.65,.85]:
		for y in [.15,.35,.5,.65,.85]:
			var local_point: Vector2=_view.grid_to_local(Vector2(cell)+Vector2(x,y))
			var screen:=_screen(local_point)
			if not hud._safe.has_point(screen) or _inside_hud(screen) or _view.solid_covers_point(local_point): continue
			var score:=screen.distance_squared_to(center)
			if score<distance: best=screen; distance=score
	return best

func _find_space(anchor: Vector2, outward: Vector2) -> Vector2:
	for distance in [0.0,28.0,44.0,60.0,80.0,104.0]:
		for angle in [0.0,-PI/6,PI/6,-PI/3,PI/3,-PI/2,PI/2,PI]:
			if distance==0.0 and angle!=0.0: continue
			var center: Vector2=anchor+outward.rotated(angle)*distance
			if _fits(center): return center
	return Vector2.INF

func _fits(center: Vector2) -> bool:
	var rect:=Rect2(center-Vector2.ONE*RADIUS,Vector2.ONE*RADIUS*2)
	if not hud._safe.encloses(rect): return false
	for blocked in _blocked:
		if rect.intersects(blocked): return false
	for target in targets:
		if center.distance_to(target.center)<SEPARATION: return false
	# Do not place a paid command over a door, chest or walkable floor.
	for offset in [Vector2.ZERO,Vector2(24,0),Vector2(-24,0),Vector2(0,24),Vector2(0,-24),Vector2(24,24),Vector2(-24,24),Vector2(24,-24),Vector2(-24,-24)]:
		if not _free_rock(center+offset): return false
	# Thin diagonal masonry can cross a disc between its cardinal samples.
	for angle in range(0,360,15):
		if not _free_rock(center+Vector2.from_angle(deg_to_rad(angle))*RADIUS): return false
	return true

func _free_rock(point: Vector2) -> bool:
	if _rock_samples.has(point): return _rock_samples[point]
	var local_point:=_world(point)
	var cell: Vector2i=_view.pick_cell(local_point)
	var free: bool=hud.session.sim._inside(cell) and hud.session.sim.grid[cell.y][cell.x]==Types.Tile.ROCK and not _view.solid_covers_point(local_point)
	_rock_samples[point]=free
	return free

func hit_cell(point: Vector2) -> Vector2i:
	refresh()
	for target in targets:
		if point.distance_to(target.center)<=RADIUS: return target.cell
	return NONE

func press(cell: Vector2i) -> void:
	pressed_cell=cell; queue_redraw()

func cancel_press() -> void:
	press(NONE)

func _draw() -> void:
	for target in targets:
		var toward: Vector2=target.anchor-target.center
		if toward.length()>22:
			draw_line(target.center+toward.normalized()*20,target.anchor,Color("c69aeb"),1.5,true)
			draw_circle(target.anchor,2.5,Color("dab9f4"))
	for target in targets:
		var selected: bool=pressed_cell==target.cell
		draw_style_box(UI.round_surface(selected),Rect2(target.center-Vector2(20,20),Vector2(40,40)))
		var picture:=UI.icon("pick")
		var extent:=picture.get_size()*(26.0/maxf(picture.get_width(),picture.get_height()))
		draw_texture_rect(picture,Rect2(target.center-extent*.5,extent),false)
