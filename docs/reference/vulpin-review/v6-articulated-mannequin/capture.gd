extends SceneTree
## Four geometric mannequins in native paving, with stride matched to the rig.
## Isolated presentation only; no raid, hero replacement or save access.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const TYPES=preload("res://scripts/game/game_types.gd")
const OUT="res://docs/reference/vulpin-review/v6-articulated-mannequin/"
var game: Node
var actors: Array=[]
var contacts: Dictionary={}
var max_stance_drift:=0.0

class Shadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,Vector2(1,.5))
		draw_circle(Vector2.ZERO,19,Color(0,0,0,.22))

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): quit(2))
	run.call_deferred()

func run() -> void:
	root.size=Vector2i(1280,720)
	game=GAME.instantiate()
	game.save_path=OUT+"never-created.save"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.sim.new_map()
	for y in range(6,11):
		for x in range(6,11): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[6][10]=TYPES.Tile.CORE
	game.changed.emit(true)
	var view=game.get_node("PlayArea/World/Dungeon")
	var meta=JSON.parse_string(FileAccess.get_file_as_string(OUT+"rig.json"))
	var poses=JSON.parse_string(FileAccess.get_file_as_string(OUT+"pose-data.json"))
	for frame in 5: await process_frame
	var starts={"se":Vector2(7,7),"sw":Vector2(9,7),"nw":Vector2(9,9),"ne":Vector2(7,9)}
	var directions={"se":Vector2.RIGHT,"sw":Vector2.DOWN,"nw":Vector2.LEFT,"ne":Vector2.UP}
	for d in ["se","sw","nw","ne"]:
		var frames=SpriteFrames.new()
		frames.add_animation("walk")
		frames.set_animation_speed("walk",30)
		var atlas=ImageTexture.create_from_image(Image.load_from_file(OUT+"atlas-"+d+".png"))
		for i in range(24):
			var part=AtlasTexture.new()
			part.atlas=atlas
			part.region=Rect2(i%6*160,floori(i/6.0)*160,160,160)
			frames.add_frame("walk",part)
		var actor=AnimatedSprite2D.new()
		actor.name="Mannequin_"+d
		actor.sprite_frames=frames;actor.animation="walk"
		actor.centered=false;actor.offset=-Vector2(meta.root[0],meta.root[1]);actor.z_index=1
		view._world.add_child(actor)
		var shadow=Shadow.new();view._world.add_child(shadow)
		actors.append({"d":d,"node":actor,"shadow":shadow})
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(8.1,8.1))+Vector2(0,-40)
	camera.force_update_scroll()
	for frame in 7: await process_frame
	game.frame_updated.emit()
	DirAccess.make_dir_recursive_absolute(OUT+"native")
	for i in range(49):
		var t:=i/24.0
		var frame:=i%24
		for item in actors:
			var d: String=item.d
			var actor: AnimatedSprite2D=item.node
			var at: Vector2=starts[d]+directions[d]*float(meta.strideCells)*t
			actor.position=view.grid_to_local(at);actor.frame=frame
			item.shadow.position=actor.position
			view._actor=actor;view._order_actor(view._proxy(at,.72,actor));view._actor=null
			for side in ["L","R"]:
				if not poses[d][frame].contact[side]:continue
				var p=poses[d][frame].feet[side]
				var sole=actor.position+Vector2(p[0]-meta.root[0],p[1]-meta.root[1])
				var cycle=floori(t+(0.5 if side=="R" else 0.0)+.00000001)
				var key=d+side+str(cycle)
				if not contacts.has(key):contacts[key]=sole
				max_stance_drift=maxf(max_stance_drift,sole.distance_to(contacts[key]))
		await process_frame
		await RenderingServer.frame_post_draw
		var full=root.get_texture().get_image()
		assert(full.get_region(Rect2i(240,100,800,560)).save_png(OUT+"native/frame-%02d.png"%i)==OK)
		if i==0:assert(full.save_png(OUT+"native/landscape.png")==OK)
	assert(max_stance_drift<.002,"Projected foot drifts off paving")
	assert(not FileAccess.file_exists(game.save_path))
	FileAccess.open(OUT+"native-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"directions":4,"captures":49,"duration_seconds":1.6,"stride_cells_per_cycle":meta.strideCells,"max_stance_drift_world_canvas_pixels":max_stance_drift,"contact_groups":contacts.size(),"save_written":false,"note":"Native texture roots and path agree with Blender sole landmarks. Measures landmarks, not painted pixel edges. Native gameplay movement speed untouched; fixture uses the rig stride."},"\t"))
	game.queue_free();await process_frame
	print("Mannequin: 4 directions,49 native frames; stance drift=",max_stance_drift,"; no save.")
	quit(0)
