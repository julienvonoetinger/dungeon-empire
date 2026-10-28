extends SceneTree
## Isolated animation fixture. No production actor integration or player save.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const TYPES=preload("res://scripts/game/game_types.gd")
const OUT="res://docs/reference/vulpin-review/v5-walk-pilot/"
var game: Node
var actor: AnimatedSprite2D
var sequence: Array=[]
var loops:=0

class ContactShadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,Vector2(1,.5))
		draw_circle(Vector2.ZERO,23,Color(0,0,0,.22))

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	run.call_deferred()

func run() -> void:
	root.size=Vector2i(1280,720)
	game=GAME.instantiate()
	game.save_path=OUT+"never-created.save"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.sim.new_map()
	for y in range(6,10):
		for x in range(6,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	for x in range(10,13): game.sim.grid[7][x]=TYPES.Tile.FLOOR
	game.sim.grid[6][7]=TYPES.Tile.VAULT
	game.sim.vault_gold[Vector2i(7,6)]=95
	game.sim.grid[6][9]=TYPES.Tile.CORE
	game.sim.grid[7][11]=TYPES.Tile.DOOR
	game.sim.grid[8][8]=TYPES.Tile.SPIKE
	game.changed.emit(true)
	var view=game.get_node("PlayArea/World/Dungeon")
	for frame in 5: await process_frame
	var metadata=JSON.parse_string(FileAccess.get_file_as_string(OUT+"animation.json"))
	var texture=ImageTexture.create_from_image(Image.load_from_file(OUT+"walk-atlas.png"))
	var sprites=SpriteFrames.new()
	sprites.add_animation("walk")
	sprites.set_animation_speed("walk",8.0/float(metadata.cycleSeconds))
	sprites.set_animation_loop("walk",true)
	for i in range(8):
		var region=AtlasTexture.new()
		region.atlas=texture
		region.region=Rect2(i%4*160,floori(i/4.0)*160,160,160)
		sprites.add_frame("walk",region)
	actor=AnimatedSprite2D.new()
	actor.name="VulpinWalkPilot"
	actor.sprite_frames=sprites
	actor.animation="walk"
	actor.centered=false
	actor.offset=-Vector2(metadata.root[0],metadata.root[1])
	actor.z_index=1
	var at=Vector2(7.5,8.0)
	actor.position=view.grid_to_local(at)
	view._world.add_child(actor)
	var shadow=ContactShadow.new()
	shadow.position=actor.position
	view._world.add_child(shadow)
	view._actor=actor
	view._order_actor(view._proxy(at,.65,actor))
	view._actor=null
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(8.3,7.8))+Vector2(0,-25)
	camera.force_update_scroll()
	for frame in 7: await process_frame
	game.frame_updated.emit()
	DirAccess.make_dir_recursive_absolute(OUT+"native")
	var ground=view.get_canvas_transform()*actor.position
	var crop=Rect2i(roundi(ground.x)-192,roundi(ground.y)-166,384,256)
	for i in range(8):
		actor.frame=i
		await process_frame
		await RenderingServer.frame_post_draw
		var full=root.get_texture().get_image()
		assert(full.get_region(crop).save_png(OUT+"native/frame-%d.png"%i)==OK)
		if i==0: assert(full.save_png(OUT+"native/landscape.png")==OK)
	actor.frame=0
	actor.frame_changed.connect(func(): sequence.append(actor.frame))
	actor.animation_looped.connect(func(): loops+=1)
	actor.play("walk")
	await create_timer(1.75).timeout
	actor.pause()
	var paused_frame=actor.frame
	await create_timer(.25).timeout
	assert(actor.frame==paused_frame)
	assert(loops>=2)
	assert(not FileAccess.file_exists(game.save_path))
	FileAccess.open(OUT+"native-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"captures":8,"sequence":sequence,"loops":loops,"paused_frame_stable":true,"save_written":false,"crop":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"note":"Actual AnimatedSprite2D atlas playback in isolated native fixture; no foot-slip oracle or gameplay integration."},"\t"))
	game.queue_free()
	await process_frame
	print("Vulpin pilot: 8 native captures, looping playback and pause; no save written.")
	quit(0)
