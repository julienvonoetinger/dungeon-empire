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
var _actor: Node2D
var _actor_at := Vector2(INF, INF)
var chest_facings: Dictionary = {}

func _ready() -> void:
	session = get_parent() as IsometricGameSession
	session.changed.connect(_on_change)
	session.frame_updated.connect(_update_markers)

func _on_change(structure: bool) -> void:
	if structure: rebuild()
	queue_redraw()

func rebuild() -> void:
	solid_groups.clear()
	_markers.clear()
	chest_facings.clear()
	_actor = null
	_actor_at = Vector2(INF, INF)
	var cells := {}
	var specials := {}
	var hearts := PackedVector2Array()
	var chests := {}
	var sim := session.sim
	for y in Types.ROWS:
		for x in Types.COLS:
			var p := Vector2i(x,y)
			var tile: int = sim.grid[y][x]
			if tile == Types.Tile.ROCK: continue
			cells[p] = true
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
	var plan := {"cells":cells,"openings":{},"hearts":hearts,"decoration_positions":chests,"wall_variants":true,"floor_variants":true,"floor_damage":true}
	render_plan(plan, specials, true, false)
	for p: Vector2i in cells:
		var tile: int = sim.grid[p.y][p.x]
		if sim._is_trap_tile(tile):
			_add_marker("trap", p, Color("dc7682") if tile == Types.Tile.SPIKE else Color("9b85df"), false)
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

func _ordered_parts(parts: Array[Dictionary]) -> Array[Dictionary]:
	_paint_order = super._ordered_parts(parts)
	_paint_cursor = 0
	return _paint_order

func _draw_part(part: Dictionary, layer: int) -> void:
	var before := _world.get_child_count()
	super._draw_part(part, layer)
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
	var entry: Dictionary = _definition.get("entries").get(part.id, {})
	if main and entry.get("decoration", {}).has("chest_state"):
		# The count moves with the prepared solid, so foreground ordering stays intact.
		var caption := Marker.new()
		caption.kind = "chest"
		caption.position = grid_to_local(part.at)
		_last_group.add_child(caption)
		caption.label.position.y = part.rect.position.y - caption.position.y - 28
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

func _update_markers() -> void:
	if not session: return
	var sim := session.sim
	for item in _markers:
		var p: Vector2i = item.cell
		var text_value := ""
		match item.kind:
			"chest": text_value = "%d / 150" % int(sim.vault_gold.get(p,0))
			"trap":
				var names := {Types.Tile.SPIKE:"Pointes",Types.Tile.SNARE:"Entrave",Types.Tile.VOID:"Néant"}
				text_value = "%s · %d" % [names.get(sim.grid[p.y][p.x],"Piège"),sim.trap_charges.get(p,0)]
				item.node.active = int(sim.trap_charges.get(p,0)) > 0
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
	elif session.can_edit():
		for y in Types.ROWS:
			for x in Types.COLS:
				var p := Vector2i(x,y)
				if session.sim._is_diggable_rock(p): draw_polyline(_diamond(p),Color(.85,.67,.35,.5),1.5,true)
	if session.selected.x >= 0:
		var points := _diamond(session.selected)
		var color := Color("e7c679") if session.preview.get("valid",true) else Color("df7f87")
		draw_colored_polygon(points,Color(color,.15))
		draw_polyline(points,color,3,true)
