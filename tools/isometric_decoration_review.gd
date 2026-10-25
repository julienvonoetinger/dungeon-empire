extends Node2D
## Isolated appearance review; shared production geometry/art stay unchanged.
const BASE := "res://docs/reference/isometric-decoration-review/v1/"

class SurfaceStudy extends "res://scripts/wireframe_cell_study.gd":
	var damage_entries: Dictionary = {}
	var damage_textures: Dictionary = {}
	var decoration_enabled := true
	var motif_override := ""
	var placements := {
		"floor": {Vector2i(0,0):"crack-short",Vector2i(0,1):"crack-branch",Vector2i(2,1):"chip-worn",Vector2i(1,4):"crack-short",Vector2i(4,1):"crack-corrupt"},
		"wall-h": {Vector2i(0,0):"crack-short",Vector2i(2,0):"chip-worn",Vector2i(3,1):"crack-branch",Vector2i(5,2):"crack-corrupt"},
		"wall-v": {Vector2i(0,0):"crack-branch",Vector2i(1,4):"chip-worn",Vector2i(2,3):"crack-short"}
	}

	func _ready() -> void:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"prepared.json"))
		var atlas := ImageTexture.create_from_image(Image.load_from_file("res://"+str(data.atlas.file)))
		for entry: Dictionary in data.entries:
			damage_entries[entry.id] = entry
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(entry.region[0],entry.region[1],entry.region[2],entry.region[3])
			texture.filter_clip = true
			damage_textures[entry.id] = texture
		super._ready()

	func _draw_part(part: Dictionary, layer: int) -> void:
		super._draw_part(part,layer)
		if not decoration_enabled:
			return
		var surface := "floor" if part.id == "floor" else "wall-h" if str(part.id).begins_with("wall-h-") else "wall-v" if str(part.id).begins_with("wall-v-") else ""
		if surface.is_empty() or not placements[surface].has(Vector2i(part.at)):
			return
		var motif: String = placements[surface][Vector2i(part.at)] if motif_override.is_empty() else motif_override
		var id := motif+"-"+surface
		var entry: Dictionary = damage_entries[id]
		var sprite := Sprite2D.new()
		sprite.name = "Detail_"+id.replace("-","_")
		sprite.texture = damage_textures[id]
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.position = grid_to_local(part.at)+Vector2(entry.offset[0],entry.offset[1])
		sprite.z_index = layer
		# Immediately after the host, before any solid drawn in front of it. The
		# decal receives the same lights and has no autonomous shadow or volume.
		_world.add_child(sprite)

var study: SurfaceStudy
var camera: Camera2D
var _dragging := false

func _ready() -> void:
	study = SurfaceStudy.new()
	study.name = "Dungeon"
	study.layout = load("res://scripts/dungeon_layout.gd").new()
	study.layout.rows = PackedStringArray(["000","000"])
	study.connections = 6
	study.corridor_length = 3
	study.vertical_corridor_length = 4
	study.close_corridor_ends = true
	study.heart_positions = PackedVector2Array([Vector2(1.5,1)])
	study.torch_north_cells = [Vector2i(1,0)]
	study.torch_west_cells = [Vector2i(0,1)]
	add_child(study)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2.ONE*.75
	camera.position = study.grid_to_local(Vector2(1.5,1))
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		study.decoration_enabled = not study.decoration_enabled
		study.refresh_preview(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		camera.position -= event.relative/camera.zoom
	elif event is InputEventScreenDrag:
		camera.position -= event.relative/camera.zoom
