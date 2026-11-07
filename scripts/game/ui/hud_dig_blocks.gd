extends Control
## Excavation and construction share the same map markers and touch handling.
const Block=preload("res://scripts/dig_rock_target.gd")
const Types=preload("res://scripts/game/game_types.gd")
var hud: CanvasLayer
var blocks: Array[Node2D]=[]
var pressed_cell:=Vector2i(-1,-1)
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
	var icon: Texture2D = _view.build_site_icon
	var cells: Array[Vector2i] = _view._valid_cells if icon else _view.dig_cells
	var signature:=hash([cells,icon])
	if signature!=_signature:
		_signature=signature
		for block in blocks:
			if is_instance_valid(block) and not block.is_queued_for_deletion():
				block.get_parent().remove_child(block); block.queue_free()
		blocks.clear()
		for cell in cells:
			var block:=Block.new()
			block.configure(_view,cell,icon if icon else Block.DIG_ICON)
			if icon: block.preview.flip_h = _view.should_flip_build_icon(icon,cell)
			_view._floor_guide.add_child(block)
			blocks.append(block)
	var dragging: bool = icon != null and _view.placement_tool != Types.Tool.NONE
	var building: bool = icon != null and (dragging or not hud.session.catalog_open and hud.session.selected.x < 0)
	var enabled: bool=(_view.dig_guides_visible or _view.lesson_digging or building) and hud.session.can_edit()
	if is_instance_valid(hud.shade): enabled=enabled and not hud.shade.visible
	var active_cell := pressed_cell
	if dragging: active_cell = _view._placement_cell if _view._placement_valid else Vector2i(-1,-1)
	for block in blocks:
		block.visible=enabled
		block.pressed=block.cell==active_cell

func hit_cell(point: Vector2) -> Vector2i:
	refresh()
	if blocks.is_empty() or not blocks[0].is_visible_in_tree(): return Vector2i(-1,-1)
	var local_point: Vector2=_view.get_global_transform_with_canvas().affine_inverse()*(point*hud.scale.x)
	var on_badge: bool = _view.badge_covers_point(local_point)
	if on_badge and not _view.build_site_icon: return Vector2i(-1,-1)
	# All raised previews draw above the floor tiles, in sibling order.
	for index in range(blocks.size()-1,-1,-1):
		var block := blocks[index]
		if block.preview_covers(local_point): return block.cell
	if on_badge or _view.scenery_covers_point(local_point): return Vector2i(-1,-1)
	for index in range(blocks.size()-1,-1,-1):
		var block := blocks[index]
		if block.support.rect.has_point(local_point) and block.covers(local_point): return block.cell
	return Vector2i(-1,-1)

func press(cell: Vector2i) -> void:
	pressed_cell=cell
	for block in blocks:
		if is_instance_valid(block): block.pressed=block.cell==cell

func cancel_press() -> void:
	press(Vector2i(-1,-1))
