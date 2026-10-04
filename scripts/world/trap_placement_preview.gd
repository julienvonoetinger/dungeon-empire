extends Node3D

const TOOLS := {GameTypes.Tool.TRAP_SPIKE: GameTypes.Tile.SPIKE,
	GameTypes.Tool.TRAP_SNARE: GameTypes.Tile.SNARE, GameTypes.Tool.TRAP_VOID: GameTypes.Tile.VOID}
var _signature := ""

func sync(game: Node) -> void:
	var ui = game.mobile_ui
	visible = ui != null and TOOLS.has(ui.tool) and game._inside(ui.selected) and not game.raid_active and not ui.modal.visible
	if not visible:
		return
	var cell: Vector2i = ui.selected
	visible = int(game.grid[cell.y][cell.x]) != GameTypes.Tile.ROCK
	if not visible:
		return
	var tile: int = TOOLS[ui.tool]
	var signature := "%s:%d" % [cell, tile]
	if signature == _signature:
		return
	_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var floor_mesh := preload("res://scripts/world/floor_renderer.gd").new()
	floor_mesh.name = "PreviewFloor"
	floor_mesh.mobile_mode = true
	add_child(floor_mesh)
	var cells: Array[Vector2i] = [cell]
	var empty: Array[Vector2i] = []
	floor_mesh.sync_cells(cells, 1.0, empty, empty, empty,
		cells if tile == GameTypes.Tile.SPIKE else empty,
		cells if tile == GameTypes.Tile.SNARE else empty,
		cells if tile == GameTypes.Tile.VOID else empty)
	var mechanism := Node3D.new()
	mechanism.name = "Mechanism"
	mechanism.position = Vector3(cell.x, 0, cell.y)
	add_child(mechanism)
	preload("res://scripts/world/mobile_surfaces.gd").trap(mechanism, tile, false, false)
	# Lift only enough to avoid fighting the existing floor; the footprint is unchanged.
	position.y = 0.008
	_make_translucent(self)

func _make_translucent(node: Node) -> void:
	if node is GeometryInstance3D:
		node.transparency = 0.25
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_make_translucent(child)
