extends "res://docs/reference/treasury-review/v9-sprite-unique/renderer.gd"
## Fixed-camera art. Select on every topology rebuild, including changes within a side.
const ART := "res://docs/reference/treasury-review/v11-couloir/"
const ROOM_ORIGIN := Vector2i(6,6)
const SIDES := ["N","E","S","W"]
const OUTWARD := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
var entrance: Dictionary = {}
var page: Texture2D
var registrations: Dictionary
var variants: Dictionary = {}

static func entrance_of(floor_cells: Dictionary,room: Vector2i) -> Dictionary:
	for y in 2:
		for x in 2:
			if not floor_cells.has(room+Vector2i(x,y)):return {}
	var result := {}
	for i in SIDES.size():
		for slot in 2:
			var edge := Vector2i(slot,0) if i==0 else Vector2i(1,slot) if i==1 else Vector2i(slot,1) if i==2 else Vector2i(0,slot)
			if floor_cells.has(room+edge+OUTWARD[i]):
				if not result.is_empty():return {}
				result={"side":SIDES[i],"slot":slot,"inward":-Vector2(OUTWARD[i]),"axis":Vector2.RIGHT if i%2==0 else Vector2.DOWN}
	return result

func render_plan(plan: Dictionary,specials: Dictionary,pillar_details: bool,reload_textures := true) -> void:
	entrance=entrance_of(plan.cells,ROOM_ORIGIN)
	if not entrance.is_empty():
		# The two mouths on one side share the facing, with a lateral offset
		# away from the actual slot. Everything remains on the same world grid.
		anchor=Vector2(ROOM_ORIGIN)+Vector2.ONE+entrance.inward*.10+entrance.axis*(.055 if entrance.slot==0 else -.055)
		var along_x: bool=entrance.side=="N" or entrance.side=="S"
		support_half=Vector2(.84,.81) if along_x else Vector2(.81,.84)
	super.render_plan(plan,specials,pillar_details,reload_textures)

func _load_hoard() -> bool:
	if entrance.is_empty():
		tex=null
		return false
	if page==null:
		var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ART+"atlas.json"))
		registrations=meta.regions
		var img:=Image.load_from_file(ART+str(meta.file))
		assert(img!=null and not img.is_empty())
		img.generate_mipmaps()
		page=ImageTexture.create_from_image(img)
	var side: String=entrance.side
	var data: Dictionary=registrations[side]
	if not variants.has(side):
		var selected:=AtlasTexture.new()
		selected.atlas=page
		selected.region=Rect2(data.rect[0],data.rect[1],data.rect[2],data.rect[3])
		selected.filter_clip=true
		variants[side]=selected
	tex=variants[side]
	ground_pin=Vector2(data.pivot[0],data.pivot[1])
	return true
