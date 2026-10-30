extends SceneTree
## Same simulation observed with passive probes, optionally with native sprites.
const Session=preload("res://scripts/game/game_session.gd")
const Game=preload("res://scenes/game/DungeonGame.tscn")
const Probes=preload("res://scripts/testing/game_probes.gd")
const Types=preload("res://scripts/game/game_types.gd")
const OUT="res://artifacts/vulpin-trap-reaction/"
var failures: Array[String]=[]
var checks:=0
var traces: Array=[]
var native:=false

func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message); print("FAIL: ",message)

func run() -> void:
	native="--native" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(OUT)
	for rate in [1,2]:
		for tile in [Types.Tile.SPIKE,Types.Tile.SNARE]:
			await exercise(tile,rate,false)
	await exercise(Types.Tile.SPIKE,1,true)
	FileAccess.open(OUT+("native" if native else "probes")+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"traces":traces},"\t"))
	print("Vulpin trap reaction: ",checks," checks, ",failures.size()," failures; native=",native)
	quit(0 if failures.is_empty() else 1)

func exercise(tile: int,rate: int,lethal: bool) -> void:
	var game=Game.instantiate() if native else Session.new()
	game.persistence_enabled=false
	root.add_child(game); game.set_process(false)
	if native: await process_frame
	game.restart(true)
	var trap:=Vector2i(6,8)
	game.sim.grid[trap.y][trap.x]=tile
	game.raid_speed=rate
	seed(21); game.start_raid()
	# Preserve actual navigation/pick/arrival; choose deterministic test outcomes.
	game.raid.hero.lockpick_success_chance=1.0
	if lethal: game.raid.hero.hp=Types.DAMAGE_SPIKE
	var label: String=Types.Tile.keys()[tile]+" x"+str(rate)+(" lethal" if lethal else "")
	var before:=Probes.snapshot(game)
	var hit: Dictionary={}
	var dt:=1.0/60
	for tick in 2400:
		game.advance_simulation(dt)
		var now:=Probes.snapshot(game)
		if now["trap:6:8"].charges<before["trap:6:8"].charges:
			hit=now; break
		if not now.raid.active: break
	check(not hit.is_empty(),label+": actual trap hit observed")
	if hit.is_empty(): game.free(); return
	var view=game.get_node("PlayArea/World/Dungeon") if native else null
	if native:
		var frames: SpriteFrames=view._actor.FRAMES.hurt
		var duration:=0.0
		for index in frames.get_frame_count("se"):
			duration+=frames.get_frame_duration("se",index)/frames.get_animation_speed("se")
		check(is_equal_approx(duration,Types.VULPIN_HURT_HOLD),label+": hold matches the approved full clip")
	var anchor: Vector2=view._actor.position if native else Vector2.ZERO
	var hit_time: float=hit.raid.elapsed
	var trace: Array=[{"t":hit_time,"hero":hit.hero}]
	game.set_paused(true); game.advance_simulation(.1)
	check(Probes.snapshot(game).raid.elapsed==hit_time,label+": pause freezes hit clock")
	game.set_paused(false)
	var remains_still:=true
	var pixels_still:=true
	var hurt_seen:=not native
	var death_seen:=not native
	var resumed_at: float=-1
	for tick in 260:
		game.advance_simulation(dt)
		var now:=Probes.snapshot(game)
		var since: float=now.raid.elapsed-hit_time
		if not now.hero.present: break
		var moved: bool=now.hero.pos!=hit.hero.pos or now.hero.get("step_started_at")!=hit.hero.get("step_started_at")
		if since<.7:
			remains_still=remains_still and not moved and now.hero.turns==hit.hero.turns
			if native:
				pixels_still=pixels_still and view._actor.position.distance_to(anchor)<.001
				hurt_seen=hurt_seen or view._actor.state=="hurt"
				death_seen=death_seen or view._actor.state=="death"
		if native and view._actor.state=="hurt":
			pixels_still=pixels_still and view._actor.position.distance_to(anchor)<.001
		if tick%6==0: trace.append({"t":now.raid.elapsed,"hero":now.hero})
		if native and tick in [5,18]:
			var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
			camera.position=anchor-Vector2(0,50); camera.zoom=Vector2.ONE*1.4; camera.force_update_scroll()
			await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+label.replace(" ","-")+"-%02d.png"%tick)
		if moved:
			resumed_at=since; break
		if lethal and since>1.7: break
	check(remains_still,label+": no simulation movement or decision during recoil")
	if native: check(pixels_still,label+": root stays on the struck tile during recoil")
	if lethal:
		check(resumed_at<0 and not game.raid.raid_active and game.raid.last_result.get("killed",0)==1,label+": death takes priority and ends normally")
		check(death_seen,label+": native fall takes priority")
	else:
		check(hurt_seen,label+": native damage clip played")
		var expected:=.72 if tile==Types.Tile.SPIKE else Types.SNARE_HOLD_TIME
		check(resumed_at>=expected-.034 and resumed_at<=expected+.10,label+": resumes after correct hold, got "+str(resumed_at))
		check(game.sim.trap_charges[trap]==2,label+": damage consumes only one charge")
	traces.append({"case":label,"resume":resumed_at,"trace":trace})
	game.free()
