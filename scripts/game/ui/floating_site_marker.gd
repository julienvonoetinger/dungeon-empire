extends Sprite2D
## Translucent tool or prop suspended above a selectable site.
const GHOST_SHADER = preload("res://scripts/game/ui/floating_gift.gdshader")
const MINT := Color("#bcffea")
const TILE_SIDE := .87
static var materials: Dictionary[bool, ShaderMaterial] = {}
var resting_material: ShaderMaterial

func set_icon(icon: Texture2D, construction := false) -> void:
	texture = icon
	if not materials.has(construction):
		var ghost := ShaderMaterial.new()
		ghost.shader = GHOST_SHADER
		ghost.set_shader_parameter("construction",construction)
		materials[construction] = ghost
	resting_material = materials[construction]
	material = resting_material

func highlight(active: bool) -> void:
	material = null if active else resting_material

static func tile_extent(view: Node2D) -> Vector2:
	return view.grid_to_local(Vector2.RIGHT) * 2. * TILE_SIDE

static func draw_tile(node: Node2D, at: Vector2, corners: PackedVector2Array, unit: float, active: bool, construction: bool) -> void:
	var ink := Color("#ffedbd") if active else MINT
	var fill := Color("#d9b56965") if active else Color("#63bcaf38")
	if construction: fill = Color("#ffc46e93") if active else Color("#58e7bf79")
	node.draw_colored_polygon(corners, fill)
	if construction:
		var rim := corners.duplicate()
		rim.append(corners[0])
		node.draw_polyline(rim, Color(ink,.72), 1.6*unit, true)
	for i in 4:
		var tip := at.lerp(corners[i], .92)
		var a := at.lerp(corners[i].lerp(corners[(i+3)%4], .34), .92)
		var b := at.lerp(corners[i].lerp(corners[(i+1)%4], .34), .92)
		var bracket := PackedVector2Array([a,tip,b])
		node.draw_polyline(bracket, Color("#18323c"), 5.*unit, true)
		node.draw_polyline(bracket, ink, 2.6*unit, true)
	node.draw_set_transform(at, 0., Vector2(unit,unit*.38))
	node.draw_circle(Vector2.ZERO, 14., Color("#162936a8"), true,-1,true)
	node.draw_arc(Vector2.ZERO, 14., 0., TAU, 40, ink, 2., true)
	node.draw_set_transform(Vector2.ZERO)

static func draw_link(canvas: CanvasItem, anchor: Vector2, lift: float, unit: float, active: bool) -> void:
	var ink := Color("#ffd18a") if active else MINT
	var beam := PackedVector2Array([
		anchor + Vector2(-9.*unit, 0.), anchor + Vector2(-5.*unit, -lift),
		anchor + Vector2(5.*unit, -lift), anchor + Vector2(9.*unit, 0.)])
	canvas.draw_polygon(beam, PackedColorArray([Color(ink,.05),Color(ink,.23),Color(ink,.23),Color(ink,.05)]))
	for i in 4:
		var pos := anchor + Vector2.UP * (lift * (5.+9.*i)/42.)
		canvas.draw_circle(pos, (1.+.2*i)*unit, ink, true,-1,true)
