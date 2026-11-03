extends SceneTree
## Native review only. All types use the same corridor, framing and stone layers.
const Stage = preload("res://docs/reference/door-redesign/seal-v1/v17-door-materials/stage.gd")
const InputScript = preload("res://scripts/game/game_input.gd")
const OUT := "res://docs/reference/door-redesign/seal-v1/v17-door-materials/vues/"
const SIZE := Vector2i(460, 320)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = SIZE
	var bg := ColorRect.new()
	bg.color = Color("111825")
	bg.size = SIZE
	root.add_child(bg)
	for direction in ["ne","nw","sw","se"]:
		for variant: String in ["wood","arcane","iron","wood-ajar","arcane-ajar","iron-ajar","grille","open"]:
			var stage := Stage.new()
			stage.material_id = "grille" if variant == "open" else variant.trim_suffix("-ajar")
			stage.ajar = variant.ends_with("-ajar")
			stage.opened = variant == "open"
			bg.add_child(stage)
			stage.build(direction)
			assert(stage.registration_error() < .01)
			stage.actor.hide()
			stage._contact.hide()
			var cell := Vector2(1.5,.5) if stage.CONFIG[direction].axis == 0 else Vector2(.5,1.5)
			stage.scale = Vector2.ONE * InputScript.FIXED_ZOOM
			stage.position = Vector2(230,194) - stage.grid_to_local(cell) * stage.scale
			await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			if img.get_size()!=SIZE or img.save_png(OUT+variant+"-"+direction+".png")!=OK:
				printerr("Failed to capture ",variant," ",direction)
				quit(1)
				return
			stage.free()
	print("Captured all four textures and clear passage on four approaches at the fixed raid zoom.")
	quit()
