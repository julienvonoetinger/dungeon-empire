extends SceneTree
## Render the real header against transparency: opaque stone must not acquire
## a vertical hole where its independently sized pieces meet. No game/save.
const HEADER = preload("res://scripts/game/ui/hud_master_header.gd")
const OUT = "res://artifacts/header-seams/"
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("run")

func run() -> void:
	create_timer(30).timeout.connect(func(): push_error("Header seams timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1800,400)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var header = HEADER.new()
	header.theme = header.UI.create()
	viewport.add_child(header)
	for child in header.get_children(): child.visible = child == header.band or child == header.eye
	var records: Array = []
	for extent in [Vector2(760,96),Vector2(556,84),Vector2(378,96),Vector2(308,96),Vector2(761,96)]:
		for display_scale in [1.0,1.25,1.5,2.0]:
			header.size = extent
			header.scale = Vector2.ONE * display_scale
			header.position = Vector2(16.25,16.25)
			header._layout()
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var frame := viewport.get_texture().get_image()
			var context := "%dx%d-scale%.2f" % [extent.x,extent.y,display_scale]
			for seam in [header.eye.position.x,header.eye.get_rect().end.x]:
				var x: float = header.position.x + float(seam) * display_scale
				var minimum := 1.0
				for sy in range(ceili(header.position.y + extent.y * .36 * display_scale),floori(header.position.y + extent.y * .65 * display_scale)):
					for sx in range(floori(x)-1,ceili(x)+2):
						minimum = minf(minimum,frame.get_pixel(sx,sy).a)
				checks += 1
				var record := {"case":context,"seam_x":x,"minimum_alpha":minimum}
				records.append(record)
				if minimum < .99:
					failures.append("%s seam x=%.3f exposes background (alpha=%.3f)" % [context,x,minimum])
			frame.get_region(Rect2i(0,0,ceili(extent.x*display_scale)+34,ceili(extent.y*display_scale)+34)).save_png(OUT+context+".png")
	header.free(); viewport.free()
	var report := {"checks":checks,"failures":failures,"samples":records}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
