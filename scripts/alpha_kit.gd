@tool
extends RefCounted

## All regions select COMPLETE generated sprites, including transparent margins.
## Body rectangles measure placement only; they never crop or mask the texture.
const ROOT := "res://assets/dungeon/alpha-kit/"
const SHEETS := {
	"units":["wall-units-v2.png",Vector2(1774,887)],
	"blocks":["wall-blocks-v2.png",Vector2(1402,1122)],
	"short_caps":["short-caps-v2.png",Vector2(2172,724)],
	"floors":["floors.png",Vector2(1448,1086)],
	"piers":["piers-v2.png",Vector2(2079,756)],
	"tall":["facades-v2.png",Vector2(1536,1024)],
	"door":["entrance.png",Vector2(1195,1316)],
	"heart":["heart.png",Vector2(1269,1239)]
}
const PARTS := {
	"north0":["units",Rect2(0,0,887,887),Rect2(148,197,684,580)],
	"north1":["units",Rect2(887,0,887,887),Rect2(938,196,685,580)],
	"south0":["units",Rect2(0,0,887,887),Rect2(148,197,684,580)],
	"south1":["units",Rect2(887,0,887,887),Rect2(938,196,685,580)],
	"west":["blocks",Rect2(0,0,701,365),Rect2(348,70,264,253)],
	"east":["blocks",Rect2(701,0,701,365),Rect2(790,70,264,253)],
	"short_west":["short_caps",Rect2(0,0,1086,724),Rect2(91,273,922,212)],
	"short_east":["short_caps",Rect2(1086,0,1086,724),Rect2(1157,273,924,210)],
	"edge_west":["blocks",Rect2(0,365,701,455),Rect2(400,410,162,374)],
	"edge_east":["blocks",Rect2(701,365,701,455),Rect2(840,410,166,374)],
	"edge_short_west":["blocks",Rect2(0,820,701,302),Rect2(383,862,196,193)],
	"edge_short_east":["blocks",Rect2(701,820,701,302),Rect2(824,861,195,193)],
	"wide0":["floors",Rect2(0,0,724,350),Rect2(278,44,389,259)],
	"wide1":["floors",Rect2(724,0,724,350),Rect2(783,44,388,259)],
	"square0":["floors",Rect2(0,350,724,340),Rect2(335,386,281,274)],
	"square1":["floors",Rect2(724,350,724,340),Rect2(833,386,281,274)],
	"narrow0":["floors",Rect2(0,690,724,396),Rect2(379,719,198,318)],
	"narrow1":["floors",Rect2(724,690,724,396),Rect2(869,718,202,318)],
	"low":["piers",Rect2(416,0,416,756),Rect2(515,244,232,368)],
	"medium":["piers",Rect2(416,0,416,756),Rect2(515,244,232,368)],
	"buttress":["piers",Rect2(832,0,416,756),Rect2(918,158,221,503)],
	"joined":["piers",Rect2(1248,0,416,756),Rect2(1315,104,220,557)],
	"entry_pier":["piers",Rect2(1664,0,415,756),Rect2(1719,52,216,638)],
	"tall0":["tall",Rect2(0,630,768,394),Rect2(86,673,633,283)],
	"tall1":["tall",Rect2(768,630,768,394),Rect2(817,673,635,283)],
	"door":["door",Rect2(0,0,1195,1316),Rect2(115,114,967,1061)],
	"heart":["heart",Rect2(0,0,1269,1239),Rect2(295,322,680,724)]
}
static var _textures: Dictionary = {}

static func size_at_width(id: String,width: float) -> Vector2:
	var body: Rect2 = PARTS[id][2]
	return body.size*(width/body.size.x)

static func width_at_height(id: String,height: float) -> float:
	var body: Rect2 = PARTS[id][2]
	return height*body.size.x/body.size.y

static func make(id: String,width: float) -> Sprite2D:
	var def: Array = PARTS[id]
	var sheet: Array = SHEETS[def[0]]
	var image: Texture2D = load(ROOT+sheet[0])
	var factor: Vector2 = image.get_size()/sheet[1]
	var region: Rect2 = def[1]
	var body: Rect2 = def[2]
	if not _textures.has(id):
		var texture := AtlasTexture.new()
		texture.atlas = image
		texture.region = Rect2(region.position*factor,region.size*factor)
		texture.filter_clip = true
		_textures[id] = texture
	var sprite := Sprite2D.new()
	sprite.texture = _textures[id]
	sprite.centered = false
	sprite.offset = -(body.position-region.position)*factor
	# Imports keep the original dimensions; render scale is strictly uniform.
	sprite.scale = Vector2.ONE*(width/(body.size.x*factor.x))
	sprite.set_meta("asset_id",id)
	sprite.set_meta("source_region",sprite.texture.region)
	sprite.set_meta("source_path",image.resource_path)
	sprite.set_meta("body_size",size_at_width(id,width))
	return sprite
