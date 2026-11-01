extends Control
## Shared excavation volumes; GameInput owns the one-shot touch/Undo pipeline.
const Block=preload("res://scripts/dig_rock_target.gd")
const Sorter=preload("res://scripts/mobile_dungeon_renderer.gd")
const Layout=preload("res://scripts/dig_target_layout.gd")
const Geometry=preload("res://scripts/game/terrain_geometry.gd")
var hud: CanvasLayer
var blocks: Array[Node2D]=[]
var ordered: Array[Dictionary]=[]
var height:=0.0
var pressed_cell:=Vector2i(-1,-1)
var _sorter:=Sorter.new()
var _view: Node2D
var _signature:=0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_view=hud.session.get_node("PlayArea/World/Dungeon")
	hud.session.changed.connect(func(_structure): _signature=0; refresh())
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	# HUD children enter the tree before the session's first renderer rebuild.
	if not is_instance_valid(_view) or _view._definition==null or not is_instance_valid(_view._world): return
	height=float(_view._definition.get("entries")["wall-h-0"].bounds.max[2])
	var signature:=hash([_view.dig_cells,_view.solid_groups])
	if signature!=_signature:
		_signature=signature
		for block in blocks:
			if is_instance_valid(block) and not block.is_queued_for_deletion():
				block.get_parent().remove_child(block); block.queue_free()
		blocks.clear(); ordered=_view.solid_groups.duplicate()
		var terrain=hud.session.get_node("PlayArea/World/Terrain")
		var shifts: Dictionary=Layout.offsets(_view,_view.dig_cells,maxf(0,terrain.cut_margin-Geometry.MARGIN))
		for cell in _view.dig_cells:
			var block:=Block.new()
			block.configure(_view,cell,height,shifts[cell])
			_view._world.add_child(block)
			blocks.append(block); ordered.append(block.support)
		ordered=_sorter._ordered_parts(ordered)
		# The renderer already orders masonry and heroes during raids. Do not
		# disturb that order when no excavation volumes need insertion.
		if not blocks.is_empty():
			for part in ordered: _view._world.move_child(part.node,-1)
	var enabled: bool=_view.dig_guides_visible and hud.session.can_edit()
	if is_instance_valid(hud.shade): enabled=enabled and not hud.shade.visible
	for block in blocks: block.visible=enabled

func hit_cell(point: Vector2) -> Vector2i:
	refresh()
	if not is_instance_valid(_view) or not _view.dig_guides_visible or not hud.session.can_edit(): return Vector2i(-1,-1)
	if is_instance_valid(hud.shade) and hud.shade.visible: return Vector2i(-1,-1)
	var local_point: Vector2=_view.get_global_transform_with_canvas().affine_inverse()*(point*hud.scale.x)
	if _view.solid_covers_point(local_point): return Vector2i(-1,-1)
	for index in range(ordered.size()-1,-1,-1):
		var part: Dictionary=ordered[index]
		if not part.rect.has_point(local_point): continue
		if part.has("dig_cell") and part.node.visible and part.node.covers(local_point): return part.dig_cell
	return Vector2i(-1,-1)

func press(cell: Vector2i) -> void:
	pressed_cell=cell
	for block in blocks:
		if is_instance_valid(block): block.pressed=block.cell==cell; block.queue_redraw()

func cancel_press() -> void:
	press(Vector2i(-1,-1))

func _exit_tree() -> void:
	_sorter.free()
