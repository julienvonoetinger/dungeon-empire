@tool
extends Node2D
signal rebuilt
const KIT := preload("res://scripts/alpha_kit.gd")
const TORCH := preload("res://scenes/DungeonTorch.tscn")
const VARIATION := preload("res://scripts/stone_variation.gd")
const SIDE := 68.0
const NORTH_HEIGHT := 117.0
const SOUTH_HEIGHT := 101.0
@export var layout: DungeonLayout
@export_group("Stone materials")
@export var stone_variation: bool = true
@export var variation_seed: int = 173
@export_tool_button("Actualiser le rendu", "Reload") var refresh_action: Callable = refresh_preview
var _surfaces: Array[Sprite2D] = []
var _torches: Array[Sprite2D] = []
var _lights: Array[PointLight2D] = []
var _side_runs: Array[Dictionary] = []
var _preview_signature: int = -1
var _preview_elapsed := 0.0
var _rebuild_pending := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rebuild()
	set_process(Engine.is_editor_hint())

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	_preview_elapsed += delta
	if _preview_elapsed >= 0.5:
		_preview_elapsed = 0.0
		if _get_preview_signature() != _preview_signature:
			refresh_preview()

func _get_preview_signature() -> int:
	var kit_script: Script = KIT
	var variation_script: Script = VARIATION
	var values: Array = [get_script().source_code,kit_script.source_code,variation_script.source_code,TORCH.get("_bundled"),stone_variation,variation_seed]
	if layout:
		values.append_array([layout.get_script().source_code,layout.cell_size,layout.margin,layout.rows,layout.entrance_enabled,layout.entrance_cell,layout.entrance_side])
	return hash(values)

func refresh_preview() -> void:
	if is_inside_tree() and not _rebuild_pending:
		_rebuild_pending = true
		_refresh_deferred.call_deferred()

func _refresh_deferred() -> void:
	_rebuild_pending = false
	if is_inside_tree():
		_rebuild()

func get_content_rect() -> Rect2:
	return Rect2(Vector2.ZERO,layout.get_pixel_size()) if layout else Rect2()

func get_surface_pieces() -> Array[Sprite2D]:
	return _surfaces.duplicate()

func get_torch_sprites() -> Array[Sprite2D]:
	return _torches.duplicate()

func get_wall_metrics() -> Dictionary:
	return {"north":NORTH_HEIGHT,"south":SOUTH_HEIGHT,"side":SIDE,"buttress":76,"exterior":24,"west":90,"east":90}

func cell_position(cell: Vector2i) -> Vector2:
	return Vector2(cell*layout.cell_size)+Vector2.ONE*layout.margin

func _rebuild() -> void:
	for child in get_children():
		var legacy: bool = child is Polygon2D and child.get_meta("kind","") in ["floor","wall","pier","entrance"]
		if child.owner == null and (child.get_meta("dungeon_generated",false) or legacy):
			remove_child(child)
			child.queue_free()
	_surfaces.clear()
	_torches.clear()
	_lights.clear()
	_side_runs.clear()
	_preview_signature = _get_preview_signature() if Engine.is_editor_hint() else -1
	if layout:
		_build_floors()
		_build_horizontal_walls()
		_build_vertical_walls()
		_build_corners()
		_build_wall_cores()
		_build_exterior_edges()
		_build_entrance()
	queue_redraw()
	rebuilt.emit()

func _piece(id: String,kind: String,position_: Vector2,width: float,z: int,label: String = "") -> Sprite2D:
	var part := KIT.make(id,width)
	part.name = "%s_%d"%[id if label.is_empty() else label,_surfaces.size()]
	part.position = position_
	part.z_index = z
	part.light_mask = 2 if kind in ["floor","wall"] else 1
	part.set_meta("kind",kind)
	part.set_meta("dungeon_generated",true)
	if stone_variation and kind == "wall":
		part.self_modulate = VARIATION.wall_tint(position_,variation_seed)
	add_child(part)
	_surfaces.append(part)
	return part

func _choice(x: int,y: int,salt: int) -> int:
	return VARIATION.choose(x,y,variation_seed,salt,2) if stone_variation else 0

func _build_floors() -> void:
	# Whole overlapping substrate sprites fill mortar. No calculated mask.
	for cell in layout.get_floor_cells():
		var bed := _piece("square0","floor",cell_position(cell)-Vector2(8,8),112,0,"FloorBed")
		bed.self_modulate = Color(0.50,0.53,0.60,1)
	var grid := layout.get_grid_size()
	for y in range(grid.y):
		var x := 0
		while x < grid.x:
			if not layout.has_floor(Vector2i(x,y)):
				x += 1
				continue
			var origin := cell_position(Vector2i(x,y))
			if layout.has_floor(Vector2i(x+1,y)):
				if y % 2 == 0:
					_floor("wide",origin-Vector2(3,3),144,x,y)
					_floor("narrow",origin+Vector2(136,-3),60,x+1,y)
				else:
					_floor("narrow",origin-Vector2(3,3),60,x,y)
					_floor("wide",origin+Vector2(52,-3),144,x+1,y)
				x += 2
			else:
				_floor("square",origin-Vector2(3,3),103,x,y)
				x += 1
	if _north_entrance_enabled():
		for x in range(1,8):
			_piece("square0","floor",cell_position(Vector2i(x,3))-Vector2(3,25),103,0,"EntryFloorBed")

func _floor(family: String,position_: Vector2,width: float,x: int,y: int) -> void:
	var part := _piece(family+str(_choice(x,y,11)),"floor",position_,width,1,"Floor")
	part.self_modulate = VARIATION.floor_tint(x,y,variation_seed) if stone_variation else Color.WHITE

func _build_horizontal_walls() -> void:
	var grid := layout.get_grid_size()
	for side: Vector2i in [Vector2i.UP,Vector2i.DOWN]:
		for y in range(grid.y):
			var x := 0
			while x < grid.x:
				if not _edge(Vector2i(x,y),side):
					x += 1
					continue
				var start := x
				while x < grid.x and _edge(Vector2i(x,y),side):
					x += 1
				var length := float((x-start)*layout.cell_size)
				var origin := cell_position(Vector2i(start,y))
				var tall := _north_entrance_enabled() and side == Vector2i.UP and y == 3 and start == 1
				if tall:
					var width := KIT.width_at_height("tall0",191)
					_piece("tall0","wall",origin+Vector2(-40,-191),width,2,"EntryWall")
					_piece("tall1","wall",origin+Vector2(length-width+40,-191),width,2,"EntryWall")
					continue
				var family := "north" if side == Vector2i.UP else "south"
				var height := NORTH_HEIGHT if side == Vector2i.UP else SOUTH_HEIGHT
				origin.y += -height if side == Vector2i.UP else float(layout.cell_size)
				var width := KIT.width_at_height(family+"0",height)
				var count := maxi(1,ceili((length-width)/(width-5))+1)
				for i in range(count):
					var offset := (length-width)*float(i)/float(count-1) if count > 1 else (length-width)*0.5
					var id := family+str(_choice(start+i,y,17))
					_piece(id,"wall",origin+Vector2(offset,0),width,2,family.capitalize())

func _build_vertical_walls() -> void:
	var grid := layout.get_grid_size()
	for side: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT]:
		for x in range(grid.x):
			var y := 0
			while y < grid.y:
				if not _edge(Vector2i(x,y),side):
					y += 1
					continue
				var start := y
				while y < grid.y and _edge(Vector2i(x,y),side):
					y += 1
				var origin := cell_position(Vector2i(x,start))+Vector2(-SIDE if side == Vector2i.LEFT else float(layout.cell_size),0)
				var room_length := float((y-start)*layout.cell_size)
				_side_runs.append({"core_x":origin.x,"start":origin.y,"end":origin.y+room_length,"west":side == Vector2i.LEFT})
				var pier_count := maxi(0,int((room_length-100)/320))
				for i in range(pier_count):
					var size_pier := KIT.size_at_width("buttress",76)
					var center := room_length*(i+1.0)/(pier_count+1.0)
					var p := Vector2(origin.x-4,origin.y+center-size_pier.y*0.5)
					var pier := _piece("buttress","pier",p,76,3,"SidePier")
					pier.set_meta("core_x",origin.x)

func _build_corners() -> void:
	var grid := layout.get_grid_size()
	var corners: Array[Dictionary] = []
	for y in range(grid.y+1):
		for x in range(grid.x+1):
			var vertex := Vector2i(x,y)
			var occupied: Array[bool] = [layout.has_floor(vertex+Vector2i(-1,-1)),layout.has_floor(vertex+Vector2i(0,-1)),layout.has_floor(vertex+Vector2i(-1,0)),layout.has_floor(vertex)]
			var count := occupied.count(true)
			if count != 1 and count != 3:
				continue
			var quadrant := occupied.find(false) if count == 3 else 3-occupied.find(true)
			var north := quadrant in [0,1]
			var west := quadrant in [0,2]
			var entry := _north_entrance_enabled() and y == 3 and x in [1,8]
			var origin := cell_position(vertex)+Vector2(-68 if west else 0,0)
			corners.append({"vertex":vertex,"origin":origin,"north":north,"west":west,"entry":entry})
	var joined: Array[int] = []
	for lower_index in range(corners.size()):
		var lower := corners[lower_index]
		if not lower.north or lower.entry or lower_index in joined:
			continue
		for upper_index in range(corners.size()):
			var upper := corners[upper_index]
			if upper.north or upper_index in joined or upper.vertex.x != lower.vertex.x or upper.west != lower.west:
				continue
			if upper.origin.y < lower.origin.y and upper.origin.y+101 > lower.origin.y-142:
				_piece("joined","pier",upper.origin-Vector2(0,6),68,3,"JoinedCorner")
				joined.append_array([upper_index,lower_index])
				break
	for i in range(corners.size()):
		if i in joined:
			continue
		var corner := corners[i]
		var id := "entry_pier" if corner.entry else ("medium" if corner.north else "low")
		var size := KIT.size_at_width(id,68)
		var origin: Vector2 = corner.origin+Vector2(0,-size.y if corner.north else -6)
		_piece(id,"pier",origin,68,3,"Corner")

func _build_wall_cores() -> void:
	var piers := _surfaces.filter(func(p): return p.get_meta("kind") == "pier")
	for run in _side_runs:
		var spans: Array[Vector2] = [Vector2(run.start,run.end)]
		for pier in piers:
			if absf(pier.get_meta("core_x",pier.position.x)-run.core_x) < 1:
				spans = _without_span(spans,Vector2(pier.position.y,pier.position.y+pier.get_meta("body_size").y))
		var id := "west" if run.west else "east"
		var height := KIT.size_at_width(id,SIDE).y
		var short_height := KIT.size_at_width("short_"+id,SIDE).y
		for span in spans:
			var length := span.y-span.x
			if length < short_height: continue
			var full_count := floori(length/height)
			var short_count := ceili(maxf(0,length-full_count*height)/short_height)
			if full_count > 0 and ((full_count+1)*height-length)/full_count <= 4:
				full_count += 1
				short_count = 0
			var count := full_count+short_count
			var overlap := (full_count*height+short_count*short_height-length)/maxi(1,count-1)
			var y: float = span.x
			for i in range(count):
				var selected := id if i < full_count else "short_"+id
				var core := _piece(selected,"wall",Vector2(run.core_x,y),SIDE,2,id.capitalize())
				core.set_meta("wall_layer","core")
				y += KIT.size_at_width(selected,SIDE).y-overlap

func _build_exterior_edges() -> void:
	# Independent backing only along exposed room-height spans. Whole sprites
	# stop before piers/facades; no alpha processing or source clipping is used.
	var blockers := _surfaces.filter(func(p): return p.get_meta("kind") == "pier" or (p.get_meta("kind") == "wall" and p.get_meta("wall_layer","") != "core"))
	for run in _side_runs:
		var edge_x: float = run.core_x-22 if run.west else run.core_x+SIDE-2
		var spans: Array[Vector2] = [Vector2(run.start,run.end)]
		for blocker in blockers:
			var rect := Rect2(blocker.position,blocker.get_meta("body_size"))
			var same_pier: bool = blocker.get_meta("kind") == "pier" and not str(blocker.name).begins_with("SidePier") and absf(rect.position.x-run.core_x) < 1
			var crossing_wall: bool = blocker.get_meta("kind") == "wall" and rect.position.x < edge_x+24 and rect.end.x > edge_x
			if same_pier or crossing_wall:
				spans = _without_span(spans,Vector2(rect.position.y,rect.end.y))
		for span in spans:
			var suffix := "west" if run.west else "east"
			var id := "edge_"+suffix
			var height := KIT.size_at_width(id,24).y
			if span.y-span.x < height:
				id = "edge_short_"+suffix
				height = KIT.size_at_width(id,24).y
			if span.y-span.x < height:
				continue
			var count := maxi(1,ceili((span.y-span.x-height)/(height-2))+1)
			for i in range(count):
				var offset := (span.y-span.x-height)*float(i)/float(count-1) if count > 1 else 0.0
				var edge := _piece(id,"wall",Vector2(edge_x,span.x+offset),24,1,"Exterior")
				edge.self_modulate = Color(0.43,0.46,0.55,1)
				edge.set_meta("wall_layer","exterior")
				edge.set_meta("core_x",run.core_x)
				edge.set_meta("exposed_span",span)

func _without_span(spans: Array[Vector2],block: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for span in spans:
		if block.y <= span.x or block.x >= span.y:
			result.append(span)
		else:
			if block.x > span.x: result.append(Vector2(span.x,block.x))
			if block.y < span.y: result.append(Vector2(block.y,span.y))
	return result

func _build_entrance() -> void:
	if not _north_entrance_enabled():
		return
	var door_size := KIT.size_at_width("door",216)
	_piece("door","entrance",Vector2(546,454)-Vector2(108,door_size.y),216,4,"EntryDoor")
	for side in range(2):
		var torch: Sprite2D = TORCH.instantiate()
		torch.name = "EntryTorchWest" if side == 0 else "EntryTorchEast"
		torch.position = Vector2(430+232*side,454)
		add_child(torch)
		_torches.append(torch)
		_add_torch_light(Vector2(430+232*side,375))

func _add_torch_light(location: Vector2) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	var glow := GradientTexture2D.new()
	glow.gradient = gradient
	glow.width = 384
	glow.height = 384
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5,0.5)
	glow.fill_to = Vector2(0.5,0)
	var light := PointLight2D.new()
	light.name = "TorchLight_%d"%_lights.size()
	light.position = location
	light.texture = glow
	light.color = Color("f02aff")
	light.energy = 1.5
	light.range_item_cull_mask = 2
	light.set_meta("dungeon_generated",true)
	add_child(light)
	_lights.append(light)

func _edge(cell: Vector2i,side: Vector2i) -> bool:
	return layout.has_floor(cell) and not layout.has_floor(cell+side)

func _north_entrance_enabled() -> bool:
	return layout.has_valid_entrance() and layout.entrance_side == DungeonLayout.WallSide.NORTH and layout.entrance_cell == Vector2i(3,3)

func _draw() -> void:
	if layout:
		draw_rect(get_content_rect(),Color("080e19"))
