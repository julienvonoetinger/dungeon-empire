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
	check(doors.size() == (0 if removed else 6 if open_frame else 8), state + ": independent jambs/crowns and closed panels on both doors")
	for cell in [Vector2i(8,6),Vector2i(10,8)]:
		var cell_parts := doors.filter(func(p): return Vector2i(p.at)==cell)
		var roles := cell_parts.map(func(p): return view._definition.entries[p.id].get("door_part", ""))
		check(roles.count("jamb-left")==int(not removed) and roles.count("jamb-right")==int(not removed) and roles.count("crown")==int(not removed), state+": complete frame per door")
		check(roles.count("panel")==int(not removed and not open_frame),state+": panel exists only while closed")
		if not removed and not open_frame:
			var panel_id := "door-north-panel" if cell.x==8 else "door-west-arcane-panel"
			check(cell_parts.any(func(p): return p.id==panel_id),state+": correct material for "+panel_id)
		var across := Vector2i.RIGHT if cell.x==8 else Vector2i.DOWN
		var wall_prefix := "wall-v-" if cell.x==8 else "wall-h-"
		for at: Vector2i in [cell,cell+across]:
			var walls: Array = view.solid_groups.filter(func(p): return str(p.id).begins_with(wall_prefix) and Vector2i(p.at)==at)
			check(walls.size()==1,state+": one continuous wall at "+str(at))
	check(segments.is_empty(),state+": no rail cuts below the segmental frame")
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
	game.persistence_enabled=false
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
	game.raid.hero={"kind":"thief","display":"Review","lockpick_success_chance":1.0}
	game.raid._resolve_vulpin_lockpick(cells[0])
	game.raid.hero = {"kind":"mage","display":"Review","intelligence":100,"arcane_door_rolls":{}}
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
		game.raid.hero.pos=gate
		game.raid.hero.erase("move_from")
		game.raid.hero.erase("step_started_at")
		view._update_markers()
		var jambs: Array=view.solid_groups.filter(func(p): return Vector2i(p.at)==gate and str(p.id).begins_with("door-") and str(view._definition.entries[p.id].get("door_part", "")).begins_with("jamb"))
		jambs.sort_custom(func(a,b): return a.depth<b.depth)
		check(jambs.size()==2,"Gameplay retains two independent jamb supports")
		if jambs.size()==2:
			check(jambs[0].node.get_index()<view._actor.get_index(),"Gameplay cached order: far jamb behind actor")
			check(view._actor.get_index()<jambs[1].node.get_index(),"Gameplay cached order: near jamb in front of actor")
		var axis:=Vector2i.DOWN if gate.x==8 else Vector2i.RIGHT
		for step in [0,1]:
			for progress in [.25,.5,.75]:
				game.raid.hero.pos=gate+axis*step
				game.raid.hero.move_from=gate+axis*(step-1)
				game.raid.hero.step_started_at=0.0
				game.raid.elapsed_seconds=TYPES.TURN_TIME*progress
				view._update_markers(); await snapshot(game,view,"actor-%s-%d-%.2f" % ["n" if gate.x==8 else "w",step,progress])
	game.raid.raid_active=false; game.raid.hero.clear()
	for p in cells:
		game.sim.door_opened.erase(p)
		game.sim.door_hp[p]=TYPES.DOOR_MAX_HP
	game.raid.raid_stats={"doors_destroyed":0}
	game.raid.hero={"kind":"paladin","display":"Review","door_damage":TYPES.DOOR_MAX_HP,"strength":100,"door_force_rolls":{}}
	check(game.raid._try_force_door(cells[0]),"Force destroys the wooden door")
	check(not game.raid._try_force_door(cells[1]) and game.sim._door_intact(cells[1]),"Force leaves the arcane seal intact")
	game.raid.hero={"kind":"mage","display":"Review","intelligence":100,"arcane_door_rolls":{}}
	game.raid._resolve_mage_arcane_open(cells[1])
	game.raid.hero.clear()
	view.rebuild(); inspect(view,"forced",true); await snapshot(game,view,"forced")
	game.sim.gold=200
	for p in cells: check(game.sim.repair_door(p), "Existing repair action succeeds")
	view.rebuild(); inspect(view,"repaired",false)
	for p in cells: check(game.sim._door_intact(p), "Repair restores the blocking leaf")
	var gate: Vector2i = cells[0]
	game.sim.grid[gate.y][gate.x] = TYPES.Tile.REINFORCED_DOOR
	game.sim.door_hp[gate] = 60
	view.rebuild()
	check(view.solid_groups.any(func(p): return Vector2i(p.at)==gate and p.id=="door-north-iron-panel"), "Reinforced gate uses the iron panel")
	for item in view._markers:
		if item.cell == gate and item.kind == "door":
			check(is_equal_approx(item.node.badge.ratio,.5), "60 HP fills half the reinforced door ring")
	var hud = game.get_node("HUD")
	game.progression.xp = 60
	hud._open_catalog(1)
	check(not hud.catalog.cards.any(func(card): return card.id==TYPES.Tool.BUILD_REINFORCED_DOOR and card.button.visible), "Legacy iron doors remain inspectable while new construction stays locked")
	hud._close_catalog()
	game.tool = TYPES.Tool.NONE
	game.selected = gate
	hud.selection.refresh()
	check(hud.selection.title.text=="Reinforced door" and hud.selection.detail.text=="60 / 120 HP", "Inspecting the iron gate shows its material and resistance")
	await snapshot(game,view,"reinforced")
	for p in cells: game.sim.grid[p.y][p.x]=TYPES.Tile.FLOOR
	view.rebuild(); inspect(view,"removed",false,true)
	check(not FileAccess.file_exists(game.save_path), "Review must not write a save")
	FileAccess.open(out+"results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"states":records},"\t"))
	game.queue_free(); await process_frame
	print("Open doors: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
