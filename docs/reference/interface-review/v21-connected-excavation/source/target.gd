extends Node2D
## Excavation affordance on the connected bedrock, never a freestanding prop.
const UI=preload("res://scripts/game/ui/hud_theme.gd")
var cell:=Vector2i.ZERO
var faces: Array[PackedVector2Array]=[]
var top_center:=Vector2.ZERO
var support: Dictionary={}
var pressed:=false
var icon: Texture2D
var _last_scale:=0.0
var _last_view_size:=Vector2.ZERO
var _last_window_size:=Vector2i.ZERO
var _icon_rect:=Rect2()

func configure(view: Node2D, at: Vector2i, height: float) -> void:
	cell=at; icon=UI.icon("pick")
	var low:=Vector2(.13,.13); var high:=Vector2(.87,.87)
	# Leave a visible gap beside the wall. Keep the mark inside the cut surface.
	var sim=view.session.sim
	for dir in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
		if sim._inside(cell+dir) and sim.grid[cell.y+dir.y][cell.x+dir.x]!=view.Types.Tile.ROCK:
			if dir==Vector2i.LEFT: low.x=.28
			elif dir==Vector2i.UP: low.y=.28
			elif dir==Vector2i.RIGHT: high.x=.72
			else: high.y=.72
	var top:=PackedVector2Array()
	for offset in [low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]:
		top.append(view.grid_to_local(Vector2(cell)+offset,height))
	faces=[top]
	top_center=view.grid_to_local(Vector2(cell)+(low+high)*.5,height)
	var rect:=Rect2(top[0],Vector2.ZERO)
	for point in top: rect=rect.expand(point)
	var direction: Vector3=view._definition.get("view_direction")
	support={"id":"dig-rock-target","at":Vector2(cell),"min":Vector3(cell.x+low.x,cell.y+low.y,0),"max":Vector3(cell.x+high.x,cell.y+high.y,height),"rect":rect,"depth":(Vector2(cell)+Vector2(.5,.5)).dot(Vector2(direction.x,direction.y)),"node":self,"dig_cell":cell}
	z_index=1
	queue_redraw()

func _process(_delta: float) -> void:
	var scale_factor:=get_global_transform_with_canvas().get_scale().x
	var view_size:=get_tree().root.get_visible_rect().size
	if not is_equal_approx(scale_factor,_last_scale) or view_size!=_last_view_size or get_window().size!=_last_window_size:
		_last_scale=scale_factor
		_last_view_size=view_size
		_last_window_size=get_window().size
		queue_redraw()

func covers(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,faces[0]) or _icon_rect.has_point(point)

func _draw() -> void:
	if faces.is_empty(): return
	var pixel:=1.0/maxf(.1,get_global_transform_with_canvas().get_scale().x)
	var top:=faces[0]
	draw_colored_polygon(top,Color(.52,.28,.78,.22 if pressed else .10))
	var line:=top.duplicate(); line.append(line[0])
	draw_polyline(line,Color(.82,.62,1,.98 if pressed else .68),pixel*(2.2 if pressed else 1.25),true)
	var density:=clampf(DisplayServer.screen_get_dpi()/160.0,1,4) if OS.has_feature("mobile") else 1.0
	var ui_scale:=get_tree().root.get_visible_rect().size.x/maxf(1,get_window().size.x)*density
	var side:=minf(32*ui_scale*pixel,absf(top[1].x-top[3].x)*.52)
	var size:=Vector2(side,side)
	var ratio:=Vector2(icon.get_size()); ratio*=side/maxf(ratio.x,ratio.y)
	_icon_rect=Rect2(top_center-size*.5,size)
	draw_texture_rect(icon,Rect2(top_center-ratio*.5+Vector2(1.2,1.5)*pixel,ratio),false,Color(0,0,0,.75))
	draw_texture_rect(icon,Rect2(top_center-ratio*.5,ratio),false,Color(1.15,1.07,1.23) if pressed else Color.WHITE)
	# Support bounds include only the real visible icon, not a detached badge.
	support.rect=Rect2(top[0],Vector2.ZERO)
	for point in top: support.rect=support.rect.expand(point)
	support.rect=support.rect.merge(_icon_rect)
