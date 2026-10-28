extends SceneTree
## Isolated artwork presentation: no hero logic, production asset or save change.
const GAME=preload("res://scenes/game/DungeonGame.tscn")
const TYPES=preload("res://scripts/game/game_types.gd")
const OUT="res://docs/reference/vulpin-review/v2-approved-design/"
var game: Node
var view: Node2D
var actor: Sprite2D
var records: Array=[]
var prepared_height:=112.0

class ContactShadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,Vector2(1,.5))
		draw_circle(Vector2.ZERO,25,Color(0,0,0,.28))
		draw_circle(Vector2.ZERO,17,Color(0,0,0,.14))

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	run.call_deferred()

func capture(label: String) -> void:
	for frame in 7: await process_frame
	game.frame_updated.emit() # Session is frozen; fit badges to the settled viewport.
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var error:=image.save_png(OUT+label+".png")
	assert(error==OK)
	var screen:=view.get_canvas_transform()*actor.position
	var factor:=Vector2(root.size)/root.get_visible_rect().size
	records.append({"label":label,"size":[image.get_width(),image.get_height()],"hero_ground_screen":[screen.x*factor.x,screen.y*factor.y],"sprite_visible_height_px":prepared_height*view.get_canvas_transform().get_scale().y*factor.y})

func run() -> void:
	root.size=Vector2i(1280,720)
	game=GAME.instantiate()
	game.save_path=OUT+"never-created.save"
	root.add_child(game); game.set_process(false)
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
	view=game.get_node("PlayArea/World/Dungeon")
	for frame in 5: await process_frame
	var metadata=JSON.parse_string(FileAccess.get_file_as_string(OUT+"asset.json"))
	prepared_height=float(metadata.visible_height)
	actor=Sprite2D.new()
	actor.name="VulpinVisualProposal"
	actor.texture=ImageTexture.create_from_image(Image.load_from_file(OUT+"vulpin-128.png"))
	actor.centered=false
	actor.offset=-Vector2(metadata.anchor[0],metadata.anchor[1])
	actor.z_index=1
	var at:=Vector2(7.5,8.0)
	actor.position=view.grid_to_local(at)
	view._world.add_child(actor)
	var shadow:=ContactShadow.new()
	shadow.position=actor.position
	shadow.z_index=0
	view._world.add_child(shadow)
	view._actor=actor # Reuse native physical ordering, without simulating a raid.
	view._order_actor(view._proxy(at,.65,actor))
	view._actor=null # Presentation sprite must not be hidden by the empty raid state.
	var camera: Camera2D=game.get_node("PlayArea/World/Camera2D")
	camera.position=view.grid_to_local(Vector2(8.3,7.8))+Vector2(0,-25)
	camera.force_update_scroll()
	await capture("landscape-1280")
	root.size=Vector2i(844,390)
	for frame in 7: await process_frame
	camera.force_update_scroll()
	await capture("mobile-844")
	root.size=Vector2i(390,844)
	for frame in 7: await process_frame
	camera.position=view.grid_to_local(at)+Vector2(0,-40)
	camera.force_update_scroll()
	await capture("portrait-390")
	assert(not FileAccess.file_exists(game.save_path))
	FileAccess.open(OUT+"native-captures.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	game.queue_free(); await process_frame
	print("Vulpin proposal: three native captures; no save written.")
	quit(0)
