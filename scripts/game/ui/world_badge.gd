extends Control
## Shared mobile vault/trap/door ring, adapted to the isometric solid groups.
## Read-only: selecting the actual cell still opens exact amounts and repairs.
const SCREEN_DIAMETER := 44.0
const CENTER := Vector2(21,21)
const RADIUS := 21.0
const ICON_EXTENT := 26.0
const SEALED_ICON_EXTENT := 22.0
const SEAL_CENTER := Vector2(27,27)
const ICONS := {
	"coins": preload("res://assets/ui/forge/coins.svg"),
	"spike": preload("res://assets/ui/master/badges/spike.svg"),
	"snare": preload("res://assets/ui/master/badges/snare.svg"),
	"void": preload("res://assets/ui/master/badges/void.svg"),
}
var amount := -1
var capacity := 1
var ratio := 0.0
var glyph := "coins"
var color := Color("e9b94f")
var protection_tier := 0
var protected := false
var segmented := false
var door_status := ""
var _icon: Texture2D

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size=CENTER*2
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR

func configure(icon_name: String, ink: Color, segments := false) -> void:
	glyph=icon_name
	_icon=ICONS.get(glyph)
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

func set_door_status(value: String) -> void:
	if door_status==value: return
	door_status=value
	queue_redraw()

func contains_ink(point: Vector2) -> bool:
	return point.distance_to(CENTER) <= RADIUS

func _draw() -> void:
	draw_circle(CENTER,RADIUS,Color("0b1012"),true,-1,true)
	draw_arc(CENTER,18.5,0,TAU,64,Color("718097"),3,true)
	if ratio>0:
		draw_arc(CENTER,18.5,-PI/2,-PI/2+TAU*ratio,64,color,3,true)
	if segmented and capacity>1:
		for i in capacity:
			var direction := Vector2.from_angle(-PI/2+TAU*i/capacity)
			draw_line(CENTER+direction*16,CENTER+direction*RADIUS,Color("0b1012"),2,true)
	if glyph == "lock":
		var tint := Color("e0a2ff") if protection_tier == 2 else Color("ffd377")
		if door_status == "open": tint = Color("9de4c9")
		if door_status == "broken": tint = Color("ff9a9e")
		draw_set_transform(CENTER,0,Vector2.ONE*1.55)
		_draw_padlock(door_status in ["open","broken"],tint,door_status == "broken")
		return
	var has_seal := protection_tier > 0
	if _icon:
		var extent := SEALED_ICON_EXTENT if has_seal else ICON_EXTENT
		var center := CENTER - Vector2(2.5,2) if has_seal else CENTER
		var fitted := _icon.get_size()*(extent/maxf(_icon.get_width(),_icon.get_height()))
		draw_texture_rect(_icon,Rect2(center-fitted/2,fitted),false,Color.WHITE if amount>0 else Color("a5a7ad"))
	if not has_seal: return
	draw_set_transform(SEAL_CENTER,0,Vector2.ONE*.71)
	draw_circle(Vector2.ZERO,9,Color("101522"),true,-1,true)
	if protection_tier==2:
		var tint := Color("e0a2ff") if protected else Color("a5a7ad")
		draw_polyline(PackedVector2Array([Vector2(0,-6),Vector2(5,0),Vector2(0,6),Vector2(-5,0),Vector2(0,-6)]),tint,2.5,true)
	else:
		_draw_padlock(not protected,Color("ffd377") if protected else Color("9de4c9"))

func _draw_padlock(opened: bool, tint: Color, broken := false) -> void:
	var shackle := Vector2(2.5,-3.5) if opened else Vector2(0,-1.5)
	draw_arc(shackle,3.5,PI,TAU,16,tint,2,true)
	draw_line(shackle+Vector2(-3.5,0),shackle+Vector2(-3.5,4),tint,2,true)
	if not opened: draw_line(shackle+Vector2(3.5,0),shackle+Vector2(3.5,3),tint,2,true)
	draw_rect(Rect2(-5,0,10,6),tint)
	if broken:
		draw_polyline(PackedVector2Array([Vector2(1,0),Vector2(-1,3),Vector2(1,3),Vector2(-1,6)]),Color("302539"),1.5,true)
	else:
		draw_line(Vector2(0,2),Vector2(0,4),Color("302539"),2,true)
