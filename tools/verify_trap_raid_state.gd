extends SceneTree
## Real raid activation and renderer, no player-save access.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const Types=preload("res://scripts/game/game_types.gd")
const OUT="res://artifacts/trap-raid-state/"
const CELL=Vector2i(6,8)
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: ",message)
func check_art(view:Node,kind:String,expected:String,context:String) -> void:
	check(view._trap_state(CELL,view.session.sim.grid[CELL.y][CELL.x])==expected,context+": state "+expected)
	var count:=0
	for item in view._trap_visuals:
		if item.cell!=CELL: continue
		count+=1
		check(item.node.get_meta("prepared_id")=="trap-"+kind+"-"+expected+"-"+item.layer,context+": painted "+item.layer)
	check(count==(1 if kind=="void" else 2),context+": all layers present")
func run() -> void:
	create_timer(30).timeout.connect(func(): push_error("Trap raid check timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var game=GAME.instantiate(); game.persistence_enabled=false
	root.add_child(game); game.set_process(false); await process_frame
	var view=game.get_node("PlayArea/World/Dungeon")
	for tile in [Types.Tile.SPIKE,Types.Tile.SNARE,Types.Tile.VOID]:
		var kind:String={Types.Tile.SPIKE:"spike",Types.Tile.SNARE:"snare",Types.Tile.VOID:"void"}[tile]
		var charge_cases:=[Types.trap_max_charges(tile)]
		if charge_cases[0]>1: charge_cases.append(1)
		for initial_charges in charge_cases:
			var context:="%s / %d charges" % [kind,initial_charges]
			game.restart(true); game.sim.grid[CELL.y][CELL.x]=tile; game.sim.trap_charges[CELL]=initial_charges
			game.cancel_selection(); game.start_raid(); game.set_process(false)
			game.raid.hero.pos=CELL; game.raid.hero.hp=1000; game.raid.hero.max_hp=1000
			view.rebuild(); view.set_process(false)
			check_art(view,kind,"ready",context+" before activation")
			game.raid._trigger_trap(CELL,tile)
			check_art(view,kind,"triggered",context+" immediate")
			view.set_process(false); view._advance_trap_effects(30); view._update_markers()
			check_art(view,kind,"triggered",context+" after 30s")
			var charges:int=game.sim.trap_charges[CELL]; var hp:int=game.raid.hero.hp
			game.raid._trigger_trap(CELL,tile)
			check(game.sim.trap_charges[CELL]==charges and game.raid.hero.hp==hp,context+": cannot trigger twice")
			# The raid ledger must survive rebuilding or losing the short VFX cache.
			view._trap_triggers.clear(); view.rebuild(); view.set_process(false)
			check_art(view,kind,"triggered",context+" after rebuild/cache loss")
			game.set_paused(true); view._advance_trap_effects(30)
			check_art(view,kind,"triggered",context+" paused")
			game.set_paused(false)
			if DisplayServer.get_name()!="headless" and initial_charges==Types.trap_max_charges(tile):
				var camera:Camera2D=game.get_node("PlayArea/World/Camera2D")
				camera.position=view.grid_to_local(Vector2(CELL)+Vector2(.5,.5)); camera.zoom=Vector2.ONE*2
				camera.force_update_scroll(); game.get_node("HUD").hide(); view._actor.hide()
				await process_frame; await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
				game.get_node("PlayArea/World").get_texture().get_image().save_png(OUT+kind+"-used.png")
			game.raid._end_raid("Review complete"); game.continue_preparation(); view._update_markers()
			var expected:="ready" if charges>0 else "spent"
			check_art(view,kind,expected,context+" next preparation")
			game.start_raid(); view._update_markers()
			check_art(view,kind,expected,context+" next raid")
			if charges>0:
				game.raid._trigger_trap(CELL,tile)
				check(game.sim.trap_charges[CELL]==charges-1,context+": can trigger in new raid")
			game.restart(true); view._update_markers()
			check_art(view,"spike","ready",context+" reset")
	var file:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Trap raid state: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
