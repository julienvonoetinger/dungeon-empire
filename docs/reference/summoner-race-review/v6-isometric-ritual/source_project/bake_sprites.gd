extends SceneTree
## Bake the live diorama before the interface and its screen-space threshold.
const STAGE = preload("res://scripts/game/ritual_glade.gd")
func _initialize() -> void: bake.call_deferred()

func take(vp: SubViewport, path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if vp.get_texture().get_image().save_png(path) != OK:
		push_error("Cannot write "+path)
		quit(1)

func bake() -> void:
	var output := OS.get_cmdline_user_args()[0]
	var vp := SubViewport.new()
	vp.size = Vector2i(1536,1536)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage = STAGE.new()
	vp.add_child(stage)
	# This rig parent is anchored at the soles on the altar-side flagstone.
	var invoker: Node3D = stage.find_child("Oculin", true, false)
	invoker.scale *= .68
	stage.set_moment(3.)
	stage.camera.size = 14.
	var character := stage.find_children("output_unwrapped","MeshInstance3D",true,false)[0]
	character.hide()
	stage.rift.hide()
	stage.entity.hide()
	stage.dust.hide()
	await take(vp,output+"/plate.png")
	# Same camera for the transparent action pass. Keep original lights and skeleton.
	vp.transparent_bg = true
	for mesh in stage.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["Stone","Etching","Glow"] or mesh.material_override == stage.stone_ink:
			mesh.hide()
	character.show()
	stage.rift.show()
	# The painted master is composited separately by the ritual shader.
	stage.dust.show()
	# 0..32: invocation, 33..40: gentle held motion, 41..45: departure.
	for i in 46:
		if i < 41: stage.set_moment(i/8.)
		else: stage.set_moment(4.5+(i-41)*.1,(i-41)/4.)
		stage.camera.size = 14.
		await take(vp,output+"/frame-%02d.png"%i)
	quit()
