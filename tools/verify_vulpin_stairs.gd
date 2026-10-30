extends SceneTree
## Actual entrance/exit progression and native renderer. Never accesses a save.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const Types=preload("res://scripts/game/game_types.gd")
const Stairs=preload("res://scripts/game/stair_traversal.gd")
const OUT="res://artifacts/vulpin-stairs/"
var failures: Array[String]=[]
var checks:=0
var traces: Dictionary={}

func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	create_timer(70).timeout.connect(func(): push_error("Stair test timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var game=GAME.instantiate(); game.persistence_enabled=false
	root.add_child(game); game.set_process(false); await process_frame
	game.restart(true); game.start_raid()
	var view=game.get_node("PlayArea/World/Dungeon")
	check(game.raid.hero.get("entering",false),"A raid starts with a timed stair descent")
	check(view._actor.state=="walk","Entry uses moving feet rather than a standing spawn")
	check(view._actor.modulate.a<.01,"The hero starts concealed at the top instead of popping into the middle")
	game.advance_simulation(.1)
	check(game.raid.hero.pos==Vector2i(3,8) and game.raid.hero.turns==0,"Entry must finish before the first exploration decision")
	var at: Vector2=view._actor.grid_position
	check(view._actor.position.y<view.grid_to_local(at).y-20,"Feet are raised onto the actual stair treads")
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(3.7,8.5))-Vector2(0,50)
	camera.zoom=Vector2.ONE*1.5; camera.force_update_scroll()
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"entry.png")
	var frozen: Vector2 = view._actor.position
	var opacity: float = view._actor.modulate.a
	game.set_paused(true); game.advance_simulation(.1)
	check(view._actor.position==frozen and view._actor.modulate.a==opacity,"Pause freezes descent and endpoint fade")
	game.set_paused(false); game.raid_speed=2; game.advance_simulation(.05)
	check(is_equal_approx(game.raid.elapsed_seconds,.2),"2x drives the same entry clock")
	game.raid_speed=1
	for mouth: Vector2i in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
		if not "--adjacent-only" in OS.get_cmdline_user_args(): await exercise_direction(game,view,mouth)
		await exercise_adjacent_door(game,view,mouth)
	game.queue_free(); await process_frame
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"traces":traces},"\t"))
	print("Vulpin stairs: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func exercise_direction(game: Node,view: Node,mouth: Vector2i) -> void:
	game.restart(false)
	var entrance := Vector2i(8,8)
	for i in 4:
		var cell := entrance+mouth*i
		game.sim.grid[cell.y][cell.x]=Types.Tile.FLOOR
	var vault := entrance+mouth*3
	game.sim.grid[vault.y][vault.x]=Types.Tile.VAULT
	game.sim.vault_gold[vault]=100
	game.sim.grid[entrance.y][entrance.x]=Types.Tile.ENTRANCE
	# This small inspection corridor deliberately bypasses storage prerequisites.
	# The first case above exercises start_raid in the real complete demo instead.
	game.raid._start_raid(); game.changed.emit(true)
	var direction: String=view.ENTRANCE_OPEN_SIDES[mouth]
	check(game.sim._entrance_mouth(entrance)==mouth,"Native mouth "+direction)
	# Check runtime profile against the actual art source, not just its copy in code.
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/reference/entrance-stairs-open-south-wireframe.json"))
	for step: Dictionary in source.stairs.steps:
		var u: float=(step.y0+step.y1)*.5
		var at:=Vector2(entrance)+Vector2(.5,.5)+Vector2(mouth)*(u-.5)
		check(is_equal_approx(Stairs.sample(game.sim,{},at).elevation,step.top),"Feet match painted tread "+direction+str(u))
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(entrance)+Vector2(.5,.5)+Vector2(mouth)*.4)-Vector2(0,65)
	camera.zoom=Vector2.ONE*1.25; camera.force_update_scroll()
	game.get_node("HUD").hide()
	var trace:=[]
	var previous: Vector2=view._actor.position
	var left_stairs:=false
	var climbing:=false
	var max_exit_height:=0.0
	var last_opacity:=1.0
	for frame in 120:
		if game.raid.raid_active:
			# Turn back through the simulation after reaching the corridor floor.
			if frame==34: game.raid.hero.fleeing=true
			game.advance_simulation(1.0/30)
		if game.raid.raid_active:
			var actor=view._actor
			var hero: Dictionary=game.raid.hero
			check(actor.position.distance_to(previous)<30,"Continuous stair travel "+direction+str(frame))
			previous=actor.position
			var on_stairs: bool=actor.stair_cell==entrance
			if not on_stairs: left_stairs=true
			if on_stairs:
				for part: Dictionary in view.solid_groups:
					if String(part.get("id","")).begins_with("stair-") and Vector2i(part.at)==entrance:
						check(part.node.get_index()<actor.get_index(),"Treads stay behind the hero "+direction+str(frame))
				check(actor.elevation>=0 and actor.elevation<=.25001,"Grounded stair height "+direction)
			else: check(is_zero_approx(actor.elevation),"Floor contact "+direction)
			if hero.get("fleeing",false) and on_stairs:
				climbing=true; max_exit_height=maxf(max_exit_height,actor.elevation)
			if not hero.get("entering",false) and not hero.get("exiting",false):
				check(is_equal_approx(actor.modulate.a,1),"No mid-stair fade "+direction)
			last_opacity=actor.modulate.a
			trace.append({"frame":frame,"at":str(actor.grid_position),"height":actor.elevation,"alpha":last_opacity,"enter":hero.get("entering",false),"exit":hero.get("exiting",false)})
		if frame%2==0:
			await process_frame; await RenderingServer.frame_post_draw
			var screen: Image=game.get_node("PlayArea/World").get_texture().get_image()
			# 15 FPS native captures; simulation still advances at 30 Hz.
			screen.save_png(OUT+direction+"-%03d.png"%frame)
	check(left_stairs and climbing and max_exit_height>.249,"Complete descent and ascent "+direction)
	check(not game.raid.raid_active and game.raid.last_result.get("escaped",0)==1,"One timed departure "+direction)
	check(last_opacity<.1,"Vanish only at the distant top endpoint "+direction)
	traces[direction]=trace

func exercise_adjacent_door(game: Node,view: Node,mouth: Vector2i) -> void:
	game.restart(false)
	var entrance:=Vector2i(8,8)
	for i in 4:
		var cell:=entrance+mouth*i
		game.sim.grid[cell.y][cell.x]=Types.Tile.FLOOR
	var door:=entrance+mouth
	game.sim.grid[door.y][door.x]=Types.Tile.DOOR; game.sim.door_hp[door]=Types.DOOR_MAX_HP
	var vault:=entrance+mouth*3
	game.sim.grid[vault.y][vault.x]=Types.Tile.VAULT; game.sim.vault_gold[vault]=100
	game.sim.grid[entrance.y][entrance.x]=Types.Tile.ENTRANCE
	game.raid._start_raid(); game.raid.hero.lockpick_success_chance=0.0
	game.changed.emit(true)
	var previous: Vector2=view._actor.position
	var picked:=false
	var returned:=false
	var direction: String=view.ENTRANCE_OPEN_SIDES[mouth]
	for frame in 240:
		if not game.raid.raid_active: break
		game.advance_simulation(1.0/30)
		if not game.raid.raid_active: break
		var actor=view._actor
		picked=picked or game.raid.hero.get("lockpicking",false)
		check(actor.position.distance_to(previous)<30,"No snap after adjacent pick "+direction+str(frame))
		previous=actor.position
		if game.raid.hero.get("exiting",false):
			returned=true
			var u: float=(actor.grid_position-Vector2(entrance)-Vector2(.5,.5)).dot(Vector2(mouth))+.5
			if u>.23: check(is_equal_approx(actor.modulate.a,1),"Longer retreat fades only at top "+direction)
	check(picked and returned and not game.raid.raid_active,"Adjacent door failure returns through stairs "+direction)
