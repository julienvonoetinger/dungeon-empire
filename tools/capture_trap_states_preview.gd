extends SceneTree
## Native presentation capture, with no session or persistence involved.
const SCENE=preload("res://scenes/DungeonTraps.tscn")
var OUT="res://docs/reference/trap-review/v8-state-scene/"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): OUT=arg.trim_prefix("--output=").trim_suffix("/")+"/"
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1280,720)
	var scene:=SCENE.instantiate()
	root.add_child(scene)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	var error:=root.get_texture().get_image().save_png(OUT+"overview.png")
	var inventory: Array=[]
	for node in scene.find_children("*","Sprite2D",true,false):
		if node.has_meta("prepared_id"): inventory.append(str(node.get_meta("prepared_id")))
	inventory.sort()
	var file:=FileAccess.open(OUT+"native-inventory.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"scene":SCENE.resource_path,"capture_error":error,"prepared_sprites":inventory},"\t"))
	file.close()
	print("Trap state scene: ",inventory.size()," prepared layers; capture error=",error)
	scene.queue_free(); await process_frame
	quit(0 if error==OK else 1)
