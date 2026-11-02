extends "res://docs/reference/treasury-review/v3-salle-ouverte/capture.gd"
## The same camera and cell layout for both wall studies; no save file is opened.
const REVIEW := "res://docs/reference/treasury-review/v4-murs-de-salle/"

func capture() -> void:
	stage.size = Vector2i(960,600)
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var game := IsometricGameSession.new()
	game.persistence_enabled = false
	var terrain := Terrain.new()
	game.add_child(terrain)
	terrain.owner = game
	view = Renderer.new()
	game.add_child(view)
	stage.add_child(game)
	game.set_process(false)
	var cells := {}
	for p in ROOM + PASSAGE:
		game.sim.grid[p.y][p.x] = Types.Tile.FLOOR
		cells[p] = true
	game.changed.emit(true)
	var camera := Camera2D.new()
	stage.add_child(camera)
	camera.zoom = Vector2(1.28,1.28)
	camera.position = view.grid_to_local(CENTER) + Vector2(-27,-28)
	view.render_plan({"cells":cells,"openings":{},"floor_variants":true,"wall_variants":true}, {}, true, false)
	await snap("salle-nue")
	var img := Image.load_from_file(OUT + "source/eboulis.png")
	var crop := img.get_region(Rect2i(332,277,994,354).grow(45))
	crop.generate_mipmaps()
	var hoard := Sprite2D.new()
	hoard.texture = ImageTexture.create_from_image(crop)
	hoard.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Tuck the mound inside the perimeter so neither near pilaster clips its edge.
	hoard.scale = Vector2.ONE * (248.0 / 994.0)
	hoard.position = view.grid_to_local(CENTER) + Vector2(0,-22)
	hoard.light_mask = 0
	view._world.add_child(hoard)
	await snap("salle-or")
	print("Captured both native masonry references.")
	quit()

func snap(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(stage.get_texture().get_image().save_png(REVIEW + file + ".png") == OK)
