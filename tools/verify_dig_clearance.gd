extends SceneTree
## Compare the same masonry with guides hidden/shown; no player saves.
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/dig-clearance/"
var checks:=0
var failures: Array[String]=[]
var samples: Array[Dictionary]=[]
var texture_images: Dictionary={}

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func settle() -> void:
	for i in 8: await process_frame
func opaque_paint(node: Node2D, world: Vector2) -> bool:
	if not node.is_visible_in_tree(): return false
	if node is Sprite2D:
		var point:=node.to_local(world)
		var rect: Rect2=node.get_rect()
		if rect.has_point(point):
			var texture: Texture2D=node.texture
			if not texture_images.has(texture): texture_images[texture]=texture.get_image()
			var painted: Image=texture_images[texture]
			var uv: Vector2=(point-rect.position)/rect.size*Vector2(painted.get_size())-Vector2(.5,.5)
			var solid:=true
			# Every texel contributing to bilinear filtering must be opaque.
			for delta in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
				var pixel: Vector2i=Vector2i(uv.floor())+delta
				pixel=Vector2i(clampi(pixel.x,0,painted.get_width()-1),clampi(pixel.y,0,painted.get_height()-1))
				if painted.get_pixelv(pixel).a<.999: solid=false; break
			if solid: return true
	for child in node.get_children():
		if child is Node2D and opaque_paint(child,world): return true
	return false
func masonry_interior(view: Node2D, local: Vector2, canvas: Transform2D) -> bool:
	# Exclude translucent sprite fringes: seeing a guide through partial alpha
	# is expected compositing, not paint over an opaque masonry face.
	for part in view.solid_groups:
		if not (part.id.begins_with("wall-") or part.id.begins_with("door-") or part.id=="pillar"): continue
		if not part.rect.has_point(local): continue
		var interior:=true
		for delta in [Vector2.ZERO,Vector2(3,0),Vector2(-3,0),Vector2(0,3),Vector2(0,-3),Vector2(3,3),Vector2(-3,3),Vector2(3,-3),Vector2(-3,-3)]:
			var p: Vector2=local+canvas.basis_xform_inv(delta)
			if not opaque_paint(part.node,view.to_global(p)): interior=false; break
		if interior: return true
	return false
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var preview=SCENE.instantiate(); root.add_child(preview); await settle()
	var view=preview.game.get_node("PlayArea/World/Dungeon")
	var hud=preview.game.get_node("HUD")
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
		root.size=extent; await settle(); preview.center_review(); await settle()
		view.dig_guides_visible=false; await settle(); await RenderingServer.frame_post_draw
		var clean:=root.get_texture().get_image()
		view.dig_guides_visible=true; await settle(); await RenderingServer.frame_post_draw
		var marked:=root.get_texture().get_image()
		# The floating tools intentionally draw over walls. Isolate the ground layer
		# for the pixel and touch checks, keeping the full scene for the review PNG.
		for block in preview.targets.blocks: block.preview.hide()
		await settle(); await RenderingServer.frame_post_draw
		var ground:=root.get_texture().get_image()
		var canvas: Transform2D=view.get_global_transform_with_canvas()
		var image_scale:=Vector2(marked.get_size())/root.get_visible_rect().size
		var stained:=0
		var intercepted:=0
		var masonry_samples:=0
		var tested: Dictionary={}
		var examples: Array[Dictionary]=[]
		for block in preview.targets.blocks:
			var screen_bounds: Rect2=canvas*block.support.rect
			screen_bounds=Rect2(screen_bounds.position*image_scale,screen_bounds.size*image_scale)
			for y in range(maxi(0,ceili(screen_bounds.position.y)),mini(marked.get_height(),ceili(screen_bounds.end.y)),2):
				for x in range(maxi(0,ceili(screen_bounds.position.x)),mini(marked.get_width(),ceili(screen_bounds.end.x)),2):
					var pixel:=Vector2i(x,y)
					if tested.has(pixel): continue
					tested[pixel]=true
					var screen: Vector2=(Vector2(pixel)+Vector2(.5,.5))/image_scale
					var local: Vector2=canvas.affine_inverse()*screen
					if not block.covers(local) or hud.blocks_pointer(screen): continue
					if not masonry_interior(view,local,canvas): continue
					masonry_samples+=1
					var a:=clean.get_pixel(x,y); var b:=ground.get_pixel(x,y)
					var changed:=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>.025
					if changed: stained+=1
					var picked: bool=preview.targets.hit_cell(screen/hud.scale.x).x>=0
					if picked: intercepted+=1
					if (changed or picked) and examples.size()<12:
						var ids: Array[String]=[]
						for part in view.solid_groups:
							if view._opaque_at(part.node,view.to_global(local)): ids.append(part.id)
						examples.append({"pixel":str(pixel),"cell":str(block.cell),"changed":changed,"picked":picked,"ids":ids})
		samples.append({"size":str(extent),"masonry_samples":masonry_samples,"stained":stained,"intercepted":intercepted,"examples":examples})
		check(stained==0,"Excavation volumes leave masonry pixels intact at "+str(extent)+": "+str(stained)+" tinted samples")
		check(intercepted==0,"Excavation does not intercept masonry at "+str(extent)+": "+str(intercepted)+" samples")
		marked.save_png(OUT+"%dx%d.png" % [extent.x,extent.y])
		for block in preview.targets.blocks: block.preview.show()
	check(not preview.game.persistence_enabled,"Clearance fixture never accesses player saves")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples},"\t"))
	print("Dig clearance: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
