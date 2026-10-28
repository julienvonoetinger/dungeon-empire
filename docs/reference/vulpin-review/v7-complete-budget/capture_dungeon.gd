extends SceneTree
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const TYPES=preload("res://scripts/game/game_types.gd")
const OUT="res://docs/reference/vulpin-review/v7-complete-budget/"
var game: Node
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var disk_out:=ProjectSettings.globalize_path(OUT)
	assert(ProjectSettings.load_resource_pack(OUT+"vulpin-balanced.pck"))
	var frames: SpriteFrames=load("res://vulpin.res")
	var manifest=JSON.parse_string(FileAccess.get_file_as_string(OUT+"projects/balanced/manifest.json"))
	game=GAME.instantiate();game.save_path=disk_out+"never-created.save";root.add_child(game);game.set_process(false)
	await process_frame
	game.sim.new_map()
	for y in range(6,11):
		for x in range(6,11):game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[6][10]=TYPES.Tile.CORE;game.changed.emit(true)
	var view=game.get_node("PlayArea/World/Dungeon")
	for i in 5:await process_frame
	var placements=[{"at":Vector2(7,7),"clip":"se-walk","direction":Vector2.RIGHT,"stride":.176},{"at":Vector2(9,7),"clip":"sw-run","direction":Vector2.DOWN,"stride":.256},{"at":Vector2(7,9),"clip":"se-lock-chest","direction":Vector2.ZERO,"stride":0},{"at":Vector2(9,9),"clip":"sw-death","direction":Vector2.ZERO,"stride":0}]
	for item in placements:
		var actor:=AnimatedSprite2D.new();actor.sprite_frames=frames;actor.animation=item.clip;actor.centered=false
		actor.offset=-Vector2(manifest.root[0],manifest.root[1]);actor.scale=Vector2.ONE/manifest.scale;actor.z_index=1;view._world.add_child(actor);item.node=actor
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(8.1,8.1))+Vector2(0,-40);camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(disk_out+"native")
	for i in 49:
		var time:=i/24.0
		for item in placements:
			var c: Dictionary=manifest.clips[item.clip];var actor: AnimatedSprite2D=item.node
			var at: Vector2=item.at+item.direction*float(item.stride)*time/c.seconds
			actor.position=view.grid_to_local(at)
			actor.frame=mini(c.frames.size()-1,floori((fmod(time,c.seconds) if c.loop else minf(time,c.seconds-.00001))/c.seconds*c.frames.size()))
			view._actor=actor;view._order_actor(view._proxy(at,.72,actor));view._actor=null
		await process_frame;await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image().get_region(Rect2i(240,100,800,520))
		assert(image.save_png(disk_out+"native/frame-%02d.png"%i)==OK)
	assert(not FileAccess.file_exists(game.save_path))
	FileAccess.open(disk_out+"dungeon-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"captures":49,"profile":"balanced","directions":2,"actions":["walk","run","lock-chest","death"],"save_written":false,"note":"Static native sampling of imported pack in real dungeon. Demonstration stride matched to rig; actual gameplay speeds unchanged and not synchronized."},"\t"))
	game.queue_free();await process_frame;print("49 native dungeon captures; packed balanced resource; no save.");quit(0)
