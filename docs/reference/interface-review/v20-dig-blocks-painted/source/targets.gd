extends Control
## Isolated adapter for the existing one-shot pointer/Undo pipeline.
const Block=preload("res://scripts/dig_block_wireframe.gd")
const Sorter=preload("res://scripts/mobile_dungeon_renderer.gd")
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
	if hud.hint.visible: hud.hint.text="Tap a rock block to dig · 5 gold\nPainted preview · Drag to explore"

func refresh() -> void:
	if not is_instance_valid(_view): return
	var signature:=hash([_view.dig_cells,_view.solid_groups])
	if signature!=_signature:
		_signature=signature
		for block in blocks:
			if is_instance_valid(block) and not block.is_queued_for_deletion():
				block.get_parent().remove_child(block); block.queue_free()
		blocks.clear(); ordered=_view.solid_groups.duplicate()
		for cell in _view.dig_cells:
			var block:=Block.new()
			block.configure(_view,cell,height)
			_view._world.add_child(block)
			blocks.append(block); ordered.append(block.support)
		ordered=_sorter._ordered_parts(ordered)
		for part in ordered: _view._world.move_child(part.node,-1)
	for block in blocks: block.visible=_view.dig_guides_visible and hud.session.can_edit()

func hit_cell(point: Vector2) -> Vector2i:
	refresh()
	if not _view.dig_guides_visible or not hud.session.can_edit(): return Vector2i(-1,-1)
	var local_point: Vector2=_view.get_global_transform_with_canvas().affine_inverse()*(point*hud.scale.x)
	var world_point: Vector2=_view.to_global(local_point)
	# Status rings are above all solid parts, as in the native renderer.
	for item in _view._markers:
		var badge: Control=item.node.badge
		if is_instance_valid(badge) and badge.is_visible_in_tree():
			var q:=badge.get_global_transform().affine_inverse()*world_point
			if q.distance_to(badge.size*.5)<=badge.size.x*.5: return Vector2i(-1,-1)
	for index in range(ordered.size()-1,-1,-1):
		var part: Dictionary=ordered[index]
		if not part.rect.has_point(local_point): continue
		if part.has("dig_cell"):
			if part.node.visible and part.node.covers(local_point): return part.dig_cell
		else:
			if part.has("wall_segment"):
				var ground: Vector2=_view.local_to_grid(local_point)
				var origin:=Vector3(ground.x,ground.y,0)
				var direction: Vector3=_view._definition.get("view_direction")
				var entry: Vector3=(part.min-origin)/direction
				var exit_hit: Vector3=(part.max-origin)/direction
				if maxf(entry.x,maxf(entry.y,entry.z))>minf(exit_hit.x,minf(exit_hit.y,exit_hit.z)): continue
			if _view._opaque_at(part.node,world_point): return Vector2i(-1,-1)
	return Vector2i(-1,-1)

func press(cell: Vector2i) -> void:
	pressed_cell=cell
	for block in blocks:
		if is_instance_valid(block): block.pressed=block.cell==cell; block.queue_redraw()

func cancel_press() -> void:
	press(Vector2i(-1,-1))

func _exit_tree() -> void:
	_sorter.free()
