extends SceneTree
## Isolated import, packing, anchors and actual AnimatedSprite2D playback.
var failures: Array[String]=[]
var checks:=0
var manifest: Dictionary
var frames:=SpriteFrames.new()
var textures: Array[Texture2D]=[]
var parts: Dictionary={}
var review_root: String
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	review_root=ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	root.size=Vector2i(1100,840)
	for p in manifest.pages: textures.append(load("res://assets/"+p.file))
	for id in manifest.sprites:
		var s: Dictionary=manifest.sprites[id]
		var tex:=AtlasTexture.new()
		tex.atlas=textures[s.page];tex.region=Rect2(s.rect[0],s.rect[1],s.rect[2],s.rect[3])
		tex.margin=Rect2(s.crop[0],s.crop[1],manifest.canvas-s.crop[2],manifest.canvas-s.crop[3])
		tex.filter_clip=true;parts[id]=tex
		check(tex.get_size()==Vector2(manifest.canvas,manifest.canvas),"Virtual canvas "+id)
	frames.remove_animation("default")
	for name in manifest.clips:
		var c: Dictionary=manifest.clips[name]
		frames.add_animation(name);frames.set_animation_loop(name,c.loop);frames.set_animation_speed(name,c.frames.size()/float(c.seconds))
		for f in c.frames: frames.add_frame(name,parts[f.sprite])
		check(frames.get_frame_count(name)==c.frames.size(),"Count "+name)
		check(is_equal_approx(frames.get_frame_count(name)/frames.get_animation_speed(name),c.seconds),"Duration "+name)
	for d in ["se","sw","nw","ne"]:
		check(not frames.has_animation(d+"-death"),"No fall clip "+d)
		check(frames.get_frame_count(d+"-dead")==1 and not frames.get_animation_loop(d+"-dead"),"Static corpse "+d)
	check(ResourceSaver.save(frames,"res://vulpin.res")==OK,"Save SpriteFrames resource")
	var reload: SpriteFrames=load("res://vulpin.res")
	check(reload.get_animation_names().size()==32,"Reload 32 clips")
	# Render a representative trimmed frame of every action and facing at 1:1.
	var vp:=SubViewport.new();vp.size=Vector2i(manifest.canvas,manifest.canvas);vp.transparent_bg=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var sprite:=Sprite2D.new();sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;vp.add_child(sprite)
	var max_alpha_error:=0;var tested_ids: Array=[]
	for name in manifest.clips:
		var c: Dictionary=manifest.clips[name];var id: String=c.frames[c.frames.size()/2].sprite
		if tested_ids.has(id):continue
		tested_ids.append(id);sprite.texture=parts[id]
		await process_frame;await RenderingServer.frame_post_draw
		var native:=vp.get_texture().get_image()
		var original:=Image.load_from_file(review_root.path_join("frames/"+manifest.profile+"/"+id+".png"))
		var err:=0
		for y in range(native.get_height()):
			for x in range(native.get_width()):err=maxi(err,absi(roundi(native.get_pixel(x,y).a*255)-roundi(original.get_pixel(x,y).a*255)))
		max_alpha_error=maxi(max_alpha_error,err)
		check(err<=1,"Trimmed native alpha/anchor "+id+" max error="+str(err))
	vp.queue_free()
	# Playback all clips concurrently, freeze and check the actual frame clock.
	var actors: Array[AnimatedSprite2D]=[]
	for name in frames.get_animation_names():
		var actor:=AnimatedSprite2D.new();actor.sprite_frames=frames;root.add_child(actor);actor.visible=false;actor.play(name);actors.append(actor)
	await create_timer(1.85).timeout
	for actor in actors:
		var c: Dictionary=manifest.clips[String(actor.animation)]
		if not c.loop:check(not actor.is_playing() and actor.frame==c.frames.size()-1,"Non-loop holds final frame "+String(actor.animation))
		else:check(actor.is_playing(),"Loop still running "+String(actor.animation))
		actor.pause()
	var saved: Array=[]
	for a in actors:saved.append([a.frame,a.frame_progress])
	await create_timer(.12).timeout
	for i in actors.size():check(saved[i][0]==actors[i].frame and is_equal_approx(saved[i][1],actors[i].frame_progress),"Pause "+String(actors[i].animation));actors[i].queue_free()
	# Native review board at the same .75 world display scale across densities.
	var background:=Node2D.new();root.add_child(background)
	var states: Array=["idle","walk","run","hurt","lock-door","lock-chest","loot","dead"]
	var rows: Array=[]
	for i in states.size():
		var state: String=states[i];var x:=25+(i%3)*360;var y:=30+(i/3)*260
		var label:=Label.new();label.position=Vector2(x,y);label.text=manifest.clips["se-"+state].label;label.add_theme_font_size_override("font_size",19);root.add_child(label)
		for j in 4:
			var d: String=["se","sw","nw","ne"][j]
			var a:=AnimatedSprite2D.new();a.sprite_frames=frames;a.animation=d+"-"+state;a.centered=false
			a.offset=-Vector2(manifest.root[0],manifest.root[1]);a.scale=Vector2.ONE*.75/float(manifest.scale);a.position=Vector2(x+55+j%2*155,y+118+(j/2)*105);root.add_child(a);rows.append(a)
	await process_frame
	for a in rows:a.frame=frames.get_frame_count(a.animation)/2
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(review_root.path_join("native-"+manifest.profile+".png"))
	# Self-contained Godot resource bundle; intentionally no engine or APK.
	var pack_path:=review_root.path_join("vulpin-"+manifest.profile+".pck")
	var pack:=PCKPacker.new();check(pack.pck_start(pack_path)==OK,"Start pack")
	check(pack.add_file("res://vulpin.res",ProjectSettings.globalize_path("res://vulpin.res"))==OK,"Pack animation")
	var imported_bytes:=0
	for p in manifest.pages:
		var file: String="res://assets/"+p.file;var cfg:=ConfigFile.new();check(cfg.load(file+".import")==OK,"Read import config")
		check(cfg.get_value("params","compress/mode")==0,"Lossless import")
		check(cfg.get_value("params","mipmaps/generate")==false,"No mipmaps")
		var imported: String=cfg.get_value("remap","path");imported_bytes+=FileAccess.get_file_as_bytes(imported).size()
		check(pack.add_file(imported,ProjectSettings.globalize_path(imported))==OK,"Pack ctex")
		check(pack.add_file(file+".import",ProjectSettings.globalize_path(file+".import"))==OK,"Pack texture import remap")
	check(pack.flush()==OK,"Finish pack")
	var report: Dictionary={"profile":manifest.profile,"checks":checks,"failures":failures,"animationResourceBytes":FileAccess.get_file_as_bytes("res://vulpin.res").size(),"importedTextureBytes":imported_bytes,"pckBytes":FileAccess.get_file_as_bytes(pack_path).size(),"nativeAlphaMaxError":max_alpha_error,"nativeAnchorCases":tested_ids.size(),"scope":"Isolated native desktop import/playback and dependency-complete resource pack. No APK, final paint or mobile profiling."}
	FileAccess.open(review_root.path_join("godot-"+manifest.profile+".json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
