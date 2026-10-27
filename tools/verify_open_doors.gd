extends SceneTree
## Isolated presentation regression; no normal player-save access.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
var out := "res://artifacts/open-doors-after/"
var failures: Array[String] = []
var checks := 0
var records: Array = []

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	if "--before" in OS.get_cmdline_user_args(): out = "res://artifacts/open-doors-before/"
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func inspect(view: Node2D, state: String, open_frame: bool, removed := false) -> void:
	var doors: Array = view.solid_groups.filter(func(p): return str(p.id).begins_with("door-"))
	var segments: Array = view.solid_groups.filter(func(p): return p.has("wall_segment"))
	check(doors.size() == (0 if removed else 4), state + ": stone frames must remain on both doors")
	check(segments.size() == (0 if removed else 8), state + ": wall contacts must match the frames")
	for p in doors:
		check(str(p.id).contains("-open-") == open_frame, state + ": wrong leaf state " + str(p.id))
	records.append({"state":state,"parts":doors.map(func(p): return p.id),"contacts":segments.size()})

func snapshot(game: Node, view: Node2D, state: String) -> void:
	var camera: Camera2D = game.get_node("PlayArea/World/Camera2D")
	var world: SubViewport = game.get_node("PlayArea/World")
	for cell in [Vector2i(8,6),Vector2i(10,8)]:
		camera.position = view.grid_to_local(Vector2(cell)+Vector2(.5,.5))+Vector2(0,-45)
		camera.zoom = Vector2.ONE*1.7; camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		world.get_texture().get_image().save_png(out+state+("-north" if cell.x==8 else "-west")+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var game = GAME.instantiate(); game.save_path = out+"never-created.save"
	root.add_child(game); game.set_process(false); await process_frame
	game.get_node("HUD").hide()
	game.get_node("PlayArea").stretch = false
	game.get_node("PlayArea/World").size = Vector2i(640,480)
	game.sim.new_map()
	for i in range(5,12):
		game.sim.grid[8][i]=TYPES.Tile.FLOOR
		game.sim.grid[i][8]=TYPES.Tile.FLOOR
	game.sim.grid[8][8]=TYPES.Tile.CORE
	var cells := [Vector2i(8,6),Vector2i(10,8)]
	game.sim.grid[6][8]=TYPES.Tile.DOOR
	game.sim.grid[8][10]=TYPES.Tile.MAGIC_DOOR
	var view: Node2D=game.get_node("PlayArea/World/Dungeon")
	view.rebuild(); inspect(view,"closed",false); await snapshot(game,view,"closed")
	game._visual_state=game._structure_hash()
	game.raid.hero={"display":"Review","lockpick_success_chance":1.0}
	game.raid._resolve_vulpin_lockpick(cells[0])
	game.raid._resolve_mage_arcane_open(cells[1])
	game.raid.hero.clear(); game.raid.raid_active=true; game.paused=false
	game._process(0) # Actual live structural refresh, not a manual view rebuild.
	game.raid.raid_active=false
	inspect(view,"unlocked",true); await snapshot(game,view,"unlocked")
	for p in cells: check(not game.sim._door_intact(p), "Unlocked door remains passable")
	# Reconstruct the saved logical state through the existing serialization path.
	var saved=game.Save.capture(game.sim,game.raid,game.progression)
	game.sim.new_map()
	check(game.Save.apply(saved,game.sim,game.raid,game.progression), "Door state must reload")
	view.rebuild(); inspect(view,"reloaded",true)
	game.raid.raid_active=true
	game.raid.hero={"pos":Vector2i(8,6),"name":"Neris","kind":"thief","level":1,"hp":100,"max_hp":100}
	view.rebuild()
	for gate in cells:
		var axis:=Vector2i.DOWN if gate.x==8 else Vector2i.RIGHT
		for step in [0,1]:
			for progress in [.25,.5,.75]:
				game.raid.hero.pos=gate+axis*step
				game.raid.hero.move_from=gate+axis*(step-1)
				game.raid.hero.step_started_at=0.0
				game.raid.elapsed_seconds=TYPES.TURN_TIME*progress
				view._update_markers(); await snapshot(game,view,"actor-%s-%d-%.2f" % ["n" if gate.x==8 else "w",step,progress])
	game.raid.raid_active=false; game.raid.hero.clear()
	game.sim.door_opened.clear()
	game.raid.raid_stats={"doors_destroyed":0}
	game.raid.hero={"display":"Review","door_damage":TYPES.DOOR_MAX_HP}
	for p in cells:
		game.sim.door_hp[p]=TYPES.DOOR_MAX_HP
		game.raid._apply_door_damage(p)
	game.raid.hero.clear()
	view.rebuild(); inspect(view,"forced",true); await snapshot(game,view,"forced")
	game.sim.gold=200
	for p in cells: check(game.sim.repair_door(p), "Existing repair action succeeds")
	view.rebuild(); inspect(view,"repaired",false)
	for p in cells: check(game.sim._door_intact(p), "Repair restores the blocking leaf")
	for p in cells: game.sim.grid[p.y][p.x]=TYPES.Tile.FLOOR
	view.rebuild(); inspect(view,"removed",false,true)
	check(not FileAccess.file_exists(game.save_path), "Review must not write a save")
	FileAccess.open(out+"results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"states":records},"\t"))
	game.queue_free(); await process_frame
	print("Open doors: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
