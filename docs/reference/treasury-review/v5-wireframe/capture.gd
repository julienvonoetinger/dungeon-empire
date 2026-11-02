extends "res://docs/reference/treasury-review/v3-salle-ouverte/capture.gd"
const REVIEW := "res://docs/reference/treasury-review/v5-wireframe/"
const Wire = preload("res://docs/reference/treasury-review/v5-wireframe/renderer.gd")
var failures: Array[String] = []
var checked := 0
var review_points := {}
var cam: Camera2D

func check(condition: bool, message: String) -> void:
	checked += 1
	if not condition:
		failures.append(message)

func make_view() -> Node2D:
	return Wire.new()

func review_directory() -> String:
	return REVIEW

func capture() -> void:
	stage.size = Vector2i(900,600)
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var game := IsometricGameSession.new()
	game.persistence_enabled = false
	var terrain := Terrain.new()
	game.add_child(terrain)
	terrain.owner = game
	view = make_view()
	game.add_child(view)
	stage.add_child(game)
	game.set_process(false)
	cam = Camera2D.new()
	stage.add_child(cam)
	cam.zoom = Vector2.ONE * 1.05
	cam.position = view.grid_to_local(CENTER) + Vector2(0,-44)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REVIEW+"layouts.json"))
	DirAccess.make_dir_recursive_absolute(review_directory()+"vues")
	for row: Dictionary in data.rows:
		var cells := {}
		game.sim.new_map()
		for p in ROOM:
			game.sim.grid[p.y][p.x] = Types.Tile.VAULT
			cells[p] = true
		for outside: Array in row.passage:
			var p := Vector2i(6+outside[0],6+outside[1])
			game.sim.grid[p.y][p.x] = Types.Tile.FLOOR
			cells[p] = true
		game.changed.emit(true)
		var plan := {"cells":cells,"openings":{},"wall_variants":false,"floor_variants":true}
		view.layout = {}
		view.render_plan(plan,{},true,false)
		await save(row.id+"-kit")
		view.layout = row
		view.render_plan(plan,{},true,false)
		check(view.replaced.size()==4,row.id+" three wall segments and one corner post matched native hosts")
		check(view.painted.size()==3,row.id+" only two vaults and their connecting corner post rendered")
		for cell in ROOM:
			var center := Vector2(cell)+Vector2(.5,.5)
			for obj: Dictionary in row.objects:
				var shape := Rect2(Vector2(6+obj.min[0],6+obj.min[1]),Vector2(obj.max[0]-obj.min[0],obj.max[1]-obj.min[1]))
				check(not shape.has_point(center),row.id+" floor stays flat and free for the future coin texture")
		var mouth_local := Vector2(row.passage[0][0],row.passage[0][1])+Vector2(6.5,6.5)
		var inside := Vector2(0,1) if row.side=="N" else Vector2(-1,0) if row.side=="E" else Vector2(0,-1) if row.side=="S" else Vector2(1,0)
		var threshold := mouth_local+inside*.5
		var tangent := Vector2(-inside.y,inside.x)
		var contacts: Array = []
		for i in row.bays.size():
			var b: Dictionary = row.bays[i]
			var art: Dictionary = row.objects[i]
			var horizontal: bool = b.side in ["N","S"]
			var lo := 100.0
			var hi := -100.0
			for host in view.replaced:
				if not str(host.id).begins_with("wall-h" if horizontal else "wall-v"):
					continue
				lo = minf(lo,host.min.x if horizontal else host.min.y)
				hi = maxf(hi,host.max.x if horizontal else host.max.y)
				var perp := 1 if horizontal else 0
				check(is_equal_approx(host.min[perp],6+float(art.min[perp])) and is_equal_approx(host.max[perp],6+float(art.max[perp])),row.id+" matches native wall thickness/line")
			var axis := 0 if horizontal else 1
			check(is_equal_approx(lo,6+float(art.min[axis])) and is_equal_approx(hi,6+float(art.max[axis])),row.id+" bay terminates exactly at native host ends")
			var transverse := .5*(float(art.min[1-axis])+float(art.max[1-axis]))+6
			for u: float in [lo,hi]:
				var p := Vector2(u,transverse) if horizontal else Vector2(transverse,u)
				contacts.append(px(p,data.wallHeight))
		for item: Dictionary in row.objects:
			var support := Rect2(Vector2(6+item.min[0],6+item.min[1]),Vector2(item.max[0]-item.min[0],item.max[1]-item.min[1]))
			# A strip 0.70 cell wide crosses the exact mouth and extends into the room.
			for offset: float in [-.35,0.,.35]:
				for depth in range(0,11):
					check(not support.has_point(threshold+tangent*offset+inside*(depth*.05-.1)),row.id+" central approach free")
		await save(row.id)
		review_points[row.id]={"joints":contacts,"mouth":px(threshold,.01)}
	var f := FileAccess.open(review_directory()+"verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checked,"perimeterMasks":data.perimeterMasks,"failures":failures,"views":review_points},"\t")+"\n")
	f.close()
	for issue in failures: push_error(issue)
	print("%d native geometry checks, %d failures." % [checked,failures.size()])
	quit(1 if not failures.is_empty() else 0)

func px(grid: Vector2,z: float) -> Array:
	var p: Vector2 = view.get_global_transform_with_canvas() * view.grid_to_local(grid,z)
	return [snappedf(p.x,.1),snappedf(p.y,.1)]

func save(title: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(stage.get_texture().get_image().save_webp(review_directory()+"vues/"+title+".webp",false)==OK,"save "+title)
