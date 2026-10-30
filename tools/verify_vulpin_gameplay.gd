extends SceneTree
## Regression at the real renderer boundary. Never reads/writes player saves.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const OUT = "res://artifacts/vulpin-gameplay/"
var failures: Array[String] = []
var checks := 0
var fixture_id := 100
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: ", message)
func fixture(game: Node, view: Node, values: Dictionary) -> void:
	fixture_id += 1
	game.raid.hero = {"id":fixture_id,"pos":Vector2i(6,8),"kind":"thief","name":"Neris","level":1,"hp":100,"max_hp":100,"facing":Vector2i.RIGHT,"carried_gold":0,"display":"Neris","fleeing":false}
	game.raid.hero.merge(values,true)
	game.raid.elapsed_seconds = 10
	game.raid.raid_active = true
	view.rebuild()
	view.set_process(false)
func shot(game: Node, view: Node, title: String, close := true) -> void:
	if DisplayServer.get_name()=="headless": return
	if close:
		var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
		camera.position = view._actor.position-Vector2(0,50)
		camera.zoom = Vector2.ONE*1.4
		camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+title+".png")
func inspect_passage(view: Node, cell: Vector2i, context: String) -> void:
	var jambs: Array = []
	for part in view.solid_groups:
		if not str(part.id).begins_with("door-") or Vector2i(part.at)!=cell: continue
		var role: String = view._definition.entries[part.id].get("door_part","")
		if role.begins_with("jamb"): jambs.append(part)
		if role=="crown": check(view._actor.get_index()<part.node.get_index(),context+": crown above hero")
	jambs.sort_custom(func(a,b):return a.depth<b.depth)
	check(jambs.size()==2,context+": two independently sorted jambs")
	if jambs.size()==2:
		check(jambs[0].node.get_index()<view._actor.get_index(),context+": far jamb behind")
		check(jambs[1].node.get_index()>view._actor.get_index(),context+": near jamb in front")
func run() -> void:
	create_timer(90).timeout.connect(func(): push_error("Vulpin gameplay timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280,720)
	var game = GAME.instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.restart(true)
	game.start_raid()
	var view = game.get_node("PlayArea/World/Dungeon")
	check(game.raid.hero.kind == "thief", "real raid selects a Vulpin")
	var sprite = view._actor.get_node_or_null("Sprite")
	check(sprite is AnimatedSprite2D, "real raid renders approved Vulpin sprites instead of a pawn")
	if sprite is AnimatedSprite2D:
		check(sprite.sprite_frames.resource_path.ends_with("vulpin-walk/frames.tres") and game.raid.hero.get("entering",false),"spawn walks down the entrance")
		await shot(game,view,"spawn",false)
		# One native raid: the same simulation clock updates sprites, including pause and 2x.
		game.advance_simulation(.1)
		check(view._actor.state=="walk","actual movement selects walking")
		var clock: float = game.raid.elapsed_seconds
		var pose: int = view._actor.sprite.frame
		var position: Vector2 = view._actor.position
		game.set_paused(true); game.advance_simulation(.1)
		check(game.raid.elapsed_seconds==clock and view._actor.sprite.frame==pose and view._actor.position==position,"pause freezes travel and pose")
		game.set_paused(false); game.raid_speed=2; game.advance_simulation(.05)
		check(is_equal_approx(game.raid.elapsed_seconds,clock+.1),"2x shares simulation time")
		game.raid_speed=1
		# Direction, walk/run/idle, real art resources and no rendering writes to hero.
		for dir in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			for fleeing in [false,true]:
				fixture(game,view,{"pos":Vector2i(6,8),"move_from":Vector2i(6,8)-dir,"step_started_at":9.8,"facing":dir,"fleeing":fleeing})
				var before := var_to_bytes(game.raid.hero)
				view._update_markers()
				check(view._actor.facing=={Vector2i.RIGHT:"se",Vector2i.DOWN:"sw",Vector2i.LEFT:"nw",Vector2i.UP:"ne"}[dir],"correct facing "+str(dir))
				check(view._actor.state==("run" if fleeing else "walk"),"correct gait "+str(dir)+str(fleeing))
				check(before==var_to_bytes(game.raid.hero),"rendering never changes simulation")
				var initial_frame: int = view._actor.sprite.frame
				game.raid.elapsed_seconds=10.12; view._update_markers()
				check(view._actor.sprite.frame!=initial_frame,"gait advances")
				game.raid.elapsed_seconds=10.5; view._update_markers()
				check(view._actor.state=="idle","standing after completed step")
		# Four door approaches and full-sized hero passing the real split open arch.
		var gate := Vector2i(6,8)
		for dir in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			game.sim.new_map()
			for n in range(-2,3): game.sim.grid[(gate+dir*n).y][(gate+dir*n).x]=Types.Tile.FLOOR
			game.sim.grid[gate.y][gate.x]=Types.Tile.DOOR; game.sim.door_hp[gate]=Types.DOOR_MAX_HP
			fixture(game,view,{"pos":gate-dir,"facing":dir,"lockpicking":true,"lockpick_pos":gate,"lockpick_t":3.0})
			game.raid.elapsed_seconds=10.3; game.raid.hero.lockpick_t=2.7; view._update_markers()
			check(view._actor.state=="lockpick","door lockpick "+str(dir))
			check((view._actor.position+view._actor.contact_offset).distance_to(view._actor.contact_target)<.001,"calibrated lock contact "+str(dir))
			var actor = view._actor
			var old_frame: int = actor.sprite.frame
			view.rebuild()
			check(view._actor==actor and actor.sprite.frame==old_frame,"rebuild preserves pose and actor")
			await shot(game,view,"door-pick-"+actor.facing)
			game.sim.door_hp[gate]=0; game.sim.door_opened[gate]=true
			fixture(game,view,{"pos":gate,"facing":dir})
			inspect_passage(view,gate,"passage "+str(dir))
			await shot(game,view,"door-passage-"+view._actor.facing)
			for running in [false,true]:
				for frame in 8:
					fixture(game,view,{"pos":gate+dir,"move_from":gate-dir,"facing":dir,"fleeing":running,"step_started_at":9.76})
					game.raid.elapsed_seconds=16+frame/(16.0 if running else 15.0)
					game.raid.hero.step_started_at=game.raid.elapsed_seconds-.24
					view._update_markers()
					inspect_passage(view,gate,"moving passage "+str(dir)+str(running)+str(frame))
		# Four chest orientations; closed stays closed until actual unlock.
		for normal in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			game.sim.new_map()
			game.sim.grid[gate.y][gate.x]=Types.Tile.VAULT
			for n in [1,2]: game.sim.grid[(gate+normal*n).y][(gate+normal*n).x]=Types.Tile.FLOOR
			game.sim.vault_locks[gate]=1
			fixture(game,view,{"pos":gate,"lockpicking":true,"lockpick_pos":gate,"lockpick_t":3.0})
			game.raid.elapsed_seconds=10.3; view._update_markers()
			check(view._actor.state=="chest_lockpick" and game.sim.vault_protected(gate),"closed chest picking "+str(normal))
			check((view._actor.position+view._actor.contact_offset).distance_to(view._actor.contact_target)<.001,"chest lock registration "+str(normal))
			await shot(game,view,"chest-pick-"+view._actor.facing)
			game.sim.vault_opened[gate]=true
			fixture(game,view,{"pos":gate,"collecting_gold":true,"collect_vault":gate,"collect_t":5.5})
			game.raid.elapsed_seconds=10.3; view._update_markers()
			check(view._actor.state=="chest_open" and not game.sim.vault_protected(gate),"ajar chest collection "+str(normal))
			check((view._actor.position+view._actor.contact_offset).distance_to(view._actor.contact_target)<.001,"chest grip registration "+str(normal))
			await shot(game,view,"chest-loot-"+view._actor.facing)
		# Legal dense storage: a chest's front can face rock when every adjoining
		# walkable cell also contains a chest. Registration must not put the fox outside.
		game.restart(true)
		for n in range(-1,2):
			game.sim._clear_cell_state(gate+Vector2i(n,0))
			game.sim.grid[gate.y][gate.x+n]=Types.Tile.FLOOR
			check(game.sim.build_vault(gate+Vector2i(n,0),1),"adjacent vault is legal")
		for action in ["lockpicking","collecting_gold"]:
			fixture(game,view,{"pos":gate,action:true,"lockpick_pos":gate,"lockpick_t":3.0,"collect_vault":gate,"collect_t":5.5})
			game.raid.elapsed_seconds=10.3; view._update_markers()
			check(not view.chest_facings[gate].accessible,"fixture has no clear chest front")
			var support: Dictionary = view._actor.support()
			check(view._actor.grid_position.y < gate.y+1,"blocked front keeps feet out of rock")
			check(support.min.y >= gate.y and support.max.y <= gate.y+1,"blocked front keeps body between corridor walls")
			await shot(game,view,"blocked-chest-"+action)
		# Injury and death use their one-shot sheets, persistent corpse after raid.
		game.restart(true)
		fixture(game,view,{})
		game.raid.hero.hp=70; view._update_markers()
		check(view._actor.state=="hurt","damage selects recoil")
		game.raid.elapsed_seconds+=.20; view._update_markers()
		await shot(game,view,"hurt")
		game.raid.elapsed_seconds+=.8; view._update_markers()
		check(view._actor.state=="idle","hurt does not loop")
		game.raid.hero.hp=0; game.raid.hero.dying=true; game.raid.hero.dying_t=1.5
		view._update_markers()
		check(view._actor.state=="death" and view._actor.sprite.frame==0,"death starts at knees sequence")
		game.raid.hero.dying_t=.5; game.raid.elapsed_seconds+=1; view._update_markers()
		check(view._actor.sprite.frame==9,"death holds final pose at accepted speed")
		await shot(game,view,"death")
		game.raid.raid_stats={"killed":0}; game.raid._kill_hero()
		check(game.sim.corpses.back().kind=="thief","corpse retains species")
		var snapshot: Dictionary = game.Save.capture(game.sim,game.raid,game.progression)
		check(game.Save._valid(snapshot),"corpse appearance is valid save data")
		snapshot.corpses.back().erase("kind"); snapshot.corpses.back().erase("facing")
		check(game.Save._valid(snapshot),"old corpse format still valid")
		check(view.solid_groups.any(func(p):return p.id=="vulpin"),"raid end retains painted corpse")
		var current: Dictionary = game.Save.capture(game.sim,game.raid,game.progression)
		check(game.Save.apply(current,game.sim,game.raid,game.progression),"new corpse reloads without a disk save")
		view.rebuild()
		check(view.solid_groups.any(func(p):return p.id=="vulpin"),"reloaded corpse remains painted")
		# Inspect a real unmodified raid and record the native state transitions.
		game.restart(true); seed(21); game.start_raid()
		game.get_node("Input")._apply_presentation()
		game.get_node("Input").center_core()
		var observed := {}
		var captured := {}
		for i in 1800:
			if not game.raid.raid_active: break
			game.advance_simulation(1.0/30.0)
			if not is_instance_valid(view._actor): continue
			var key: String = view._actor.state
			if not observed.has(key):
				observed[key]=game.raid.elapsed_seconds
				await shot(game,view,"raid-"+key,false)
			elif not captured.has(key) and game.raid.elapsed_seconds-observed[key]>.25:
				captured[key]=true
				await shot(game,view,"raid-"+key+"-settled",false)
		print("Observed real raid states: ",observed)
		# The same sprite remains anchored after a mobile orientation change.
		for extent in [Vector2i(844,390),Vector2i(390,844)]:
			root.size=extent
			await process_frame; await process_frame
			game.restart(true); game.start_raid()
			game.advance_simulation(.1)
			var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
			camera.position=view._actor.position-Vector2(0,40)
			camera.force_update_scroll()
			check(view._actor.sprite.visible and view._actor.sprite.scale.is_equal_approx(Vector2.ONE*.85),"same art scale after rotation "+str(extent))
			await shot(game,view,"mobile-"+str(extent.x),false)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Vulpin gameplay: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
