extends "res://scripts/mobile_dungeon_renderer.gd"

const Marker = preload("res://scripts/game/game_marker.gd")
const Types = preload("res://scripts/game/game_types.gd")
const ChestOrientation = preload("res://scripts/game/chest_orientation.gd")
# Stair suffixes name the low, open side, not the wall behind the top step.
const ENTRANCE_OPEN_SIDES := {
	Vector2i.UP: "north", Vector2i.RIGHT: "east",
	Vector2i.DOWN: "south", Vector2i.LEFT: "west",
}
var session: IsometricGameSession
var solid_groups: Array[Dictionary] = []
var _paint_order: Array[Dictionary] = []
var _paint_cursor := 0
var _last_group: Node2D
var _markers: Array[Dictionary] = []
var _trap_visuals: Array[Dictionary] = []
var _trap_triggers: Dictionary = {}
var _actor: Node2D
var _actor_at := Vector2(INF, INF)
var chest_facings: Dictionary = {}
var _overlay: Node2D
var _placement_cell := Vector2i(-1,-1)
var _placement_valid := false
var access_visible := false:
	set(value):
		access_visible=value
		if is_instance_valid(_floor_guide): _floor_guide.queue_redraw()
var _valid_cells: Array[Vector2i] = []
var _floor_guide: Node2D

func _ready() -> void:
	session = owner as IsometricGameSession
	session.changed.connect(_on_change)
	session.frame_updated.connect(_update_markers)
	session.raid.trap_activated.connect(_on_trap_activated)
	get_tree().root.size_changed.connect(_update_markers)
	_floor_guide=Node2D.new(); _floor_guide.name="GroundGuide"; add_child(_floor_guide)
	_floor_guide.draw.connect(_draw_ground_guide)
	_overlay=Node2D.new()
	_overlay.name="PlacementGuide"
	_overlay.z_index=5
	add_child(_overlay)
	_overlay.draw.connect(_draw_guide)

func _on_change(structure: bool) -> void:
	if structure: rebuild()
	_valid_cells.clear()
	if session.can_edit() and session.sim._has_core() and session.tool!=Types.Tool.NONE:
		for y in Types.ROWS:
			for x in Types.COLS:
				var cell:=Vector2i(x,y)
				if session.sim.grid[y][x] in [Types.Tile.FLOOR,Types.Tile.ROCK] and session.check_action(cell).get("valid",false): _valid_cells.append(cell)
	queue_redraw()
	_floor_guide.queue_redraw()
	_overlay.queue_redraw()

func _vortex_can_advance() -> bool:
	return session != null and not (session.paused or session.confirmation_open or session.result_open or session.save_blocked or session.sim.game_over)

func _process(delta: float) -> void:
	super._process(delta)
	_advance_trap_effects(minf(delta,.1))

func _watch_assets() -> void:
	super._watch_assets()
	# The base editor watcher disables runtime processing, including on rebuild.
	# Keep the bounded presentation clock alive only while an effect exists.
	if not Engine.is_editor_hint() and not _trap_triggers.is_empty(): set_process(true)

func _advance_trap_effects(delta: float) -> void:
	if _trap_triggers.is_empty() or not _vortex_can_advance(): return
	var expired := false
	for effect: Dictionary in _trap_triggers.values():
		effect.remaining = maxf(0, float(effect.remaining)-delta)
		if effect.remaining <= 0: expired = true
	if expired: _update_markers()

func rebuild() -> void:
	solid_groups.clear()
	_markers.clear()
	_trap_visuals.clear()
	chest_facings.clear()
	_actor = null
	_actor_at = Vector2(INF, INF)
	var cells := {}
	var specials := {}
	var hearts := PackedVector2Array()
	var chests := {}
	var trap_floors := {}
	var mechanisms := {}
	var sim := session.sim
	_prune_trap_triggers()
	for y in Types.ROWS:
		for x in Types.COLS:
			var p := Vector2i(x,y)
			var tile: int = sim.grid[y][x]
			if tile == Types.Tile.ROCK: continue
			cells[p] = true
			if sim._is_trap_tile(tile):
				var kind := "spike" if tile == Types.Tile.SPIKE else "snare" if tile == Types.Tile.SNARE else "void"
				var state := _trap_state(p, tile)
				trap_floors[p] = "trap-"+kind+"-"+state+"-floor"
				if kind != "void": mechanisms[p] = "trap-"+kind+"-"+state+"-mechanism"
			if tile == Types.Tile.CORE: hearts.append(Vector2(p) + Vector2(.5,.5))
			if tile == Types.Tile.VAULT:
				var orientation := ChestOrientation.select(sim, p)
				chest_facings[p] = orientation
				chests[Vector2(p) + Vector2(.5,.5)] = ChestOrientation.sprite_id(sim.vault_protected(p), orientation.facing)
			if sim._is_door_tile(tile) and sim._door_intact(p):
				var vertical_passage := sim._is_rock_cell(p + Vector2i.LEFT) and sim._is_rock_cell(p + Vector2i.RIGHT)
				specials[p] = "doors/north" if vertical_passage else "doors/west"
			if tile == Types.Tile.ENTRANCE:
				# Despite its legacy name, this returns the direction into the dungeon.
				var mouth := sim._wall_entrance_face(p)
				if ENTRANCE_OPEN_SIDES.has(mouth):
					specials[p] = "entrances/" + ENTRANCE_OPEN_SIDES[mouth]
	var plan := {"cells":cells,"openings":{},"hearts":hearts,"decoration_positions":chests,"wall_variants":true,"floor_variants":true,"floor_damage":true,"floor_replacements":trap_floors,"mechanisms":mechanisms}
	render_plan(plan, specials, true, false)
	for p: Vector2i in cells:
		var tile: int = sim.grid[p.y][p.x]
		if sim._is_trap_tile(tile):
			_add_marker("trap", p, Color("dc7682") if tile == Types.Tile.SPIKE else Color("9b85df"), false)
			var marker: Node2D = _markers.back().node
			marker.badge.configure("spike" if tile==Types.Tile.SPIKE else "snare" if tile==Types.Tile.SNARE else "void",Color("c66b50"),true)
		elif sim._is_door_tile(tile) and not sim._door_intact(p): _add_marker("door", p, Color("80c7b2"), false)
	for corpse in sim.corpses: _add_marker("corpse", corpse.pos, Color("aa7187"), false)
	for bag in sim.loot_bags:
		if bag.gold > 0: _add_marker("loot", bag.pos, Color("f4c55b"), false)
	# Sort architecture + static gameplay proxies only when the map changes.
	var ordered := super._ordered_parts(solid_groups.duplicate())
	solid_groups = ordered
	for part in ordered: _world.move_child(part.node, -1)
	if session.raid.raid_active:
		_actor = Marker.new()
		_actor.kind = "hero"
		_actor.z_index = 1
		_world.add_child(_actor)
	_update_markers()
	# Same layer as floors, after their container; solids retain layer 1.
	move_child(_floor_guide,-1)

func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
	_paint_order = super._ordered_parts(parts)
	_paint_cursor = 0
	return _paint_order

func _draw_part(part: Dictionary, layer: int) -> void:
	var before := _world.get_child_count()
	super._draw_part(part, layer)
	var entry: Dictionary = _definition.get("entries").get(part.id, {})
	if entry.has("trap"):
		for node in _world.get_children().slice(before):
			if node is Sprite2D:
				_trap_visuals.append({"cell":Vector2i(part.at),"node":node,"kind":entry.trap.kind,"layer":entry.trap.layer,"state":null})
	if layer != 1: return
	var nodes := _world.get_children().slice(before)
	var main: bool = _paint_cursor < _paint_order.size() and part.id == _paint_order[_paint_cursor].id and part.at == _paint_order[_paint_cursor].at
	if main:
		_last_group = Node2D.new()
		_last_group.z_index = 1
		_world.add_child(_last_group)
		var record := part.duplicate()
		record["node"] = _last_group
		solid_groups.append(record)
		_paint_cursor += 1
	# Keep each host and its following ornament in a single movable group.
	for node in nodes:
		node.reparent(_last_group)
		if node is Sprite2D: node.z_index = 0
	if main and entry.get("decoration", {}).has("chest_state"):
		# The ring moves with the prepared solid, so foreground ordering stays intact.
		var caption := Marker.new()
		caption.kind = "chest"
		caption.position = grid_to_local(part.at)
		_last_group.add_child(caption)
		caption.badge_anchor_y = part.rect.position.y - caption.position.y
		_markers.append({"cell":Vector2i(Vector2(part.at).floor()),"kind":"chest","node":caption})

func _proxy(at: Vector2, height: float, node: Node2D) -> Dictionary:
	return {"at":at,"min":Vector3(at.x-.14,at.y-.14,0),"max":Vector3(at.x+.14,at.y+.14,height),
		"rect":Rect2(grid_to_local(at)-Vector2(90,130),Vector2(180,155)),"depth":(at.x+at.y)*.6123724356957945,"node":node}

func _add_marker(kind: String, cell: Vector2i, color: Color, solid: bool) -> void:
	var marker := Marker.new()
	marker.kind = kind
	marker.tint = color
	marker.position = grid_to_local(Vector2(cell)+Vector2(.5,.5))
	marker.z_index = 1 if solid else 0
	_world.add_child(marker)
	_markers.append({"cell":cell,"kind":kind,"node":marker})
	if solid: solid_groups.append(_proxy(Vector2(cell)+Vector2(.5,.5), .25, marker))

func _on_trap_activated(cell: Vector2i, tile: int) -> void:
	var duration := .65
	if tile == Types.Tile.SNARE: duration = Types.SNARE_HOLD_TIME
	elif tile == Types.Tile.VOID: duration = session.raid.portal_hold
	# A result can arrive in the same stack as a lethal hit. This presentation
	# clock survives raid end, freezes behind pause/results, then finishes.
	_trap_triggers[cell] = {"tile":tile,"started":session.raid.elapsed_seconds,"remaining":duration,"raid":session.raid.raid_index,"charges":int(session.sim.trap_charges.get(cell,0))}
	set_process(true)
	_update_markers()

func _prune_trap_triggers() -> void:
	var sim := session.sim
	var raid := session.raid
	for p: Vector2i in _trap_triggers.keys():
		var effect: Dictionary = _trap_triggers[p]
		if raid.raid_index != effect.raid or raid.elapsed_seconds < effect.started or effect.remaining <= 0 or not sim._inside(p) or sim.grid[p.y][p.x] != effect.tile or int(sim.trap_charges.get(p,Types.trap_max_charges(effect.tile))) > effect.charges:
			_trap_triggers.erase(p)

func _trap_state(cell: Vector2i, tile: int) -> String:
	if _trap_triggers.has(cell): return "triggered"
	return "ready" if int(session.sim.trap_charges.get(cell,Types.trap_max_charges(tile))) > 0 else "spent"

func _update_markers() -> void:
	if not session: return
	var sim := session.sim
	_prune_trap_triggers()
	# All states share frame and support bounds: swaps preserve physical ordering.
	for item in _trap_visuals:
		var p: Vector2i = item.cell
		var state := _trap_state(p, sim.grid[p.y][p.x])
		if item.state == state: continue
		item.state = state
		var id: String = "trap-"+item.kind+"-"+state+"-"+item.layer
		item.node.texture = _definition.get("textures")[id]
		item.node.set_meta("prepared_id", id)
	# Keep the old mobile rings readable through project stretch and fixed zoom.
	var density := clampf(DisplayServer.screen_get_dpi()/160.0,1,4) if OS.has_feature("mobile") else 1.0
	var ui_scale := get_tree().root.get_visible_rect().size.x/maxf(1,get_window().size.x)*density
	var badge_extent := 32.0*ui_scale/maxf(.01,get_canvas_transform().get_scale().x)
	for item in _markers:
		item.node.fit_badge(badge_extent)
		var p: Vector2i = item.cell
		var text_value := ""
		match item.kind:
			"chest":
				item.node.badge.set_amount(int(sim.vault_gold.get(p,0)),Types.VAULT_CAPACITY,int(sim.vault_locks.get(p,0)),sim.vault_protected(p))
			"trap":
				var maximum := Types.trap_max_charges(sim.grid[p.y][p.x])
				var charges := int(sim.trap_charges.get(p, maximum))
				item.node.badge.set_amount(charges,maximum)
				item.node.active = charges > 0
			"door": text_value = "Ouverte" if sim.door_opened.get(p,false) else "Brisée"
			"corpse": text_value = "Corps"
			"loot": text_value = "Butin"
		item.node.refresh(text_value)
	if not is_instance_valid(_actor): return
	var hero := session.raid.hero
	if hero.is_empty():
		_actor.hide()
		return
	var at := Vector2(hero.pos) + Vector2(.5,.5)
	if hero.has("move_from") and hero.has("step_started_at"):
		var progress := clampf((session.raid.elapsed_seconds-float(hero.step_started_at))/Types.TURN_TIME,0,1)
		at = (Vector2(hero.move_from)+Vector2(.5,.5)).lerp(at, progress)
	if hero.get("jumping_trap",false):
		var progress := clampf(1-float(hero.jump_t)/Types.TRAP_JUMP_TIME,0,1)
		at = (Vector2(hero.jump_from)+Vector2(.5,.5)).lerp(Vector2(hero.pos)+Vector2(.5,.5),progress)
		_actor.jump_height = sin(progress*PI)*40
	else: _actor.jump_height = 0
	if hero.get("exiting",false):
		at = Vector2(hero.pos)+Vector2(.5,.5)-Vector2(sim._wall_entrance_face(hero.pos))*(1-float(hero.exit_t)/Types.TURN_TIME)*.4
	var colors := {"thief":Color("edb25f"),"paladin":Color("b7c9e7"),"ranger":Color("80c7a9"),"mage":Color("b98be9")}
	_actor.tint = colors.get(hero.kind,Color.WHITE)
	_actor.position = grid_to_local(at)
	_actor.refresh("%s · N%d" % [hero.name,hero.level],float(hero.hp)/maxf(1,float(hero.get("max_hp",hero.hp))))
	if not at.is_equal_approx(_actor_at):
		_actor_at = at
		_order_actor(_proxy(at,.65,_actor))

func _order_actor(actor: Dictionary) -> void:
	# Insert into cached static order, honoring physical support constraints.
	var lower := 0
	var upper := solid_groups.size()
	var fallback := 0
	for i in solid_groups.size():
		var other := solid_groups[i]
		if other.depth < actor.depth: fallback = i+1
		if not other.rect.intersects(actor.rect): continue
		var before := _behind(other,actor)
		var after := _behind(actor,other)
		if before and not after: lower = maxi(lower,i+1)
		elif after and not before: upper = mini(upper,i)
	var index := clampi(fallback,lower,maxi(lower,upper))
	_world.move_child(_actor,-1)
	if index < solid_groups.size(): _world.move_child(_actor,solid_groups[index].node.get_index())

func pick_cell(local_point: Vector2) -> Vector2i:
	return Vector2i(local_to_grid(local_point).floor())

func _diamond(cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	for offset in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN,Vector2.ZERO]:
		points.append(grid_to_local(Vector2(cell)+offset))
	return points

func _draw() -> void:
	if not session: return
	if not session.sim._has_core():
		for y in Types.ROWS:
			for x in Types.COLS: draw_polyline(_diamond(Vector2i(x,y)),Color(.4,.45,.65,.22),1,true)

func _draw_ground_guide() -> void:
	if session.can_edit():
		for cell in _valid_cells: _floor_guide.draw_polyline(_diamond(cell),Color(.74,.50,.85,.42),1.5,true)
	if access_visible:
		# Geometric access guide, not a prediction of a hero's private knowledge.
		var entrance:=session.sim._find_tile(Types.Tile.ENTRANCE)
		if entrance.x<0: return
		var pending: Array[Vector2i]=[entrance]
		var seen: Dictionary={entrance:true}
		while not pending.is_empty():
			var cell: Vector2i=pending.pop_front()
			var at:=grid_to_local(Vector2(cell)+Vector2(.5,.5))
			_floor_guide.draw_circle(at,3,Color(.91,.83,.66,.5))
			for direction in Types.DIRS:
				var next:=cell+direction
				if seen.has(next) or not session.sim._inside(next): continue
				if session.sim.grid[next.y][next.x] in [Types.Tile.ROCK,Types.Tile.CORE]: continue
				seen[next]=true; pending.append(next)

func show_placement(cell: Vector2i, valid: bool) -> void:
	_placement_cell=cell; _placement_valid=valid
	_overlay.queue_redraw()

func _draw_guide() -> void:
	var cell := _placement_cell if _placement_cell.x>=0 else session.selected
	if cell.x<0: return
	var valid := _placement_valid if _placement_cell.x>=0 else bool(session.preview.get("valid",true))
	var points := _diamond(cell)
	var color := Color("c89df0") if valid else Color("df7f87")
	_overlay.draw_colored_polygon(points,Color(color,.16))
	_overlay.draw_polyline(points,color,3,true)
