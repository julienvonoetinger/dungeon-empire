extends Node2D
## Isolated comparison: current placement policy, new prepared crack art only.
const BASE := "res://docs/reference/isometric-decoration-review/v2-edge-cracks/"

class SurfaceStudy extends "res://scripts/wireframe_cell_study.gd":
	var proposal := true
	var crack_entries: Dictionary = {}
	var crack_textures: Dictionary = {}
	const REPLACEMENTS := {"crack-short":"corner-split", "crack-branch":"vertical-hairline", "crack-corrupt":"edge-fork"}

	func _ready() -> void:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"prepared.json"))
		var atlas := ImageTexture.create_from_image(Image.load_from_file("res://"+str(data.atlas.file)))
		for entry: Dictionary in data.entries:
			crack_entries[entry.id] = entry
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(entry.region[0],entry.region[1],entry.region[2],entry.region[3])
			texture.filter_clip = true
			crack_textures[entry.id] = texture
		super._ready()

	func _draw_part(part: Dictionary, layer: int) -> void:
		var entry: Dictionary = _definition.get("entries")[part.id]
		var detail: Dictionary = entry.get("surface_detail", {})
		if not proposal or detail.is_empty() or not REPLACEMENTS.has(detail.motif):
			super._draw_part(part,layer)
			return
		var id: String = REPLACEMENTS[detail.motif]+"-"+str(detail.surface)
		var revised: Dictionary = crack_entries[id]
		var sprite := Sprite2D.new()
		sprite.name = "Proposal_"+id.replace("-","_")
		sprite.texture = crack_textures[id]
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.position = grid_to_local(part.at)+Vector2(revised.offset[0],revised.offset[1])
		sprite.z_index = layer
		_world.add_child(sprite)

var study: SurfaceStudy

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
	study.surface_details = true
	add_child(study)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2.ONE*.75
	camera.position = study.grid_to_local(Vector2(1.5,1))
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		study.proposal = not study.proposal
		study.refresh_preview(false)
