extends Control
## The v1 mobile vault/trap ring, adapted to the isometric solid groups.
## Read-only: selecting the actual cell still opens exact amounts and repairs.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
var amount := -1
var capacity := 1
var ratio := 0.0
var glyph := "coins"
var color := Color("e9b94f")
var protection_tier := 0
var protected := false
var segmented := false
var _icon: Texture2D

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size=Vector2(42,42)

func configure(icon_name: String, ink: Color, segments := false) -> void:
	glyph=icon_name
	_icon=UI.icon(glyph)
	color=ink
	segmented=segments
	queue_redraw()

func set_amount(value: int, maximum: int, tier := 0, intact := false) -> void:
	maximum=maxi(1,maximum)
	if amount==value and capacity==maximum and protection_tier==tier and protected==intact: return
	amount=value; capacity=maximum
	ratio=clampf(float(value)/maximum,0,1)
	protection_tier=tier; protected=intact
	queue_redraw()

func _draw() -> void:
	var center := Vector2(21,21)
	draw_circle(center,21,Color("0b1012"))
	draw_arc(center,18.5,0,TAU,64,Color("596273"),3,true)
	if ratio>0:
		draw_arc(center,18.5,-PI/2,-PI/2+TAU*ratio,64,color,3,true)
	if segmented and capacity>1:
		for i in capacity:
			var direction := Vector2.from_angle(-PI/2+TAU*i/capacity)
			draw_line(center+direction*16,center+direction*21,Color("0b1012"),2,true)
	if _icon:
		var fitted := _icon.get_size()*(27.0/maxf(_icon.get_width(),_icon.get_height()))
		draw_texture_rect(_icon,Rect2(center-fitted/2,fitted),false,Color.WHITE if amount>0 else Color("8a8a8a"))
	if protection_tier>0:
		var seal := Color("ca85ef") if protection_tier==2 else Color("e9b94f")
		if not protected: seal=Color("8a8a8a")
		draw_circle(Vector2(34,33),8,Color("0b1012"))
		if protection_tier==2:
			draw_polyline(PackedVector2Array([Vector2(34,27),Vector2(39,33),Vector2(34,39),Vector2(29,33),Vector2(34,27)]),seal,2,true)
		else:
			draw_arc(Vector2(34 if protected else 37,31),4,PI,TAU,12,seal,2,true)
			draw_rect(Rect2(29,31,10,7),seal,false,2)
