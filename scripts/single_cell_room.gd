@tool
extends Node2D

## Fixed 1x1 room study matching the concept art: north wall (cap row over a
## two-course face), south wall (cap row over a one-course exterior face) and
## two side columns of cap blocks with their dark outer flank. All four wall
## modules come from ONE native-alpha generation (walls.png), so they share one
## uniform scale, stone size and light. Slots keep their transparent gutters;
## anchors are measured sheet points, never masks.
signal rebuilt
const KIT := preload("res://scripts/alpha_kit.gd")
const VARIATION := preload("res://scripts/stone_variation.gd")
const SHEET := preload("res://assets/dungeon/alpha-kit/walls.png")
const CELL := 96.0
# Gap between the north A corner blocks (sheet x 188..485) spans one cell.
const WALL_SCALE := CELL / 297.0
const FLOOR_TINT := Color(0.80, 0.83, 0.90, 1)
# [complete slot, sheet anchor, room anchor]. X anchors are the midpoint between
# corner-block inner edges (horizontal walls) or the cap block inner edge (sides).
const PARTS := {
	"north_a": [Rect2(0, 0, 649, 397), Vector2(336.5, 354), Vector2(48, 2)],
	"north_b": [Rect2(649, 0, 650, 397), Vector2(959.5, 354), Vector2(48, 2)],
	# The front wall reuses the horizontal modules: the sheet's own south pieces
	# space their corner blocks 350 px apart and could not align with the side
	# columns. Its two-course face is the exterior face seen from the camera.
	"south_a": [Rect2(0, 0, 649, 397), Vector2(336.5, 101), Vector2(48, 92)],
	"south_b": [Rect2(649, 0, 650, 397), Vector2(959.5, 100), Vector2(48, 92)],
	"west": [Rect2(0, 688, 649, 523), Vector2(432, 723), Vector2(0, -44)],
	"east": [Rect2(649, 688, 650, 523), Vector2(866, 722), Vector2(CELL, -44)],
}
# Measured sheet x of the corner-block / cap-column inner outlines, plus the
# sheet y where each horizontal cap row ends. Used only to verify joints.
const JOINTS := {
	"north_a": [188.0, 485.0, 212.0], "north_b": [805.0, 1114.0, 213.0],
	"south_a": [188.0, 485.0, 212.0], "south_b": [805.0, 1114.0, 213.0],
	"west": [432.0], "east": [866.0],
}

@export var layout: DungeonLayout
@export var stone_variation := true
@export var variation_seed := 173
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable = refresh_preview
var _surfaces: Array[Sprite2D] = []
var _textures: Dictionary = {}
var _pending := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build()

func get_content_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(416, 416))

func get_surface_pieces() -> Array[Sprite2D]:
	return _surfaces.duplicate()

func get_torch_sprites() -> Array[Sprite2D]:
	return []

func get_wall_metrics() -> Dictionary:
	# Cap row depth (sheet 102..212) is shared by both horizontal walls.
	return {"cap": 110.0 * WALL_SCALE, "side": 106.0 * WALL_SCALE, "scale": WALL_SCALE}

func refresh_preview() -> void:
	if is_inside_tree() and not _pending:
		_pending = true
		_build.call_deferred()

func _register(part: Sprite2D, label: String, kind: String, at: Vector2, layer: int) -> Sprite2D:
	part.name = label
	part.position = at
	part.z_index = layer
	part.set_meta("kind", kind)
	add_child(part)
	_surfaces.append(part)
	return part

func _floor(id: String, width: float, label: String, at: Vector2, layer: int) -> Sprite2D:
	return _register(KIT.make(id, width), label, "floor", at, layer)

func _wall(id: String, label: String, origin: Vector2, layer: int) -> Sprite2D:
	var slot: Rect2 = PARTS[id][0]
	var anchor: Vector2 = PARTS[id][1]
	if not _textures.has(id):
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = slot
		texture.filter_clip = true
		_textures[id] = texture
	var part := Sprite2D.new()
	part.texture = _textures[id]
	part.centered = false
	part.offset = -(anchor - slot.position)
	part.scale = Vector2.ONE * WALL_SCALE
	part.set_meta("asset_id", id)
	part.set_meta("source_path", SHEET.resource_path)
	part.set_meta("source_region", slot)
	part.set_meta("body_size", slot.size * WALL_SCALE)
	part.set_meta("sheet_anchor", anchor)
	part.set_meta("joints", JOINTS[id])
	return _register(part, label, "wall", origin + PARTS[id][2], layer)

func _build() -> void:
	_pending = false
	for part in _surfaces:
		remove_child(part)
		part.queue_free()
	_surfaces.clear()
	if not layout or layout.get_grid_size() != Vector2i.ONE or layout.cell_size != 96 or layout.margin != 160 or not layout.has_floor(Vector2i.ZERO) or layout.entrance_enabled:
		push_warning("SingleCellRoom supports only its closed 96 px cell fixture.")
		return
	var origin := Vector2(160, 160)
	var bed := _floor("square0", 112, "FloorBed", origin - Vector2(8, 8), 0)
	bed.self_modulate = Color(0.50, 0.53, 0.60, 1)
	var variant := VARIATION.choose(0, 0, variation_seed, 11, 2) if stone_variation else 0
	var floor_part := _floor("square" + str(variant), CELL, "Floor", origin, 1)
	floor_part.self_modulate = FLOOR_TINT * (VARIATION.floor_tint(0, 0, variation_seed) if stone_variation else Color.WHITE)
	# Front and rear always use different variants so the two walls never repeat.
	var pick := VARIATION.choose(0, -1, variation_seed, 23, 2) if stone_variation else 0
	var north := "north_" + "ab"[pick]
	var south := "south_" + "ab"[1 - pick]
	# Draw order: rear wall, then side columns over its face ends, then the
	# front wall whose caps and exterior face pass over the column feet.
	_wall(north, "North", origin, 2)
	_wall("west", "West", origin, 3)
	_wall("east", "East", origin, 3)
	_wall(south, "South", origin, 4)
	queue_redraw()
	rebuilt.emit()

func _draw() -> void:
	draw_rect(get_content_rect(), Color("080e19"))
