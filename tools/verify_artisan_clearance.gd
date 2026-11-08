extends SceneTree
## Occupied volume from the same Blender poses as the rendered atlases.
const RECORD := "res://docs/reference/oculins-didacticiel/v5-port-outils/tool-bounds.json"
const ROLES := ["mineur","menuisier","scientifique"]
var measured: Dictionary
var collisions := {}
var samples := 0

class TracedView extends "res://scripts/game/isometric_game_view.gd":
	var feet := {}
	func position_invoker(actor: Node2D, at: Vector2) -> void:
		super.position_invoker(actor,at)
		if actor is AnimatedSprite2D: feet[actor.get_instance_id()] = at

func _initialize() -> void: run.call_deferred()

func orient(p: Vector3, facing: StringName) -> Vector3:
	match facing:
		&"se": return Vector3(-p.y,-p.x,p.z)
		&"nw": return Vector3(p.y,p.x,p.z)
		&"sw": return Vector3(p.x,-p.y,p.z)
		_: return Vector3(-p.x,p.y,p.z)

func sample_walk(intro, departing: bool) -> void:
	var masonry: Array[Dictionary] = []
	for part in intro.view.solid_groups:
		var id := str(part.get("id",""))
		if id.begins_with("wall-") or id == "pillar" or id.begins_with("door-"):
			masonry.append({"id":id, "box":AABB(part.min,part.max-part.min)})
	const HZ := 120.
	var ticks := ceili((intro.ENTRY_DURATION-intro.ARTISAN_START)*HZ)
	for tick in range(ticks+1):
		var time: float = intro.ARTISAN_START + tick/HZ
		intro._present_artisans(time,intro._entrance_top(),departing)
		for i in intro.artisans.size():
			var actor: AnimatedSprite2D = intro.artisans[i]
			if not actor.visible or actor.modulate.a < .01: continue
			var at: Vector2 = intro.view.feet[actor.get_instance_id()]
			var height: float = intro.Stairs.sample(intro.session.sim,{},at).elevation
			var origin := Vector3(at.x,at.y,height)
			var scale_to_cells := actor.scale.x * sqrt(2.) / 2.55
			for limits in measured[ROLES[i]].bounds[actor.frame]:
				var lo: Array = limits[0]
				var hi: Array = limits[1]
				var a := origin + orient(Vector3(lo[0],lo[1],lo[2]),actor.animation)*scale_to_cells
				var b := origin + orient(Vector3(hi[0],hi[1],hi[2]),actor.animation)*scale_to_cells
				# Include one sample's root travel between consecutive held poses.
				var box := AABB(a.min(b),(b-a).abs()).grow(intro.ARTISAN_SPEED/HZ)
				for solid in masonry:
					if box.intersects(solid.box):
						var key := "%s %s %s" % [ROLES[i],"sortie" if departing else "entrée",solid.id]
						if not collisions.has(key): collisions[key] = [at,actor.animation,actor.frame]
			samples += 1

func run() -> void:
	measured = JSON.parse_string(FileAccess.get_file_as_string(RECORD))
	for role in ROLES:
		var frames: Array = measured[role].bounds
		var empty_hands: bool = role == "scientifique"
		if frames.size() != 16 or frames.any(func(boxes): return boxes.is_empty() != empty_hands):
			push_error("Unexpected tool volume for "+role)
			quit(1)
			return
		for view in ["se","sw","nw","ne"]:
			var path := "res://assets/previews/oculin-%s-walk/walk-%s.png" % [role,view]
			if FileAccess.get_sha256(path) != measured[role].atlases[view]:
				push_error("Tool bounds do not match "+path)
				quit(1)
				return
	var game = load("res://scenes/game/DungeonGame.tscn").instantiate()
	game.persistence_enabled = false
	game.get_node("PlayArea/World/Dungeon").set_script(TracedView)
	root.add_child(game)
	var intro = game.get_node("Introduction")
	game.restart(false,true)
	intro._set_shot(intro.Shot.ENTRANCE)
	sample_walk(intro,false)
	for x in [4,5,6]:
		var cell := Vector2i(x,8)
		game.sim.grid[8][x] = GameTypes.Tile.DOOR
		intro._set_shot(intro.Shot.ARTISAN_EXIT)
		sample_walk(intro,true)
		game.sim.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
		intro._set_shot(intro.Shot.PRACTICE_OFFER)
	print("Artisan tool clearance: ",samples," samples, ",collisions.size()," conflicts")
	for key in collisions: print(key," ",collisions[key])
	game.queue_free()
	await process_frame
	quit(0 if collisions.is_empty() and samples>18000 else 1)
