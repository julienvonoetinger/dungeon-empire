extends "res://docs/reference/treasury-review/v9-sprite-unique/capture.gd"
const Oriented = preload("res://docs/reference/treasury-review/v11-couloir/renderer.gd")
var seen := {}
var page_id := 0

func make_view() -> Node2D:
	return Oriented.new()

func review_directory() -> String:
	return "res://docs/reference/treasury-review/v11-couloir/"

func capture() -> void:
	# An enclosed or multiply connected room must never receive a direction
	# left over from an earlier render. Diagonal rock/corridors are irrelevant.
	var neighbors := [Vector2i(6,5),Vector2i(7,5),Vector2i(8,6),Vector2i(8,7),Vector2i(6,8),Vector2i(7,8),Vector2i(5,6),Vector2i(5,7)]
	for mask in 256:
		var cells := {Vector2i(5,5):true}
		for p in ROOM: cells[p]=true
		var n := 0
		for i in 8:
			if mask & (1<<i):
				cells[neighbors[i]]=true
				n+=1
		assert(Oriented.entrance_of(cells,Vector2i(6,6)).is_empty()==(n!=1))
	await super.capture()

func check_placement(row: Dictionary,inward: Vector2) -> void:
	assert(view.draw_count==1 and view.entrance.side==row.side and view.entrance.slot==row.slot)
	var tex: AtlasTexture=view.tex
	var r: Array=view.registrations[row.side].rect
	assert(tex.region==Rect2(r[0],r[1],r[2],r[3]))
	if page_id==0:page_id=tex.atlas.get_instance_id()
	assert(page_id==tex.atlas.get_instance_id())
	if seen.has(row.side):
		assert(seen[row.side].tex==tex.get_instance_id())
		assert((view.anchor-seen[row.side].anchor).dot(view.entrance.axis)<-.10)
	else:
		for previous: Dictionary in seen.values():assert(previous.tex!=tex.get_instance_id())
		seen[row.side]={"tex":tex.get_instance_id(),"anchor":view.anchor}
	var half: Vector2=view.support_half
	assert((view.anchor-CENTER).dot(inward)+1.0-half.dot(inward.abs())>=.28)
	assert((view.anchor-CENTER).abs().x+half.x<.92 and (view.anchor-CENTER).abs().y+half.y<.92)
