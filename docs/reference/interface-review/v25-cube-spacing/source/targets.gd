extends Control
## Isolated adapter for the existing one-shot pointer/Undo pipeline.
const Block=preload("res://scripts/dig_rock_target.gd")
const Sorter=preload("res://scripts/mobile_dungeon_renderer.gd")
const Layout=preload("res://scripts/dig_target_layout.gd")
const Geometry=preload("res://scripts/game/terrain_geometry.gd")
var hud: CanvasLayer
var blocks: Array[Node2D] = []
var ordered: Array[Dictionary] = []
var height := 0.0
var pressed_cell := Vector2i(-1,-1)
var _sorter:=Sorter.new()
var _view: Node2D
var _signature := 0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_view=hud.session.get_node("PlayArea/World/Dungeon")
	height=float(_view._definition.get("entries")["wall-h-0"].bounds.max[2])
	hud.session.changed.connect(func(_structure): _signature=0; refresh())
	refresh()

func _process(_delta: float) -> void:
	refresh()
	if hud.hint.visible: hud.hint.text="Tap a pickaxe to dig · 5 gold\nDrag to explore"

func refresh() -> void:
	if not is_instance_valid(_view): return
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
		for part in ordered: _view._world.move_child(part.node,-1)
	for block in blocks: block.visible=_view.dig_guides_visible and hud.session.can_edit()

func hit_cell(point: Vector2) -> Vector2i:
	refresh()
	if not _view.dig_guides_visible or not hud.session.can_edit(): return Vector2i(-1,-1)
	var local_point: Vector2=_view.get_global_transform_with_canvas().affine_inverse()*(point*hud.scale.x)
	# Guides must never turn a masonry or status-seal pixel into a paid action.
	if _view.solid_covers_point(local_point): return Vector2i(-1,-1)
	for index in range(ordered.size()-1,-1,-1):
		var part: Dictionary=ordered[index]
		if not part.rect.has_point(local_point): continue
		if part.has("dig_cell"):
			if part.node.visible and part.node.covers(local_point): return part.dig_cell
	return Vector2i(-1,-1)

func press(cell: Vector2i) -> void:
	pressed_cell=cell
	for block in blocks:
		if is_instance_valid(block): block.pressed=block.cell==cell; block.queue_redraw()

func cancel_press() -> void:
	press(Vector2i(-1,-1))

func _exit_tree() -> void:
	_sorter.free()
