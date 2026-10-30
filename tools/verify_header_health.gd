extends SceneTree
## Inspect actual glyph ink against the painted lip, not the whole header rect.
const HEADER=preload("res://scripts/game/ui/hud_master_header.gd")
const SESSION=preload("res://scripts/game/game_session.gd")
const OUT="res://artifacts/header-health/"
var failures: Array[String]=[]
var checks:=0

func _initialize() -> void: call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)

func draw_frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var viewport:=SubViewport.new(); viewport.size=Vector2i(1280,400)
	viewport.transparent_bg=true; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game=SESSION.new(); game.persistence_enabled=false; root.add_child(game)
	game.set_process(false); game.restart(true)
	var header=HEADER.new(); header.theme=header.UI.create(); viewport.add_child(header)
	var records: Array=[]
	for extent: Vector2 in [Vector2(760,96),Vector2(556,84),Vector2(378,96),Vector2(308,96)]:
		header.size=extent
		for hp in [100,60,9,0]:
			game.sim.core_hp=hp; header.refresh(game); header._layout()
			for child in header.get_children(): child.visible=true
			await draw_frame()
			if hp==100:
				viewport.get_texture().get_image().get_region(Rect2i(Vector2i.ZERO,Vector2i(extent))).save_png(OUT+"%d-header.png" % extent.x)
			for child in header.get_children(): child.visible=child==header.health
			await draw_frame()
			var ink:=viewport.get_texture().get_image().get_used_rect()
			# Common rectangular interior of the trapezoidal stone lip in the
			# prepared230x192 centre slice; excludes its raised bevels.
			var art_scale:=extent.y/192.0
			var lip:=Rect2(header.eye.position+Vector2(76,166)*art_scale,Vector2(78,18)*art_scale)
			check(lip.grow(.5).encloses(Rect2(ink)),"HP%d at%s: painted lip %s does not contain glyph ink%s" % [hp,extent,lip,ink])
			check(header.health.text=="%d %%" % hp,"Full percentage is preserved")
			records.append({"extent":str(extent),"hp":hp,"lip":str(lip),"ink":str(ink)})
	header.size=Vector2(308,96); header.scale=Vector2.ONE*4
	game.sim.core_hp=100; header.refresh(game); header._layout()
	for child in header.get_children(): child.visible=true
	await draw_frame()
	viewport.get_texture().get_image().get_region(Rect2i(header.eye.get_rect().position*4,header.eye.size*4)).save_png(OUT+"eye-detail.png")
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records},"\t"))
	header.free(); game.free(); viewport.free()
	print("Header health: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
