extends BaseButton
## A selectable floor tile for a gift, door or spike.
const BAG_TEXTURE = preload("res://assets/game/introduction/village-gold-bag.png")
const FloatingMarker = preload("res://scripts/game/ui/floating_site_marker.gd")
const LIFT := 42.0 # Logical pixels between the floor and the bottom of the preview.
var icon: Texture2D = BAG_TEXTURE
var view: Node2D
var tile_size := Vector2.ZERO
var tile_center := Vector2.ZERO
var preview := FloatingMarker.new()

func _ready() -> void:
	preview.name = "SitePreview"
	preview.set_icon(icon,icon != BAG_TEXTURE)
	add_child(preview)
	for state_change in [mouse_entered,mouse_exited,focus_entered,focus_exited,button_down,button_up]:
		state_change.connect(queue_redraw)

func fit(screen_center: Vector2, extent: Vector2, zoom: float, unit: float) -> void:
	scale = Vector2.ONE * unit
	tile_size = extent * zoom / unit
	var span := maxf(26., 70. * zoom / unit)
	preview.scale = Vector2.ONE * span / maxf(icon.get_width(),icon.get_height())
	var height := icon.get_height() * preview.scale.y
	var headroom := maxf(0., LIFT + height - tile_size.y*.5)
	size = Vector2(tile_size.x, tile_size.y + headroom)
	tile_center = Vector2(tile_size.x*.5, size.y-tile_size.y*.5)
	position = screen_center - tile_center * unit
	preview.position = tile_center + Vector2.UP * (LIFT + height*.5)
	queue_redraw()

func _has_point(point: Vector2) -> bool:
	if tile_size.x <= 0. or tile_size.y <= 0.: return false
	if preview.is_pixel_opaque(preview.transform.affine_inverse() * point): return true
	var delta := (point - tile_center).abs() / (tile_size*.5)
	if delta.x + delta.y > 1.: return false
	var screen := get_global_transform_with_canvas() * point
	return not view.solid_covers_point(view.get_global_transform_with_canvas().affine_inverse()*screen)

func paint_on_floor(floor_node: Node2D, at: Vector2, extent: Vector2, world_per_ui: float) -> void:
	var half := extent*.5
	var corners := PackedVector2Array([at+Vector2(0,-half.y),at+Vector2(half.x,0),at+Vector2(0,half.y),at+Vector2(-half.x,0)])
	var active := is_hovered() or has_focus() or is_pressed()
	FloatingMarker.draw_tile(floor_node, at, corners, world_per_ui, active, icon != BAG_TEXTURE)

func _draw() -> void:
	var active := is_hovered() or has_focus() or is_pressed()
	preview.highlight(active)
	FloatingMarker.draw_link(self, tile_center, LIFT, 1., active)
