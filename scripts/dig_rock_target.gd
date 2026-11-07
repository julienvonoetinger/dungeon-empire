extends Node2D
## A floating tool or building marks its selectable tile on the dungeon floor.
const DIG_ICON=preload("res://assets/ui/master/dark-icons/dig.png")
const FloatingMarker = preload("res://scripts/game/ui/floating_site_marker.gd")
const MAX_ICON_SIZE := .44 # Relative to the projected footprint.
const MAX_LIFT_IN_ROWS := .72 # Keep the pick clear of the next tile's landing ring.
var cell:=Vector2i.ZERO
var footprint := PackedVector2Array()
var top_center:=Vector2.ZERO
var support: Dictionary={}
var pressed:=false:
	set(value):
		if pressed == value: return
		pressed = value
		preview.highlight(value)
		queue_redraw()
var preview := FloatingMarker.new()
var _last_scale:=0.0
var _last_view_size:=Vector2.ZERO
var _last_window_size:=Vector2i.ZERO
var _lift := 0.
var _link_unit := 1.

func configure(view: Node2D, at: Vector2i, icon: Texture2D = DIG_ICON) -> void:
	cell=at
	preview.name = "SitePreview"
	preview.set_icon(icon,icon != DIG_ICON)
	# A replacement can sit under the existing object's floating status ring.
	preview.z_index = 12 if icon != DIG_ICON else 3
	add_child(preview)
	var low:=Vector2.ONE*((1.0-FloatingMarker.TILE_SIDE)*.5)
	var high:=Vector2.ONE-low
	for offset in [low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]:
		footprint.append(view.grid_to_local(Vector2(cell)+offset))
	var center := Vector2(cell) + Vector2(.5,.5)
	top_center=view.grid_to_local(center)
	var rect:=Rect2(footprint[0],Vector2.ZERO)
	for point in footprint: rect=rect.expand(point)
	support={"min":Vector3(cell.x+low.x,cell.y+low.y,0),"max":Vector3(cell.x+high.x,cell.y+high.y,0),"rect":rect}
	queue_redraw()

func framing_bounds() -> Rect2:
	var bounds: Rect2 = support.rect
	var row_pitch := bounds.size.y / FloatingMarker.TILE_SIDE
	return bounds.expand(top_center + Vector2.UP * (row_pitch*MAX_LIFT_IN_ROWS + bounds.size.x*MAX_ICON_SIZE*.5))

func preview_covers(point: Vector2) -> bool:
	return preview.is_visible_in_tree() and preview.is_pixel_opaque(preview.transform.affine_inverse() * point)

func _ready() -> void:
	_fit_preview()

func _process(_delta: float) -> void:
	_fit_preview()

func _fit_preview() -> void:
	var scale_factor:=get_global_transform_with_canvas().get_scale().x
	var view_size:=get_tree().root.get_visible_rect().size
	if not is_equal_approx(scale_factor,_last_scale) or view_size!=_last_view_size or get_window().size!=_last_window_size:
		_last_scale=scale_factor
		_last_view_size=view_size
		_last_window_size=get_window().size
		var density := clampf(DisplayServer.screen_get_dpi()/160.,1.,4.) if OS.has_feature("mobile") else 1.
		var unit := density * view_size.x / maxf(1., _last_window_size.x) / maxf(.1,scale_factor)
		var width: float = support.rect.size.x
		var size := minf(34.*unit, width * MAX_ICON_SIZE)
		var texture_size := preview.texture.get_size()
		preview.scale = Vector2.ONE * size / maxf(texture_size.x,texture_size.y)
		var height := texture_size.y * preview.scale.y
		var row_pitch: float = support.rect.size.y / FloatingMarker.TILE_SIDE
		_lift = minf(42.*unit, row_pitch*MAX_LIFT_IN_ROWS - height*.5)
		_link_unit = minf(unit, size/32.)
		preview.position = top_center + Vector2.UP * (_lift + height*.5)
		queue_redraw()

func covers(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, footprint)

func _draw() -> void:
	if footprint.is_empty(): return
	FloatingMarker.draw_tile(self, top_center, footprint, _link_unit, pressed, preview.texture != DIG_ICON)
	FloatingMarker.draw_link(self, top_center, _lift, _link_unit, pressed)
